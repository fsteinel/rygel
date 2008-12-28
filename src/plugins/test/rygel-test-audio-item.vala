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
using Gee;
using Gst;

/**
 * Represents Test audio item.
 */
public class Rygel.TestAudioItem : Rygel.TestItem {
    const string TEST_PATH = "/test.wav";
    const string TEST_MIMETYPE = "audio/x-wav";

    public TestAudioItem (string   id,
                          string   parent_id,
                          string   title,
                          Streamer streamer) {
        base (id,
              parent_id,
              title,
              TEST_MIMETYPE,
              MediaItem.AUDIO_CLASS,
              streamer,
              TEST_PATH);
    }

    protected override Element create_gst_source () throws Error {
        Bin bin = new Bin (this.title);

        dynamic Element src = ElementFactory.make ("audiotestsrc", null);
        Element encoder = ElementFactory.make ("wavenc", null);

        if (src == null || encoder == null) {
            throw new GstStreamError.MISSING_PLUGIN ("Required plugin missing");
        }

        // Tell the source to behave like a live source
        src.is_live = true;

        // Add elements to our source bin
        bin.add_many (src, encoder);
        // Link them
        src.link (encoder);

        // Now add the encoder's src pad to the bin
        Pad pad = encoder.get_static_pad ("src");
        var ghost = new GhostPad (bin.name + "." + pad.name, pad);
        bin.add_pad (ghost);

        return bin;
    }
}

