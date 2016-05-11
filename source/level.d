module level;

import std.xml;
import std.file;

import area, entityconfig, entity, background;
import graphics;

debug import std.stdio : writeln;


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

  bool loadFromXmlFile(string fileName, ImageLoader imageLoader) {
	string xmlData = cast(string) std.file.read(fileName);
	return loadFromXml(xmlData, imageLoader);
  }

  bool loadFromXml(in string xmlData, ImageLoader imageLoader) {
	auto xml = new DocumentParser(xmlData);

    xml.onStartTag["background"] = Background.getXmlParser(background);
	xml.onStartTag["area"] = Area.getXmlParser(imageLoader, Area.AreaControl);
    xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);
    xml.onStartTag["entity"] = Entity.getXmlParser(entities);
	xml.parse();

    background.load(imageLoader);

    foreach (entity; entities) {
      EntityConfig entityConfig = entityConfigs[entity.getEntityConfig()];
      entity.load(entityConfig, imageLoader);

      // TODO: Find a better way to set the default animation.
      entity.getSprite().setAnimation("right");

      Entity.EntityList ~= entity;
    }

	return true;
  }

}
