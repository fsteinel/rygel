/*
 * Copyright (C) 2008 Zeeshan Ali <zeenix@gmail.com>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
 *
 * Author: Zeeshan Ali <zeenix@gmail.com>
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

using Rygel;
using GUPnP;
using DBus;

public class Rygel.TrackerContainer : MediaContainer {
    /* class-wide constants */
    private const string TRACKER_SERVICE = "org.freedesktop.Tracker";
    private const string TRACKER_PATH = "/org/freedesktop/Tracker";
    private const string TRACKER_IFACE = "org.freedesktop.Tracker";
    private const string FILES_PATH = "/org/freedesktop/Tracker/Files";
    private const string FILES_IFACE = "org.freedesktop.Tracker.Files";
    private const string METADATA_PATH = "/org/freedesktop/Tracker/Metadata";
    private const string METADATA_IFACE = "org.freedesktop.Tracker.Metadata";

    public static dynamic DBus.Object metadata;
    public static dynamic DBus.Object files;
    public static dynamic DBus.Object tracker;

    public Context context;
    public string category;

    /* UPnP class of items under this container */
    public string child_class;

    // FIXME: We should not need this
    private string root_id;

    // Class constructor
    static construct {
        DBus.Connection connection;
        try {
            connection = DBus.Bus.get (DBus.BusType.SESSION);
        } catch (DBus.Error error) {
            critical ("Failed to connect to Session bus: %s\n",
                      error.message);
        }

        TrackerContainer.metadata =
                    connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                           TrackerContainer.METADATA_PATH,
                                           TrackerContainer.METADATA_IFACE);
        TrackerContainer.files =
                    connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                           TrackerContainer.FILES_PATH,
                                           TrackerContainer.FILES_IFACE);
        TrackerContainer.tracker =
                    connection.get_object (TrackerContainer.TRACKER_SERVICE,
                                           TrackerContainer.TRACKER_PATH,
                                           TrackerContainer.TRACKER_IFACE);
    }

    public TrackerContainer (string  id,
                             string  parent_id,
                             string  root_id,
                             string  title,
                             string  category,
                             string  child_class,
                             Context context) {
        this.id = id;
        this.parent_id = parent_id;
        this.root_id = root_id;
        this.title = title;
        this.category = category;
        this.child_class = child_class;
        this.context = context;
    }

    public override void serialize (DIDLLiteWriter didl_writer) {
        /* Update the child count */
        this.child_count = this.get_children_count ();

        base.serialize (didl_writer);
    }

    private uint get_children_count () {
        string[][] stats;

        try {
                stats = TrackerContainer.tracker.GetStats ();
        } catch (GLib.Error error) {
            critical ("error getting tracker statistics: %s", error.message);

            return 0;
        }

        uint count = 0;
        for (uint i = 0; i < stats.length; i++) {
            if (stats[i][0] == this.category)
                count = stats[i][1].to_int ();
        }

        return count;
    }

    public uint add_children_from_db (DIDLLiteWriter didl_writer,
                                       uint           offset,
                                       uint           max_count,
                                       out uint       child_count) {
        string[] children;

        children = this.get_children_from_db (offset,
                                              max_count,
                                              out child_count);
        if (children == null)
            return 0;

        /* Iterate through all items */
        for (uint i = 0; i < children.length; i++)
            this.add_item_from_db (didl_writer, children[i]);

        return children.length;
    }

    private string[]? get_children_from_db (uint     offset,
                                            uint     max_count,
                                            out uint child_count) {
        string[] children = null;

        child_count = this.get_children_count ();

        try {
            children =
                TrackerContainer.files.GetByServiceType (0,
                                                         this.category,
                                                         (int) offset,
                                                         (int) max_count);
        } catch (GLib.Error error) {
            critical ("error: %s", error.message);

            return null;
        }

        return children;
    }

    public bool add_item_from_db (DIDLLiteWriter didl_writer,
                                   string         path) {
        MediaItem item;

        if (this.child_class == MediaItem.VIDEO_CLASS) {
            item = new TrackerVideoItem (this.root_id + ":" + path,
                                         path,
                                         this);
        } else if (this.child_class == MediaItem.IMAGE_CLASS) {
            item = new TrackerImageItem (this.root_id + ":" + path,
                                         path,
                                         this);
        } else {
            item = new TrackerMusicItem (this.root_id + ":" + path,
                                         path,
                                         this);
        }

        item.serialize (didl_writer);

        return true;
    }

    private string uri_from_path (string path) {
        string escaped_path = Uri.escape_string (path, "/", true);

        return "http://%s:%u%s".printf (this.context.host_ip,
                                        this.context.port,
                                        escaped_path);
    }

    public static string get_file_category (string uri) throws GLib.Error {
        string category;

        category = TrackerContainer.files.GetServiceType (uri);

        return category;
    }
}

