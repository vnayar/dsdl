module area;

import derelict.sdl2.sdl;

import std.stdio : File;
import std.string;
import std.conv, std.xml;

import constants, map, tile;
import graphics.display, graphics.imageloader;

debug import std.stdio : writeln, writefln;
debug import std.format : format;


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
  bool load(in string fileName, ImageLoader imageLoader) {
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
        if (tempMap.loadFromTmxFile(mapFileName, imageLoader) == false)
          return false;

        _mapList ~= tempMap;
      }
    }

    return true;
  }

  void render(Display display, int cameraX, int cameraY) {
    int centerMapId = cameraX / getMapWidth() + ((cameraY / getMapHeight()) * _areaSize);

    foreach (i; 0 .. 4) {
      int id = centerMapId + ((i / 2) * _areaSize) + (i % 2);

      if (id < 0 || id >= _mapList.length) continue;

      int x = ((id % _areaSize) * getMapWidth()) - cameraX;
      int y = ((id / _areaSize) * getMapHeight()) - cameraY;

      _mapList[id].render(display, x, y);
    }
  }

  void cleanup() {
    _mapList.length = 0;
  }

  /**
   * Calculate the specific map, in the area, the given coordinates are in.
   */
  Map getMap(int x, int y) {
    int id = x / getMapWidth() + y / getMapHeight() * _areaSize;

    if (id < 0 || id >= _mapList.length) {
      return null;
    }

    return _mapList[id];
  }

  /**
   * Gets the tile located at coordinates relative to the area.
   */
  Tile getTile(int x, int y) {
    Map map = getMap(x, y);

    if (map is null)
      return null;

    x = x % getMapWidth();
    y = y % getMapWidth();

    return map.getTile(x, y);
  }

  int getWidth() {
    return getMapWidth() * _areaSize;
  }

  int getHeight() {
    return getMapHeight() * _areaSize;
  }

  private int getMapWidth() {
    return _mapList[0].mapWidth * _mapList[0].tileWidth;
  }

  private int getMapHeight() {
    return _mapList[0].mapHeight * _mapList[0].tileHeight;
  }

  /**
   * Logic to drop into a parser to read an area object.
   * An element parser must take a single argument, thus one
   * should curry the first argument before adding to the parser.
   */
  static void delegate(ElementParser) getXmlParser(ImageLoader imageLoader, out Area area) {
	return (ElementParser parser) {
	  // Save the size, which is an attribute.
      area = new Area();
	  area._areaSize = to!int(parser.tag.attr["size"]);
	  parser.onEndTag["map"] = (in Element e) {
		// Each map element contains a file name to load.
		Map tempMap = new Map();
		if (tempMap.loadFromTmxFile(e.text(), imageLoader) == false)
		  throw new Exception("Unable to parse map-file " ~ e.text());
		area._mapList ~= tempMap;
	  };
	  // Parse over the entire element, reading all maps.
	  parser.parse();
	};
  }
}
