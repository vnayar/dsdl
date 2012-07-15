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
  enum Type {
    GENERIC,
    PLAYER
  };

  enum Flag {
    NONE,
    GRAVITY = 0x00000001, 
    GHOST   = 0x00000002,
    MAPONLY = 0x00000004
  };

  // Image and animation.
  private Sprite _sprite;

  // Flags letting us know which way the player intends to move.
  // e.g. I 'intend' to go right, but the wind is blowing me left.
  bool _moveLeft;
  bool _moveRight;

  // Store the name of the EntityConfig default settings.
  protected string _entityConfig;

  protected DVect _location;
  protected DVect _velocity;
  protected DVect _maxVelocity;
  protected DVect _jumpVelocity;

  // Accelleration when the object desires to move in a direction.
  protected DVect _moveAccel;

  Rectangle _collisionBoundary;

  Type _type;
  bool _dead;
  int _flags;

  // A singleton list of entities used for cleanup.
  static Entity[] EntityList;

  static this() {
    EntityList = new Entity[0];
  }

  this() {
    _location = [0.0f, 0.0f];
    _velocity = [0.0f, 0.0f];
    _maxVelocity = [10.0f, 15.0f];
    _moveAccel = [1.0f, 1.5f];
    _jumpVelocity = [0.0f, -16.0f];
  }

  string getEntityConfig() {
    return _entityConfig;
  }

  void setEntityConfig(string id) {
    _entityConfig = id;
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

  void jump() {
    _velocity[1] = _jumpVelocity[1];
  }

  void setMoveLeft(bool move) {
    _moveLeft = move;
  }

  void setMoveRight(bool move) {
    _moveRight = move;
  }

  // Allow alternate initialization from a configuration template.
  bool load(EntityConfig entityConfig) {
    _maxVelocity = entityConfig.maxVelocity;
    _moveAccel = entityConfig.moveAccel;
    _jumpVelocity = entityConfig.jumpVelocity;
    _collisionBoundary = entityConfig.collisionBoundary;

    _sprite = entityConfig.sprite.dup;
    _sprite.load();
    // TODO:  Find a better way to set the default animation.
    _sprite.setAnimation("right");

    return true;
  }

  void loop() {
    if (!_moveLeft && !_moveRight)
      stopMove();
    if (_moveLeft)
      _velocity[0] -= _moveAccel[0] * Fps.FpsControl.getSpeedFactor();
    if (_moveRight)
      _velocity[0] += _moveAccel[0] * Fps.FpsControl.getSpeedFactor();
    
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
    if (_moveLeft) {
      _sprite.setAnimation("left");
    } else if (_moveRight) {
      _sprite.setAnimation("right");
    }
    if (_velocity[0] != 0.0f)
      _sprite.animate();
  }

  /**
   * Decellerate the entity when they no longer moving on their own.
   */
  void stopMove() {
    if (_velocity[0] < 0)
      _velocity[0] += _moveAccel[0] * Fps.FpsControl.getSpeedFactor();
    else if (_velocity[0] > 0)
      _velocity[0] -= _moveAccel[0] * Fps.FpsControl.getSpeedFactor();

    if ((_velocity[0] < 0.25f) && (_velocity[0] > -0.25))
      _velocity[0] = 0;
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
  static void delegate (ElementParser) getXmlParser(out Entity[string] entities) {
    debug writeln("Entering Entity.getXmlParser");
    return (ElementParser parser) {
      debug writeln("Entity parser");
      Entity entity = new Entity();
      string id = parser.tag.attr["id"];
      
      entity._entityConfig = parser.tag.attr["config"];
      
      parser.onStartTag["location"] = getDVectParser(entity._location);

      parser.parse();

      entities[id] = entity;
    };
  }
}


class EntityCol {
  static EntityCol[] EntityColList;

  Entity entityA;
  Entity entityB;

  this() {
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