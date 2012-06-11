module level;

import std.xml;
import std.file;

import area, entityconfig;

/**
 * Container for all objects that make up a level.
 * This includes music, backgrounds, entities, areas, etc.
 * A level may be unloaded and another one installed with no memory
 * left behind.
 */
class Level {
  EntityConfig[string] entityConfigs;

  bool loadFromXmlFile(string fileName) {
	string xmlData = cast(string) std.file.read(fileName);
	return loadFromXml(xmlData);
  }

  bool loadFromXml(string xmlData) {
	auto xml = new DocumentParser(xmlData);

	xml.onStartTag["area"] = Area.getXmlParser(Area.AreaControl);
    xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);
	xml.parse();

	return true;
  }

}