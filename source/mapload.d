module mapload;

import util;
import cute_tiled;

struct TiledMap {
    cute_tiled_map_t cute_tiled_map;

    int num_layers;
    int width;
    int height;

    cute_tiled_layer_t[] layers;
}

TiledMap load_tiled_map(ubyte[] map_data) {
    TiledMap tmap;

    // load map
    cute_tiled_map_t* map = cute_tiled_load_map_from_memory(cast(ubyte*) map_data, cast(int) map_data.length, null);

    // writefln("  map size: %sx%s (%s)", map.width, map.height, map.width * map.height);
    tmap.width = map.width;
    tmap.height = map.height;

    auto num_layers = 0;
    cute_tiled_layer_t* layer = map.layers;
    while (layer) {
        tmap.layers ~= *layer;
        num_layers++;

        // next
        layer = layer.next;
    }

    // writefln("  map layers: %s", num_layers);
    tmap.num_layers = num_layers;

    tmap.cute_tiled_map = *map;

    return tmap;
}
