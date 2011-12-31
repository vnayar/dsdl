module area;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.util.compat;

import std.stdio, std.string;

import constants, map, tile, surface;

class Area {
  private Map[] _mapList;
  private SDL_Surface* _surfTileset;
  private int _areaSize;

  static Area AreaControl;

  static this() {
    AreaControl = new Area();
  }
  
  bool onLoad(string fileName) {
    _mapList.length = 0;
    
    auto f = File(fileName, "r");
    scope (exit) { f.close(); }

    string tilesetFileName;
    f.readf("%s\n", &tilesetFileName);
    writeln("tilesetFileName '" ~ tilesetFileName ~ "'");

    _surfTileset = Surface.onLoad(tilesetFileName);

    f.readf("%d\n", &_areaSize);

    foreach (x; 0 .. _areaSize) {
      auto fileNames = split(f.readln());
      assert(fileNames.length == _areaSize);
      foreach (mapFileName; fileNames) {
        writeln("mapFileName '" ~ mapFileName ~ "'");

        Map tempMap = new Map();
        if (tempMap.onLoad(mapFileName) == false)
          return false;

        tempMap.setTileset(_surfTileset);
        _mapList ~= tempMap;
      }
    }

    return true;
  }

  void onRender(SDL_Surface* surfDisplay, int cameraX, int cameraY) {
    int mapWidth = MAP_WIDTH * TILE_SIZE;
    int mapHeight = MAP_HEIGHT * TILE_SIZE;

    int firstId = -cameraX / mapWidth + ((-cameraY / mapHeight) * _areaSize);

    foreach (i; 0 .. 4) {
      int id = firstId + ((i / 2) * _areaSize) + (i % 2);

      if (id < 0 || id >= _mapList.length) continue;

      int x = ((id % _areaSize) * mapWidth) + cameraX;
      int y = ((id / _areaSize) * mapHeight) + cameraY;

      _mapList[id].onRender(surfDisplay, x, y);
    }
  }

  void onCleanup() {
    if (_surfTileset) {
      SDL_FreeSurface(_surfTileset);
    }

    _mapList.length = 0;
  }
}