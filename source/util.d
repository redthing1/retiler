module util;

public {
    import core.stdc.stdio;
    import core.stdc.string;
}

import std.utf;

public static char* c_str(string str) {
    return str.toUTFz!(char*)();
}
