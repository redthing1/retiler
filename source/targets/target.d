module targets.target;

class MapCompileTarget {
    abstract @property string name();
    abstract @property string description();

    public bool verbose = false;

    abstract void load_map(ubyte[] map_data);
    abstract ubyte[] compile_map();
}
