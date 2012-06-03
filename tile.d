module tile;

import derelict.sdl.sdl;


class Tile {
  enum Type : int {NONE=0, NORMAL, BLOCK};
  int id;
  Type type;
}

class TileSet {
  SDL_Surface* surface;
  Tile[] tiles;
}
