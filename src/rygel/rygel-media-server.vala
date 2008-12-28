/*
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 *
 * Author: Zeeshan Ali (Khattak) <zeeshanak@gnome.org>
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

/**
 * Represents a MediaServer device.
 */
public class Rygel.MediaServer: RootDevice {
    private List<ServiceInfo> services;   /* Services we implement */

    public MediaServer (GUPnP.Context context,
                        Plugin        plugin,
                        Xml.Doc      *description_doc,
                        string        relative_location) {
        this.resource_factory = plugin;
        this.root_device = null;
        this.context = context;

        this.description_doc = description_doc;
        this.weak_ref ((WeakNotify) xml_doc_free, description_doc);
        this.relative_location = relative_location;

        this.services = new List<ServiceInfo> ();

        // Now create the sevice objects
        foreach (ResourceInfo info in plugin.resource_infos) {
            // FIXME: We only support plugable services for now
            if (info.type.is_a (typeof (Service))) {
                var service = this.get_service (info.upnp_type);

                this.services.append (service);
            }
        }
    }

    private static void xml_doc_free (Xml.Doc* doc, MediaServer server) {
        delete doc;
    }
}

