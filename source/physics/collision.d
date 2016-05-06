module physics.collision;

import physics.types;

import std.stdio;
import std.conv, std.math;

// FIXME: Remove these dependencies later.
import constants, area, tile, fps;


class CollisionField : Field {
  private Collidable[] _entities;

  private bool isLocationValidTile(in Rectangle boundary) {
    // In absolute coordinates, the boundary.
    int[DVect.length] startLoc;
    int[DVect.length] endLoc;
    foreach (i; 0 .. DVect.length) {
      startLoc[i] = cast(int)boundary.location[i];
      endLoc[i] = startLoc[i] + cast(int) boundary.width[i] - 1;

      // Convert our boundaries into tile numbers.
      startLoc[i] = startLoc[i] / TILE_SIZE;
      endLoc[i] = endLoc[i] / TILE_SIZE;
    }

    for (auto tileX = startLoc[0]; tileX <= endLoc[0]; tileX++) {
      for (auto tileY = startLoc[1]; tileY <= endLoc[1]; tileY++) {
        auto tile = Area.AreaControl.getTile(tileX * TILE_SIZE, tileY * TILE_SIZE);
        // No collision if there's nothing to collide with.
        if (tile is null)
          continue;
        if (tile.type == Tile.Type.BLOCK) {
          return false;
        }
      }
    }

    return true;
  }

  private void onMove(Collidable entity, in DVect move) {
    auto location = entity.getLocation();
    auto velocity = entity.getVelocity();
    auto boundary = entity.getCollisionBoundary();

    // FIXME:  Calculate the movement vector, then incrementally move rather
    //   than by a single coordinate at a time.
    foreach (i; 0 .. DVect.length) {
      // The total distance to move on this coordinate.
      int scale = cast(int) abs(move[i]);
      // Gives -1 for negative numbers, +1 for positive numbers.
      int unit = 1 - 2 * signbit(move[i]);

      bool collision = true;

      while (scale > 0) {
        Rectangle incBoundary = boundary;
        if (unit >= 0) {
          incBoundary.location[i] = boundary.location[i] + boundary.width[i];
          incBoundary.width[i] = scale;
        } else {
          incBoundary.location[i] = boundary.location[i] - scale;
          incBoundary.width[i] = scale;
        }
        // This may trigger a collision event.
        if (isLocationValidTile(incBoundary)) {
          // Move all at once if there is no collision.
          collision = false;
          location[i] += scale * unit;
          scale = 0;
        } else {
          // Try a less drastic move.
          scale -= 1;
        }
      }

      // Go directly into wall, do not pass Go.
      if (collision)
        velocity[i] = 0.0f;
    }
    entity.setVelocity(velocity);
    entity.setLocation(location);
  }

  void add(Object entity)
  in {
    assert(cast(Collidable) entity);
  } body {
    _entities ~= cast(Collidable) entity;
  }

  void onLoop() {
    // Perform actual movement and check for tile collision.
    foreach (entity; _entities) {
      // Our copy of speed so we know how far to go.
      DVect move = entity.getVelocity()[] * Fps.FpsControl.getSpeedFactor();
      onMove(entity, move);
    }

    // We detect collisions before calling 'onCollision' to prevent
    // an entity from reacting in a way that invalidates later detection.
    // e.g. Bullet his Mario and explodes before Mario detects collision.
    Collision[] collisions;
    foreach (entity1; _entities) {
      if (entity1.isCollidable() == false)
        continue;
      // FIXME: Add entity data structure that makes it clear who may collide.
      //   e.g. Divide the area into sections, and assign entities to their
      //        sections, and only check collisions within a section.
      Rectangle boundary1 = entity1.getCollisionBoundary();
      foreach (entity2; _entities) {
        if (entity2.isCollidable() == false)
          continue;
        // Avoid self-collision.
        if (entity1 is entity2)
          continue;

        Rectangle boundary2 = entity2.getCollisionBoundary();
        if (boundary1.isIntersect(boundary2)) {
          Collision collision = new Collision();
          collision.collidable1 = entity1;
          collision.collidable2 = entity2;
          collision.velocity1 = entity1.getVelocity();
          collision.velocity2 = entity2.getVelocity();
          collisions ~= collision;
        }
      }
    }

    // Our 'correctLocation' logic means only 1 collision per pair.
    foreach (collision; collisions) {
      correctLocation(collision);
      collidePhysics(collision);

      collision.collidable1.onCollision(collision.collidable2);
      collision.collidable2.onCollision(collision.collidable1);
    }
  }

  /**
   * Perform impulse and velocity updates.
   */
  void collidePhysics(Collision collision) {
    DVect velocity1 = collision.velocity1;
    DVect velocity2 = collision.velocity2;
    DVect transfer = [1.5f, 1.5f];
    DVect relativeVelocity = velocity2[] - velocity1[];

    velocity1[] += transfer[] * relativeVelocity[];
    collision.collidable1.setVelocity(velocity1);
  }

  /**
   * Re-position entities to avoid overlap after a collision.
   */
  void correctLocation(Collision collision) {
    Rectangle boundary1 = collision.collidable1.getCollisionBoundary();
    Rectangle boundary2 = collision.collidable2.getCollisionBoundary();

    if (!boundary1.isIntersect(boundary2)) return;

    // Move entity1 back from where it came until there is no collision.
    DVect relativeVelocity = collision.velocity2[] - collision.velocity1[];

    // Make sure we move no more than 1 pixel at a time in any direction.
    float maxScale = getMaxScale(relativeVelocity);
    if (maxScale == 0.0f) {
      // FIXME:  Pick a default direction if the object is not moving.
      relativeVelocity = [1.0f, 0.0f];
      return;
    }
    DVect backMove = relativeVelocity[] / maxScale;

    // Back that assumption up.
    DVect loc1 = collision.collidable1.getLocation();
    while (boundary1.isIntersect(boundary2)) {
      boundary1.location[] += backMove[];

      // Stop if we are going to put the entity inside a tile.
      if (!isLocationValidTile(boundary1)) break;

      loc1[] += backMove[];
    }
    collision.collidable1.setLocation(loc1);
  }

  float getMaxScale(DVect vect) {
    float maxScale = 0.0f;
    foreach (v; vect) {
      maxScale = abs(v) > maxScale ? abs(v) : maxScale;
    }
    return maxScale;
  }
}

class Collision {
  Collidable collidable1, collidable2;
  DVect velocity1, velocity2;
}
