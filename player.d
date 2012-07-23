module player;

import std.xml;
import std.conv;

import entity, fps, sprite;
import physics.types;

debug import std.stdio;

class Player : /*extends*/ Entity {

  private int _projectileIndex = 0;
  private Entity[] _projectiles;

  // Flags letting us know which way the player intends to move.
  // e.g. I 'intend' to go right, but the wind is blowing me left.
  private bool _moveLeft;
  private bool _moveRight;

  // Accelleration when the object desires to move in a direction.
  private DVect _moveAccel;
  private DVect _jumpVelocity;

  this() {
    super();
    _moveAccel = [1.0f, 1.5f];
    _jumpVelocity = [0.0f, -16.0f];
  }

  void jump() {
    DVect velocity = getVelocity();
    velocity[1] = _jumpVelocity[1];
    setVelocity(velocity);
  }

  void setMoveLeft(bool move) {
    _moveLeft = move;
  }

  void setMoveRight(bool move) {
    _moveRight = move;
  }

  void setProjectiles(Entity[] projectiles) {
    _projectiles = projectiles;
  }

  void shootProjectile() {
    Rectangle boundary = getCollisionBoundary();
    DVect startLocation;
    Entity projectile = _projectiles[_projectileIndex];
    Rectangle projectileBoundary = projectile.getCollisionBoundary();

    projectile.setIsCollidable(true);
    projectile.getSprite().setAnimation("spin");

    if (_moveRight) {
      // Place the projectile above the head to the right.
      debug writeln("shooting to the right.");
      startLocation[0] = boundary.location[0] + boundary.width[0] + 1;
      startLocation[1] = boundary.location[1] - projectileBoundary.width[1];
      projectile.setLocation(startLocation);
      DVect velocity = [20.0f, -20.0f];
      projectile.setVelocity(velocity);
    }
    if (_moveLeft) {
      // Place the projectile above the head to the left.
      debug writeln("shooting to the left.");
      startLocation[0] = boundary.location[0] - projectileBoundary.width[0] - 1;
      startLocation[1] = boundary.location[1] - projectileBoundary.width[1];
      projectile.setLocation(startLocation);
      DVect velocity = [-20.0f, -20.0f];
      projectile.setVelocity(velocity);
    }
      
    _projectileIndex++;
    if (_projectileIndex >= _projectiles.length)
      _projectileIndex = 0;
  }

  /**
   * Decellerate the entity when they no longer moving on their own.
   */
  void stopMove() {
    DVect velocity = getVelocity();

    if (velocity[0] < 0)
      velocity[0] += _moveAccel[0] * Fps.FpsControl.getSpeedFactor();
    else if (velocity[0] > 0)
      velocity[0] -= _moveAccel[0] * Fps.FpsControl.getSpeedFactor();

    if ((velocity[0] < 0.25f) && (velocity[0] > -0.25))
      velocity[0] = 0;

    setVelocity(velocity);
  }

  override void animate() {
    Sprite sprite = getSprite();
    if (_moveLeft) {
      sprite.setAnimation("left");
    } else if (_moveRight) {
      sprite.setAnimation("right");
    }
    super.animate();
  }
  

  override void loop() {
    DVect velocity = getVelocity();
    if (!_moveLeft && !_moveRight)
      stopMove();
    if (_moveLeft)
      velocity[0] -= _moveAccel[0] * Fps.FpsControl.getSpeedFactor();
    if (_moveRight)
      velocity[0] += _moveAccel[0] * Fps.FpsControl.getSpeedFactor();
    setVelocity(velocity);
    
    super.loop();
  }

  static void delegate (ElementParser) getXmlParser(out Player[string] players) {
    debug writeln("Entering Player.getXmlParser");
    return (ElementParser parser) {
      debug writeln("Player parser");
      Player player = new Player();
      string id = parser.tag.attr["id"];
      
      player.setEntityConfig(parser.tag.attr["config"]);

      DVect location;
      parser.onStartTag["location"] = getDVectParser(location);

      parser.parse();

      player.setLocation(location);
      players[id] = player;
    };
  }
}
