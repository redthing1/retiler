module targets.dustermap;

import std.stdio;
import std.conv;
import std.bitmanip : to_le = nativeToLittleEndian;

import core.stdc.stdio;
import core.stdc.string;
import cute_tiled;
import util;

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
        // load map
        cute_tiled_map_t* map = cute_tiled_load_map_from_memory(cast(ubyte*) map_data, cast(int) map_data.length, null);
        writefln("  loaded map: %sx%s", map.width, map.height);

        cached_map.num_tiles = map.width * map.height;
        assert(map.width == map.height, "map width and height must match!");
        cached_map.board_size = map.width;

        bool terrain_layer_found = false;
        bool pawns_layer_found = false;

        cute_tiled_layer_t* layer = map.layers;
        while (layer) {
            int* data = layer.data;
            int data_count = layer.data_count;

            // stuff and things

            // terrain
            if (strcmp(layer.name.ptr, "terrain") == 0) {
                terrain_layer_found = true;

                assert(data_count == cached_map.num_tiles,
                    "map num tiles (based on w and h) did not match layer data count");

                // resize tiles data countainer
                cached_map.tiles.length = cached_map.num_tiles;

                // copy tile data from terrain layer
                for (int i = 0; i < data_count; i++) {
                    int tile = data[i];
                    int tx = i % map.width;
                    int ty = i / map.width;

                    cached_map.tiles[i] = tile;
                    // if (tile == 2) {
                    //     // obstacle
                    //     printf("obstacle tile (%d,%d): %d \n", tx, ty, tile);
                    // }
                }
                writefln("  copied %s board tiles", cached_map.num_tiles);
            }

            // spawn points
            if ((strcmp(layer.name.ptr, "pawns") == 0) && layer.objects) {
                pawns_layer_found = true;

                // array of pawn count for each team
                int[NUM_TEAMS] team_pawn_count;

                cute_tiled_object_t* obj = layer.objects;
                while (obj) {
                    // printf("checking obj: %s (%d)\n", obj.name.ptr, obj.id);

                    // check if spawn
                    if ((strcmp(obj.type.ptr, "pawn") == 0) && obj.property_count > 0) {
                        // add to spawn
                        int team_ix = -1;
                        int pawn_class = 0;
                        int pawn_level = 1;

                        for (int i = 0; i < obj.property_count; i++) {
                            cute_tiled_property_t* prop = &obj.properties[i];
                            if (strcmp(prop.name.ptr, "team") == 0) {
                                team_ix = prop.data.integer;
                            }
                            if (strcmp(prop.name.ptr, "class") == 0) {
                                pawn_class = prop.data.integer;
                            }
                            if (strcmp(prop.name.ptr, "level") == 0) {
                                pawn_level = prop.data.integer;
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
                            writefln("  pawn: %s", spawn);
                        }
                    }

                    obj = obj.next;
                }
            }

            layer = layer.next;
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
