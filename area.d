module area;

import derelict.sdl.sdl;

import std.stdio, std.string;
import std.conv, std.xml;

import constants, map, tile, surface;


class Area {
  private Map[] _mapList;
  private int _areaSize;

  static Area AreaControl;

  static this() {
    AreaControl = new Area();
  }
  
  /**
   * Load a an area from a file.
   * Format:
   * <size>
   * file[1][1] file[1][2] ... file[1][size]
   * ...
   * file[size][1] file[size][2] ... file[size][size]
   */
  bool load(string fileName) {
    _mapList.length = 0;
    
    auto f = File(fileName, "r");
    scope (exit) { f.close(); }

    string tilesetFileName;

    // Read the width and height in maps.
    f.readf("%d\n", &_areaSize);

    // Load the maps and add them to the list.
    foreach (x; 0 .. _areaSize) {
      auto fileNames = split(f.readln());
      assert(fileNames.length == _areaSize);
      foreach (mapFileName; fileNames) {

        Map tempMap = new Map();
        if (tempMap.loadFromTmxFile(mapFileName) == false)
          return false;

        _mapList ~= tempMap;
      }
    }

    return true;
  }

  void render(SDL_Surface* surfDisplay, int cameraX, int cameraY) {
    int mapWidth = MAP_WIDTH * TILE_SIZE;
    int mapHeight = MAP_HEIGHT * TILE_SIZE;

    int firstId = cameraX / mapWidth + ((cameraY / mapHeight) * _areaSize);

    foreach (i; 0 .. 4) {
      int id = firstId + ((i / 2) * _areaSize) + (i % 2);

      if (id < 0 || id >= _mapList.length) continue;

      int x = ((id % _areaSize) * mapWidth) - cameraX;
      int y = ((id / _areaSize) * mapHeight) - cameraY;

      _mapList[id].onRender(surfDisplay, x, y);
    }
  }

  void cleanup() {
    _mapList.length = 0;
  }

  /**
   * Calculate the specific map, in the area, the given coordinates are in.
   */
  Map getMap(int x, int y) {
    int mapWidth = MAP_WIDTH * TILE_SIZE;
    int mapHeight = MAP_HEIGHT * TILE_SIZE;
    int id = x / mapWidth + y / mapHeight * _areaSize;

    if (id < 0 || id >= _mapList.length) {
      return null;
    }

    return _mapList[id];
  }

  /**
   * Gets the tile located at coordinates relative to the area.
   */
  Tile getTile(int x, int y) {
    int mapWidth = MAP_WIDTH * TILE_SIZE;
    int mapHeight = MAP_HEIGHT * TILE_SIZE;

    Map map = getMap(x, y);

    if (map is null)
      return null;

    x = x % mapWidth;
    y = y % mapWidth;

    return map.getTile(x, y);
  }

  int getWidth() {
    return MAP_WIDTH * TILE_SIZE * _areaSize;
  }

  int getHeight() {
    return MAP_HEIGHT * TILE_SIZE * _areaSize;
  }

  /**
   * Logic to drop into a parser to read an area object.
   * An element parser must take a single argument, thus one
   * should curry the first argument before adding to the parser.
   */
  static void delegate(ElementParser) getXmlParser(Area area) {
	// Re-initialize our area object.
	area._mapList.length = 0;
	area._areaSize = 0;

	return (ElementParser parser) {
	  // Save the size, which is an attribute.
	  area._areaSize = to!int(parser.tag.attr["size"]);
	  parser.onEndTag["map"] = (in Element e) {
		// Each map element contains a file name to load.
		Map tempMap = new Map();
		if (tempMap.loadFromTmxFile(e.text()) == false)
		  throw new Exception("Unable to parse map-file " ~ e.text());

		area._mapList ~= tempMap;
	  };
	  // Parse over the entire element, reading all maps.
	  parser.parse();
	};
  }
}
