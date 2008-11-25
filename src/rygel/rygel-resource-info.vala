/*
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

using Gee;
using GUPnP;

/**
 * Holds information about a particular resource (device and service)
 * implementation.
 */
public class Rygel.ResourceInfo {
    public string upnp_type;
    public string upnp_id;
    public string description_path;

    // The GLib.Type of the class implementing this service
    public Type type;

    public ResourceInfo (string upnp_id,
                         string upnp_type,
                         string description_path,
                         Type   type) {
        this.upnp_type = upnp_type;
        this.upnp_id = upnp_id;
        this.description_path = description_path;
        this.type = type;
    }
}

