/*
 * Copyright (C) 2008 Zeeshan Ali (Khattak) <zeeshanak@gnome.org>.
 * Copyright (C) 2008 Nokia Corporation, all rights reserved.
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

using Rygel;
using GUPnP;
using DBus;

/**
 * Represents DVB item.
 */
public class Rygel.DVBChannel : MediaItem {
    public static dynamic DBus.Object channel_list;

    private uint cid; /* The DVB Daemon Channel ID */

    public DVBChannel (uint                cid,
                       string              parent_id,
                       dynamic DBus.Object channel_list,
                       Streamer            streamer) throws GLib.Error {
        string id = parent_id + ":" + cid.to_string (); /* UPnP ID */

        base (id,
              parent_id,
              "Unknown",        /* Title Unknown at this point */
              "Unknown",        /* UPnP Class Unknown at this point */
              streamer);

        this.cid = cid;
        this.channel_list = channel_list;

        this.fetch_metadata ();
    }

    public void fetch_metadata () throws GLib.Error {
        /* TODO: make this async */
        this.title = this.channel_list.GetChannelName (cid);

        bool is_radio = this.channel_list.IsRadioChannel (cid);
        if (is_radio) {
            this.upnp_class = "object.item.audioItem.audioBroadcast";
        } else {
            this.upnp_class = "object.item.videoItem.videoBroadcast";
        }

        this.res.mime_type = "video/mpeg";
        this.res.uri = this.channel_list.GetChannelURL (cid);
    }
}

