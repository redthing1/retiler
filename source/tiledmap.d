module tiledmap;

import util;
import cute_tiled;
import std.stdio;
import std.format;
import std.conv;

struct TiledMap {
    struct Property {
        string name;
        string value;
    }

    alias Properties = Property[];

    struct Object {
        int id;
        string name;
        string type;
        Properties properties;
        float x;
        float y;
        float width;
        float height;
    }

    struct Layer {
        enum Type {
            Unknown,
            Tile,
            Object,
            Image,
            Group
        }

        /** layer type */
        Type type;
        /** layer id */
        int id;
        /** layer name */
        string name;
        /** tile data */
        int[] data;
        /** object data */
        Object[] objects;
        /** layer properties */
        Properties properties;
    }

    struct Tileset {
        int firstgid;
        string name;
        string image_path;
        int image_width;
        int image_height;
        int tile_count;
        int tile_width;
        int tile_height;

    }

    cute_tiled_map_t cute_map;
    cute_tiled_layer_t[] cute_layers;
    cute_tiled_tileset_t[] cute_tilesets;

    int num_layers;
    int width;
    int height;
    int num_tiles;
    Properties properties;

    Layer[] layers;
    Tileset[] tilesets;

    private static Property convert_cute_property(cute_tiled_property_t* prop) {
        auto prop_name = prop.name.ptr.to!string;
        string prop_value;

        switch (prop.type) {
        case CUTE_TILED_PROPERTY_TYPE.CUTE_TILED_PROPERTY_INT:
            prop_value = prop.data.integer.to!string;
            break;
        case CUTE_TILED_PROPERTY_TYPE.CUTE_TILED_PROPERTY_STRING:
            prop_value = prop.data._string.ptr.to!string;
            break;
        case CUTE_TILED_PROPERTY_TYPE.CUTE_TILED_PROPERTY_BOOL:
            prop_value = prop.data.boolean.to!string;
            break;
        case CUTE_TILED_PROPERTY_TYPE.CUTE_TILED_PROPERTY_FLOAT:
            prop_value = prop.data.floating.to!string;
            break;
        default:
            assert(0, format("unsupported property type %s", prop.type));
        }

        return Property(prop_name, prop_value);
    }

    static TiledMap load(ubyte[] map_data) {
        TiledMap tmap;

        // load map
        cute_tiled_map_t* map = cute_tiled_load_map_from_memory(cast(ubyte*) map_data, cast(int) map_data.length, null);

        // writefln("  map size: %sx%s (%s)", map.width, map.height, map.width * map.height);
        tmap.width = map.width;
        tmap.height = map.height;

        tmap.num_tiles = map.width * map.height;

        // copy map properties
        for (int i = 0; i < map.property_count; i++) {
            tmap.properties ~= convert_cute_property(&map.properties[i]);
        }

        // handle map layers
        auto num_layers = 0;
        cute_tiled_layer_t* layer = map.layers;
        while (layer) {
            // found a layer
            num_layers++;

            Layer tlayer;
            tlayer.id = layer.id;
            tlayer.name = layer.name.ptr.to!string;

            // copy layer properties
            for (int i = 0; i < layer.property_count; i++) {
                tlayer.properties ~= convert_cute_property(&layer.properties[i]);
            }

            if (layer.data) {
                tlayer.type = Layer.Type.Tile;

                // look at layer data
                int data_count = layer.data_count;

                assert(tmap.num_tiles == data_count,
                    format("layer data count (%s) does not match map tile count (%s)",
                        data_count, tmap.num_tiles));

                // add to layer list
                tmap.cute_layers ~= *layer;

                // copy layer data
                // preallocate
                tlayer.data.length = data_count;
                for (int i = 0; i < data_count; i++) {
                    auto tid = layer.data[i];
                    tlayer.data[i] = tid;
                }
                tlayer.type = Layer.Type.Tile;
            } else if (layer.objects) {
                tlayer.type = Layer.Type.Object;

                // look at objects
                cute_tiled_object_t* obj = layer.objects;
                while (obj) {
                    // object basic
                    auto obj_name = obj.name.ptr.to!string;
                    auto obj_type = obj.type.ptr.to!string;

                    Object tobj;
                    tobj.id = obj.id;
                    tobj.name = obj_name;
                    tobj.type = obj_type;
                    tobj.x = obj.x;
                    tobj.y = obj.y;
                    tobj.width = obj.width;
                    tobj.height = obj.height;

                    // object properties
                    for (int i = 0; i < obj.property_count; i++) {
                        tobj.properties ~= convert_cute_property(&obj.properties[i]);
                    }

                    // add to object list
                    tlayer.objects ~= tobj;

                    // next
                    obj = obj.next;
                }
            } else {
                tlayer.type = Layer.Type.Unknown;
            }
            tmap.layers ~= tlayer;

            // next
            layer = layer.next;
        }

        // writefln("  map layers: %s", num_layers);
        tmap.num_layers = num_layers;

        // handle map tilesets
        auto num_tilesets = 0;
        cute_tiled_tileset_t* tileset = map.tilesets;
        while (tileset) {
            // found a tileset
            num_tilesets++;

            Tileset tset;
            tset.firstgid = tileset.firstgid;
            tset.name = tileset.name.ptr.to!string;
            tset.image_path = tileset.image.ptr.to!string;
            tset.image_width = tileset.imagewidth;
            tset.image_height = tileset.imageheight;
            tset.tile_count = tileset.tilecount;
            tset.tile_width = tileset.tilewidth;
            tset.tile_height = tileset.tileheight;

            // add to tileset list
            tmap.cute_tilesets ~= *tileset;
            tmap.tilesets ~= tset;

            // next
            tileset = tileset.next;
        }

        tmap.cute_map = *map;

        return tmap;
    }

    int get_tile(int layer, int x, int y) {
        assert(layer >= 0 && layer < num_layers, "invalid layer");
        assert(x >= 0 && x < width, "invalid x");
        assert(y >= 0 && y < height, "invalid y");

        int index = y * width + x;
        auto data = layers[layer].data;
        return data[index];
    }

    struct TileFlip {
        bool hflip;
        bool vflip;
        bool dflip;
    }

    TileFlip get_tile_flip(int tid) {
        TileFlip ret;
        ret.hflip = !!(tid & CUTE_TILED_FLIPPED_HORIZONTALLY_FLAG);
        ret.vflip = !!(tid & CUTE_TILED_FLIPPED_VERTICALLY_FLAG);
        ret.dflip = !!(tid & CUTE_TILED_FLIPPED_DIAGONALLY_FLAG);
        return ret;
    }
}
