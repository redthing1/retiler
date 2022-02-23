module targets.dummy;

import targets.base;

class DummyMapTarget : MapCompileTarget {
    override @property string name() {
        return "Dummy";
    }

    override @property string description() {
        return "Dummy target for showing map info";
    }

    override void load_map(ubyte[] map_data) {
        // load map
        cute_tiled_map_t* map = cute_tiled_load_map_from_memory(cast(ubyte*) map_data, cast(int) map_data.length, null);
        writefln("  loaded map: %sx%s", map.width, map.height);

        assert(map.width == map.height, "map width and height must match!");

        writefln("  map size: %sx%s (%s)", map.width, map.height, map.width * map.height);

        auto num_layers = 0;
        cute_tiled_layer_t* layer = map.layers;
        while (layer) {
            layer = layer.next;
            num_layers++;
        }

        writefln("  map layers: %s", num_layers);
    }

    override ubyte[] compile_map() {
        ubyte[] bin;

        return bin;
    }
}
