module encode.gba;

struct ToncTypes {
    alias FIXED = int; //!< Fixed point type
    alias COLOR = ushort; //!< Type for colors
    alias SCR_ENTRY = ushort;
    alias SE = ushort; //!< Type for screen entries
    alias SCR_AFF_ENTRY = ubyte;
    alias SAE = ubyte; //!< Type for affine screen entries

    //! 4bpp tile type, for easy indexing and copying of 4-bit tiles
    struct TILE {
        uint[8] data;
    }

    alias TILE4 = TILE;
    //! 8bpp tile type, for easy indexing and 8-bit tiles
    struct TILE8 {
        uint[16] data;
    }
}

struct GbaTiledBackgroundData {
    /** gba bg charblocks - tileset image data */
    /** gba bg palette - tileset palette */
    /** gba screen blocks/entries - the map data with tile index and flip flags */
}

class GbaTiledBackgroundEncoder {

}
