module map;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.util.compat;
import std.stdio;

import constants, tile, surface;

class Map {
  private SDL_Surface* _surfTileset;
  private Tile[] _tileList;

  void setTileset(SDL_Surface* surfTileset) {
    _surfTileset = surfTileset;
  }

  bool onLoad(string fileName) {
    // Clear out any old tiles.
    _tileList.length = 0;

    auto f = File(fileName, "r");
    foreach (y; 0 .. MAP_HEIGHT) {
      foreach (x; 0 .. MAP_WIDTH) {
        Tile tempTile = new Tile();
        int id, type;
        //f.readf(" %d:%d ", &(tempTile.id), &(tempTile.type));
        f.readf(" %d:%d ", &id, &type);
        tempTile.id = id;
        tempTile.type = cast(Tile.Type) type;
        _tileList ~= tempTile;
      }
      //f.readf("\n");
    }
    return true;
  }

  void onRender(SDL_Surface* surfDisplay, int mapX, int mapY) {
    if (_surfTileset == null) return;

    int tilesetWidth = _surfTileset.w / TILE_SIZE;
    int tilesetHeight = _surfTileset.h / TILE_SIZE;

    int id = 0;
    
    foreach (y; 0 .. MAP_HEIGHT) {
      foreach (x; 0 .. MAP_WIDTH) {
        if (_tileList[id].type == Tile.Type.NONE) {
          id++;
          continue;
        }

        int tX = mapX + (x * TILE_SIZE);
        int tY = mapY + (y * TILE_SIZE);

        int tilesetX = (_tileList[id].id % tilesetWidth) * TILE_SIZE;
        int tilesetY = (_tileList[id].id / tilesetWidth) * TILE_SIZE;

        Surface.onDraw(
          _surfTileset, tilesetX, tilesetY, TILE_SIZE, TILE_SIZE,
          surfDisplay, tX, tY);

        id++;
      }
    }
  }
}
