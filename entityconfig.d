import std.xml;
import std.conv;

import sprite;
import physics.types;

debug {
  import std.stdio;
}


/**
 * A collection of settings that can be applied to many entities.
 */
class EntityConfig {
  DVect maxVelocity;

  Rectangle collisionBoundary;

  // Sprite configuration
  Sprite sprite;

  // FIXME: Find a logical place for this.
  static void delegate(ElementParser) getDVectParser(ref DVect vect) {
    debug writeln("getDVectParser");
    return (ElementParser parser) {
      debug writeln("DVect parser");
      int index = 0;
      parser.onEndTag["value"] = (in Element e) {
        debug writeln("Writing to index ", index);
        vect[index++] = to!float(e.text());
      };
      parser.parse();
      debug writeln("vect = ", vect);
    };
  }

  static void delegate(ElementParser) getXmlParser(out EntityConfig[string] entityConfigs) {
    debug writeln("Entering EntityConfig.getXmlParser.");
    return (ElementParser parser) {
      debug writeln("EntityConfig parser");

      EntityConfig entityConfig = new EntityConfig();
      string id = parser.tag.attr["id"];

      debug writeln("Adding EntityConfig '" ~ id ~ "'.");

      parser.onStartTag["maxVelocity"] = getDVectParser(entityConfig.maxVelocity);

      parser.onStartTag["sprite"] = Sprite.getXmlParser(entityConfig.sprite);

      parser.onStartTag["collisionBoundary"] = (ElementParser parser) {
        parser.onStartTag["location"] = getDVectParser(entityConfig.collisionBoundary.location);
        parser.onStartTag["width"] = getDVectParser(entityConfig.collisionBoundary.width);
        parser.parse();
      };
      parser.parse();

      entityConfigs[id] = entityConfig;
    };
  }
}


unittest {
  string entityConfigXml = q"EOF
<?xml version="1.0" encoding="UTF-8"?>
<entityConfigs>
  <entityConfig id="yoshi">
    <!-- Movement settings -->
    <maxVelocity>
      <value>10.0</value>
      <value>15.0</value>
    </maxVelocity>
    <!-- Sprite information -->
    <sprite>
      <image>./gfx/yoshi3.png</image>
      <frameWidth>32</frameWidth>
      <frameHeight>32</frameHeight>
    </sprite>
    <!-- The part of the image that may collide. -->
    <collisionBoundary>
      <location>
        <value>6</value>
        <value>0</value>
      </location>
      <width>
        <value>20</value>
        <value>32</value>
      </width>
    </collisionBoundary>
  </entityConfig>
</entityConfigs>
EOF";

  EntityConfig[string] entityConfigs;
  auto xml = new DocumentParser(entityConfigXml);
  xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);

  debug writeln("Parsing entityConfig");
  xml.parse();

  EntityConfig entityConfig = entityConfigs["yoshi"];

  assert(entityConfig.maxVelocity == [10.0f, 15.0f],
         "maxVelocity " ~ to!string(entityConfig.maxVelocity));

  assert(entityConfig.sprite.frameWidth == 32, "sprite.frameWidth = " ~
         to!string(entityConfig.sprite.frameWidth) ~ ", expected 32.");

  assert(entityConfig.collisionBoundary.location == [6, 0]);
  assert(entityConfig.collisionBoundary.width == [20, 32]);
}