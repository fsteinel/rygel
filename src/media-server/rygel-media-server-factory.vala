/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
 *                               <zeeshan.ali@nokia.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 */

using GUPnP;
using GConf;
using CStuff;

public class Rygel.MediaServerFactory {
    public static const string DESC_DOC = "xml/description.xml";
    public static const string XBOX_DESC_DOC = "xml/description-xbox360.xml";
    public static const string DESC_PREFIX = "Rygel";
    public static const string ROOT_GCONF_PATH = "/apps/gupnp-media-server/";

    private GConf.Client gconf;
    private GUPnP.Context context;

    public MediaServerFactory () {
        this.gconf = GConf.Client.get_default ();

        /* Set up GUPnP context */
        this.context = create_upnp_context ();
    }

    public MediaServer? create_media_server (Plugin plugin) {
        string gconf_path = ROOT_GCONF_PATH + plugin.name + "/";
        string modified_desc = DESC_PREFIX + "-" + plugin.name + ".xml";

        bool enable_xbox;
        try {
            enable_xbox = this.gconf.get_bool (gconf_path + "enable-xbox");
        } catch (GLib.Error error) {
            warning ("%s", error.message);
        }

        /* We store a modified description.xml in the user's config dir */
        string desc_path = Path.build_filename
                                    (Environment.get_user_config_dir (),
                                     modified_desc);

        string orig_desc_path;

        if (enable_xbox)
            /* Use Xbox 360 specific description */
            orig_desc_path = Path.build_filename (BuildConfig.DATA_DIR,
                                                  XBOX_DESC_DOC);
        else
            orig_desc_path = Path.build_filename (BuildConfig.DATA_DIR,
                                                  DESC_DOC);

        Xml.Doc *doc = Xml.Parser.parse_file (orig_desc_path);
        if (doc == null)
            return null;

        /* Modify description to include Plugin-specific stuff */
        this.prepare_desc_for_plugin (doc, plugin, gconf_path);

        if (enable_xbox)
            /* Put/Set XboX specific stuff to description */
            add_xbox_specifics (doc);

        /* Save the modified description.xml into the user's config dir.
         * We do this so that we can host the modified file, and also to
         * make sure the generated UDN stays the same between sessions. */
        FileStream f = FileStream.open (desc_path, "w+");
        int res = -1;

        if (f != null)
            res = Xml.Doc.dump (f, doc);

        if (f == null || res == -1) {
            critical ("Failed to write modified description.xml to %s.\n",
                      desc_path);

            delete doc;

            return null;
        }

        /* Host our modified file */
        this.context.host_path (desc_path, "/" + modified_desc);

        var server = new MediaServer (this.context,
                                      plugin,
                                      doc,
                                      modified_desc);

        return server;
    }

    private GUPnP.Context? create_upnp_context () {
        string host_ip;
        try {
            host_ip = this.gconf.get_string (ROOT_GCONF_PATH + "host-ip");
        } catch (GLib.Error error) {
            warning ("%s", error.message);

            host_ip = null;
        }

        int port;
        try {
            port = this.gconf.get_int (ROOT_GCONF_PATH + "port");
        } catch (GLib.Error error) {
            warning ("%s", error.message);

            port = 0;
        }

        GUPnP.Context context;
        try {
            context = new GUPnP.Context (null, host_ip, port);
        } catch (GLib.Error error) {
            warning ("Error setting up GUPnP context: %s", error.message);

            return null;
        }

        /* Host UPnP dir */
        context.host_path (BuildConfig.DATA_DIR, "");

        return context;
    }

    private string get_str_from_gconf (string key,
                                       string default_value) {
        string str;

        try {
            str = this.gconf.get_string (key);
        } catch (GLib.Error error) {
            try {
                this.gconf.set_string (key, str);
            } catch (GLib.Error error) {
                warning ("Error setting gconf key '%s': %s.",
                        key,
                        error.message);

                str = null;
            }
        }

        if (str != null)
                return str;
        else
                return default_value;
    }

    private void add_xbox_specifics (Xml.Doc doc) {
        Xml.Node *element;

        element = Utils.get_xml_element ((Xml.Node *) doc,
                                         "root",
                                         "device",
                                         "friendlyName");
        /* friendlyName */
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        element->add_content (": 1 : Windows Media Connect");
    }

    private void prepare_desc_for_plugin (Xml.Doc doc,
                                          Plugin  plugin,
                                          string  gconf_path) {
        Xml.Node *device_element;

        device_element = Utils.get_xml_element ((Xml.Node *) doc,
                                                "root",
                                                "device",
                                                null);
        if (device_element == null) {
            warning ("Element /root/device not found.");

            return;
        }

        /* First, set the Friendly name and UDN */
        this.set_friendly_name_and_udn (device_element,
                                        plugin.name,
                                        gconf_path);

        /* Then list each service */
        this.add_services_to_desc (device_element, plugin);
    }

    /* Fills the description doc @doc with a friendly name, and UDN from gconf.
     * If these keys are not present in gconf, they are set with default values.
     */
    private void set_friendly_name_and_udn (Xml.Node *device_element,
                                            string    plugin_name,
                                            string    gconf_path) {
        /* friendlyName */
        Xml.Node *element = Utils.get_xml_element (device_element,
                                         "friendlyName",
                                         null);
        if (element == null) {
            warning ("Element /root/device/friendlyName not found.");

            return;
        }

        string str = get_str_from_gconf (gconf_path + "friendly-name",
                                         plugin_name);
        element->set_content (str);

        /* UDN */
        element = Utils.get_xml_element (device_element, "UDN");
        if (element == null) {
            warning ("Element /root/device/UDN not found.");

            return;
        }

        /* Generate new UUID */
        string default_value = Utils.generate_random_udn ();
        str = get_str_from_gconf (gconf_path + "UDN", default_value);
        element->set_content (str);
    }

    private void add_services_to_desc (Xml.Node *device_element,
                                       Plugin    plugin) {
        Xml.Node *service_list_node = Utils.get_xml_element (device_element,
                                                             "serviceList",
                                                             null);
        if (service_list_node == null) {
            warning ("Element /root/device/serviceList not found.");

            return;
        }

        foreach (ResourceInfo resource_info in plugin.resource_infos) {
            // FIXME: We only support plugable services for now
            if (resource_info.type.is_a (typeof (Service))) {
                    this.add_service_to_desc (service_list_node,
                                              plugin.name,
                                              resource_info);
            }
        }
    }

    private void add_service_to_desc (Xml.Node    *service_list_node,
                                      string       plugin_name,
                                      ResourceInfo resource_info) {
        // Create the service node
        Xml.Node *service_node = service_list_node->new_child (null, "service");

        service_node->new_child (null, "serviceType", resource_info.upnp_type);
        service_node->new_child (null, "serviceId", resource_info.upnp_id);

        /* Now the relative (to base URL) URLs*/
        string url = resource_info.description_path;
        service_node->new_child (null, "SCPDURL", url);

        url = plugin_name + "/" + resource_info.type.name () + "/Event";
        service_node->new_child (null, "eventSubURL", url);

        url = plugin_name + "/" + resource_info.type.name () + "/Control";
        service_node->new_child (null, "controlURL", url);
    }
}

