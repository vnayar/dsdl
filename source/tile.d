module tile;

import graphics;


class Tile {
  enum Type : int {NONE=0, NORMAL, BLOCK};
  int id;
  Type type;
}

class TileSet {
  Image image;
  Tile[] tiles;
}
