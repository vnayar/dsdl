module projectile;

import entity;
import physics.types;

debug import std.stdio;

class Projectile : /*extends*/ Entity {
  private bool _isExploded;

  this() {
    super();
    setIsRenderable(false);
    setIsCollidable(false);
  }

  void shoot() {
    _isExploded = false;
    setIsCollidable(true);
    setIsRenderable(true);
    getSprite().setAnimation("spin");
  }

  override void onCollision(Collidable entity) {
    _isExploded = true;
    getSprite().setAnimation("explode");
    setIsCollidable(false);
  }

  override void animate() {
    bool isComplete = getSprite().animate();
    if (isComplete && _isExploded)
      setIsRenderable(false);
  }
}