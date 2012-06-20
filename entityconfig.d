import std.xml;
import std.conv;

import physics.types;

debug {
  import std.stdio;
}


/**
 * A collection of settings that can be applied to many entities.
 */
struct EntityConfig {
  DVect maxVelocity;
  DVect moveAccel;
  DVect jumpVelocity;

  Rectangle collisionBoundary;

  // Sprite configuration
  string image;
  int width;
  int height;
  int maxFrames;

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
    debug writeln("Enter EntityConfig.getEntityConfigXmlParser");
    return (ElementParser parser) {
      debug writeln("EntityConfig parser");

      EntityConfig entityConfig;
      string id = parser.tag.attr["id"];

      parser.onStartTag["maxVelocity"] = getDVectParser(entityConfig.maxVelocity);
      parser.onStartTag["moveAccel"] = getDVectParser(entityConfig.moveAccel);
      parser.onStartTag["jumpVelocity"] = getDVectParser(entityConfig.jumpVelocity);
      parser.onStartTag["sprite"] = (ElementParser parser) {
        parser.onEndTag["image"] = (in Element e) { entityConfig.image = e.text(); };
        parser.onEndTag["width"] = (in Element e) { entityConfig.width = to!int(e.text()); };
        parser.onEndTag["height"] = (in Element e) { entityConfig.height = to!int(e.text()); };
        parser.onEndTag["maxFrames"] = (in Element e) {
          entityConfig.maxFrames = to!int(e.text());
        };
        parser.parse();
      };
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
    <moveAccel>
      <value>1.0</value>
      <value>1.5</value>
    </moveAccel>
    <jumpVelocity>
      <value>0.0</value>
      <value>-16.0</value>
    </jumpVelocity>
    <!-- Sprite information -->
    <sprite>
      <image>./gfx/yoshi3.png</image>
      <width>32</width>
      <height>32</height>
      <maxFrames>8</maxFrames>
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
  assert(entityConfig.moveAccel == [1.0f, 1.5f],
         "maxAccel " ~ to!string(entityConfig.moveAccel));
  assert(entityConfig.jumpVelocity == [0.0f, -16.0f],
         "maxVelocity " ~ to!string(entityConfig.jumpVelocity));

  assert(entityConfig.image == "./gfx/yoshi3.png");
  assert(entityConfig.width == 32);
  assert(entityConfig.height == 32);
  assert(entityConfig.maxFrames == 8);
  
  assert(entityConfig.collisionBoundary.location == [6, 0]);
  assert(entityConfig.collisionBoundary.width == [20, 32]);
}