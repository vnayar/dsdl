module entity;

import std.stdio;
import std.xml;
import std.conv;

import derelict.sdl.sdl;

import surface, animation, area, camera, fps;
import entityconfig;
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

  protected Animation _animControl;
  protected SDL_Surface* _surfEntity;

  // The size of our image cell.
  protected int _width;
  protected int _height;

  int _currentFrameCol;
  int _currentFrameRow;

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
    _animControl = new Animation();
    _location = [0.0f, 0.0f];
    _velocity = [0.0f, 0.0f];
    _maxVelocity = [10.0f, 15.0f];
    _moveAccel = [1.0f, 1.5f];
    _jumpVelocity = [0.0f, -16.0f];

    _currentFrameCol = 0;
    _currentFrameRow = 0;
  }

  string getEntityConfig() {
    return _entityConfig;
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

  bool onLoad(string file, int width, int height, int maxFrames) {
    _surfEntity = ImageBank.IMAGES[file];

    Surface.setTransparent(_surfEntity, 255, 0, 255);

    _width = width;
    _height = height;

    // FIXME: Get good values, not the entire image.
    _collisionBoundary.location = [0.0f, 0.0f];
    _collisionBoundary.width = [width, height];

    _animControl.setMaxFrames(maxFrames);
    return true;
  }

  // Allow alternate initialization from a configuration template.
  bool onLoad(EntityConfig entityConfig) {
    onLoad(entityConfig.image, entityConfig.width, entityConfig.height, entityConfig.maxFrames);
    _maxVelocity = entityConfig.maxVelocity;
    _moveAccel = entityConfig.moveAccel;
    _jumpVelocity = entityConfig.jumpVelocity;
    _collisionBoundary = entityConfig.collisionBoundary;
    return true;
  }

  void onLoop() {
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

    onAnimate();
  }

  void onRender(SDL_Surface* surfDisplay) {
    if (_surfEntity == null || surfDisplay == null) return;

    Surface.onDraw(_surfEntity, 
        _currentFrameCol * _width, _animControl.getCurrentFrame() * _height,
        _width, _height,
        surfDisplay,
        cast(int)_location[0] - Camera.CameraControl.getX(),
        cast(int)_location[1] - Camera.CameraControl.getY());
  }

  void onCleanup() {
    _surfEntity = null;
  }

  void onAnimate() {
    if (_moveLeft) {
      _currentFrameCol = 0;
    } else if (_moveRight) {
      _currentFrameCol = 1;
    }
    if (_velocity[0] == 0.0f) {
      _animControl.setMaxFrames(0);
    } else {
      _animControl.setMaxFrames(8);
    }
    _animControl.onAnimate();
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
   * 
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