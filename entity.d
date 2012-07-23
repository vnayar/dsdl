module entity;

import std.stdio;
import std.xml;
import std.conv;

import derelict.sdl.sdl;

import surface, sprite, area, camera, fps;
import sprite, entityconfig;
import physics.types;
import resource.image;

debug {
  import std.stdio;
}


/**
 * Anything that can be interacted with or move other than the map.
 */
class Entity : /*implements*/ Collidable {

  // Image and animation.
  private Sprite _sprite;

  // Store the name of the EntityConfig default settings.
  private string _entityConfig;

  private DVect _location;
  private DVect _velocity;
  private DVect _maxVelocity;


  private Rectangle _collisionBoundary;
  private bool _isCollidable;

  // A singleton list of entities used for cleanup.
  static Entity[] EntityList;

  static this() {
    EntityList = new Entity[0];
  }

  this() {
    _location = [0.0f, 0.0f];
    _velocity = [0.0f, 0.0f];
    _maxVelocity = [10.0f, 15.0f];
    _isCollidable = true;
  }

  string getEntityConfig() {
    return _entityConfig;
  }

  Sprite getSprite() {
    return _sprite;
  }

  void setEntityConfig(string id) {
    _entityConfig = id;
  }

  void setIsCollidable(bool isCollidable) {
    _isCollidable = isCollidable;
  }

  // Locatable Interface

  DVect getLocation() {
    return _location;
  }
  
  void setLocation(DVect location) {
    _location = location;
  }

  // Movable Interface

  DVect getVelocity() {
    return _velocity;
  }

  void setVelocity(DVect velocity) {
    _velocity = velocity;
  }

  // Collidable Interface

  bool isCollidable() {
    return _isCollidable;
  }

  Rectangle getCollisionBoundary() {
    // The boundary is relative to the entity location.
    // We add our current location to put into absolute coordinates.
    Rectangle bounds = _collisionBoundary;
    bounds.location[] += _location[];
    return bounds;
  }

  void onCollision(Collidable entity) {
  }

  // Other

  void setCollisionBoundary(Rectangle boundary) {
    _collisionBoundary = boundary;
  }


  // Allow alternate initialization from a configuration template.
  bool load(EntityConfig entityConfig) {
    _maxVelocity = entityConfig.maxVelocity;
    _collisionBoundary = entityConfig.collisionBoundary;

    _sprite = entityConfig.sprite.dup;
    _sprite.load();

    return true;
  }

  void loop() {
    foreach (i; 0 .. DVect.length) {
      if (_velocity[i] < -_maxVelocity[i])
        _velocity[i] = -_maxVelocity[i];
      if (_velocity[i] > _maxVelocity[i])
        _velocity[i] = _maxVelocity[i];
    }

    animate();
  }

  void render(SDL_Surface* surfDisplay) {
    _sprite.render(surfDisplay, 
        cast(int)_location[0] - Camera.CameraControl.getX(),
        cast(int)_location[1] - Camera.CameraControl.getY());
  }

  void cleanup() {
  }

  void animate() {
    if (_velocity[0] != 0.0f)
      _sprite.animate();
  }

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

  /**
   * Parser logic to read from XML file.
   */
  static void delegate (ElementParser) getXmlParser(out Entity[] entities) {
    debug writeln("Entering Entity.getXmlParser");
    return (ElementParser parser) {
      debug writeln("Entity parser");
      Entity entity = new Entity();
      
      entity._entityConfig = parser.tag.attr["config"];
      
      parser.onStartTag["location"] = getDVectParser(entity._location);

      parser.parse();

      entities ~= entity;
    };
  }
}

unittest {
  string entityXml = q"EOF
<?xml version="1.0" encoding="UTF-8"?>
<!-- Entities that may be interacted with -->
<entities>
  <entity config="yoshi">
    <location>
      <value>20.0</value>
      <value>20.0</value>
    </location>
  </entity>
</entities>
EOF";

  Entity[] entities;
  auto xml = new DocumentParser(entityXml);
  xml.onStartTag["entity"] = Entity.getXmlParser(entities);

  debug writeln("Parsing entities");
  xml.parse();

  Entity entity = entities[0];

  assert(entity.getLocation() == [20.0f, 20.0f],
         "location " ~ to!string(entity.getLocation()));
}