module entity;

import std.stdio;
import derelict.sdl.sdl;

import surface, animation, area, camera, fps;
import physics.types;

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
    _maxVelocity = [20.0f, 30.0f];
    _moveAccel = [2.0f, 3.0f];
    _jumpVelocity = [0.0f, -20.0f];

    _currentFrameCol = 0;
    _currentFrameRow = 0;
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
    Rectangle bounds = getCollisionBoundary();
    DVect entityVelocity = entity.getVelocity();
    DVect transfer = [0.8f, 0.8f];
    DVect reflect = [1.6f, 1.6f];
    _velocity[] += transfer[] * entityVelocity[] *
      Fps.FpsControl.getSpeedFactor();
    entityVelocity[] -= reflect[] * entityVelocity[] *
      Fps.FpsControl.getSpeedFactor();
    entity.setVelocity(entityVelocity);
  }

  // Other

  void setCollisionBoundary(Rectangle boundary) {
    _collisionBoundary = boundary;
  }

  void jump() {
    _velocity[] += _jumpVelocity[] * Fps.FpsControl.getSpeedFactor();
  }

  void setMoveLeft(bool move) {
    _moveLeft = move;
  }

  void setMoveRight(bool move) {
    _moveRight = move;
  }

  bool onLoad(string file, int width, int height, int maxFrames) {
    if ((_surfEntity = Surface.onLoad(file)) == null) {
      return false;
    }

    Surface.setTransparent(_surfEntity, 255, 0, 255);

    _width = width;
    _height = height;

    // FIXME: Get good values, not the entire image.
    _collisionBoundary.location = [0.0f, 0.0f];
    _collisionBoundary.width = [width, height];

    _animControl.setMaxFrames(maxFrames);
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
    if (_surfEntity) {
      SDL_FreeSurface(_surfEntity);
    }
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

    if ((_velocity[0] < 2.0f) && (_velocity[0] > -2.0f))
      _velocity[0] = 0;
  }

}

class EntityCol {
  static EntityCol[] EntityColList;

  Entity entityA;
  Entity entityB;

  this() {
  }
}
