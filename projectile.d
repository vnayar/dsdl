module projectile;

import entity;
import physics.types;

debug import std.stdio;

class Projectile : /*extends*/ Entity {
  override void onCollision(Collidable entity) {
    getSprite().setAnimation("explode");
    setIsCollidable(false);
  }
}