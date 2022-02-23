module targets.base;

public {
    import std.stdio;
    import util;
    import cute_tiled;
    import mapload;
}

class MapCompileTarget {
    abstract @property string name();
    abstract @property string description();

    public bool verbose = false;

    abstract void load_map(ubyte[] map_data);
    abstract ubyte[] compile_map();
}
