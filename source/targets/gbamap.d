module targets.gbamap;

import std.stdio;
import std.conv;
import std.bitmanip : to_le = nativeToLittleEndian;
import std.algorithm;
import std.range;
import std.conv;
import std.format;

import targets.base;
import encode.gba;

class GbaMapTarget : MapCompileTarget {
    override @property string name() {
        return "GBA Dusk Map";
    }

    override @property string description() {
        return "Compiled maps for GBA loaded with the Dusk framework";
    }

    public GbaMap cached_map;

    struct GbaMap {
        /** gba bg charblocks - tileset image data */
        /** gba bg palette - tileset palette */
        /** gba screen blocks/entries - the map data with tile index and flip flags */
    }

    override void load_map(ubyte[] map_data) {
        auto map = TiledMap.load(map_data);

        if (verbose)
            writefln("map: %s", map);
    }

    override ubyte[] compile_map() {
        ubyte[] bin;

        // magic header
        uint magic_header = 0xD057AABB;
        bin ~= magic_header.to_le;

        // // tile data
        // bin ~= cached_map.num_tiles.to_le;
        // for (int i = 0; i < cached_map.num_tiles; i++) {
        //     bin ~= cached_map.tiles[i].to_le;
        // }

        return bin;
    }
}
