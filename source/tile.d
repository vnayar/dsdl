module tile;

import derelict.sdl2.sdl;


class Tile {
  enum Type : int {NONE=0, NORMAL, BLOCK};
  int id;
  Type type;
}

class TileSet {
  SDL_Texture* texture;
  Tile[] tiles;
}
