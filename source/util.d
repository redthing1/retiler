module util;

public {
    import core.stdc.stdio;
    import core.stdc.string;
}

import std.utf;

public static char* c_str(string str) {
    return str.toUTFz!(char*)();
}

/**
    * LIHQ-style features with std.algorithm
 */
R1 first(alias pred = "a == b", R1, R2)(R1 haystack, scope R2 needle) {
    import std.algorithm;

    return haystack.find!(pred, needle).front;
}
