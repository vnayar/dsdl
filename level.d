module level;

import std.xml;
import std.file;

import area, entityconfig, entity, background;

/**
 * Container for all objects that make up a level.
 * This includes music, backgrounds, entities, areas, etc.
 * A level may be unloaded and another one installed with no memory
 * left behind.
 */
class Level {
  Background background;
  EntityConfig[string] entityConfigs;
  Entity[] entities;

  this() {
  }

  bool loadFromXmlFile(string fileName) {
	string xmlData = cast(string) std.file.read(fileName);
	return loadFromXml(xmlData);
  }

  bool loadFromXml(string xmlData) {
	auto xml = new DocumentParser(xmlData);

    xml.onStartTag["background"] = Background.getXmlParser(background);
	xml.onStartTag["area"] = Area.getXmlParser(Area.AreaControl);
    xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);
    xml.onStartTag["entity"] = Entity.getXmlParser(entities);
	xml.parse();

    foreach (entity; entities) {
      EntityConfig entityConfig = entityConfigs[entity.getEntityConfig()];
      entity.onLoad(entityConfig);
      Entity.EntityList ~= entity;
    }

	return true;
  }

}