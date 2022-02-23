module targets.target;

class MapCompileTarget {
    @property abstract string name();
    @property abstract string description();

    abstract void load_map(ubyte[] map_data);
    abstract ubyte[] compile_map();
}
