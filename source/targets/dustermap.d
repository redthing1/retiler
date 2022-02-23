module targets.dustermap;

import std.stdio;
import std.conv;
import std.bitmanip : to_le = nativeToLittleEndian;
import std.algorithm;
import std.range;
import std.conv;
import std.format;

import targets.base;

class DusterMapTarget : MapCompileTarget {
    override @property string name() {
        return "Duster Map";
    }

    override @property string description() {
        return "Binary map files for DusterGBA";
    }

    public DusterMap cached_map;

    enum NUM_TEAMS = 4;

    struct PawnSpawn {
        int team;
        int pawn;
        int pclass;
        int level;
        int tx;
        int ty;

        string toString() const {
            import std.string : format;

            return format("(team: %s, pawn: %s, class: %s, level: %s, pos: (%s, %s)",
                team, pawn, pclass, level, tx, ty);
        }
    }

    struct DusterMap {
        int board_size;
        int num_tiles;
        int[] tiles;

        PawnSpawn[] spawns;
    }

    override void load_map(ubyte[] map_data) {
        auto map = TiledMap.load(map_data);

        if (verbose)
            writefln("map: %s", map);

        // make sure width and height match
        assert(map.width == map.height, "map width and height must match!");
        cached_map.num_tiles = map.num_tiles;
        cached_map.board_size = map.width;

        bool terrain_layer_found = map.layers.canFind!(x => x.name == "terrain");
        bool pawns_layer_found = map.layers.canFind!(x => x.name == "pawns");

        assert(terrain_layer_found, "terrain layer not found!");
        assert(pawns_layer_found, "pawns layer not found!");

        auto terrain_layer = map.layers.find!(x => x.name == "terrain").front;
        // resize tiles data countainer
        cached_map.tiles.length = cached_map.num_tiles;
        assert(terrain_layer.data.length == map.num_tiles,
            format("terrain layer tile count (%s) does not match map tile count (%s)",
                terrain_layer.data.length, map.num_tiles));

        // copy tile data from terrain layer
        writefln("%s", terrain_layer.data);
        for (int i = 0; i < map.num_tiles; i++) {
            int tid = terrain_layer.data[i];
            int tx = i % map.width;
            int ty = i / map.width;

            cached_map.tiles[i] = tid;
            // writefln("tile %s: %s", i, tid);

            // if (tid == 2) {
            //     // obstacle
            //     writefln("    obstacle tile (%d,%d): %d", tx, ty, tid);
            // }
        }
        if (verbose)
            writefln("  copied %s board tiles", map.num_tiles);

        // spawn points
        auto pawns_layer = map.layers.find!(x => x.name == "pawns").front;
        int[NUM_TEAMS] team_pawn_count;

        foreach (obj; pawns_layer.objects) {
            if (verbose)
                writefln("  checking obj: %s (%d)", obj.name, obj.id);

            // check if spawn
            if (obj.type == "pawn" && obj.properties.length > 0) {
                // add to spawn
                int team_ix = -1;
                int pawn_class = 0;
                int pawn_level = 1;

                foreach (prop; obj.properties) {
                    if (prop.name == "team") {
                        team_ix = prop.value.to!int;
                    }
                    if (prop.name == "class") {
                        pawn_class = prop.value.to!int;
                    }
                    if (prop.name == "level") {
                        pawn_level = prop.value.to!int;
                    }
                }

                if (team_ix >= 0) {
                    // valid, add

                    // get next open pawn slot using team counts
                    int pawn_ix = team_pawn_count[team_ix];
                    // increment pawn slot number
                    team_pawn_count[team_ix]++;

                    auto spawn = PawnSpawn(team_ix, pawn_ix, pawn_class,
                        pawn_level, cast(int) obj.x, cast(int) obj.y);
                    cached_map.spawns ~= spawn;
                    if (verbose)
                        writefln("    pawn: %s", spawn);
                }
            }
        }
    }

    override ubyte[] compile_map() {
        ubyte[] bin;

        // magic header
        uint magic_header = 0xD0570000;
        bin ~= magic_header.to_le;

        // board size
        bin ~= cached_map.board_size.to_le;

        // tile data
        bin ~= cached_map.num_tiles.to_le;
        for (int i = 0; i < cached_map.num_tiles; i++) {
            bin ~= cached_map.tiles[i].to_le;
        }

        // pawn spawn data
        bin ~= (cast(int) cached_map.spawns.length).to_le;
        for (int i = 0; i < cached_map.spawns.length; i++) {
            PawnSpawn spawn = cached_map.spawns[i];

            bin ~= spawn.team.to_le;
            bin ~= spawn.pawn.to_le;
            bin ~= spawn.pclass.to_le;
            bin ~= spawn.level.to_le;
            bin ~= spawn.tx.to_le;
            bin ~= spawn.ty.to_le;
        }

        return bin;
    }
}
