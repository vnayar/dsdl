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
    assert(is(entity : Collidable));
  } body {
    _entities ~= cast(Collidable) entity;
  }

  void onLoop() {
    foreach (entity; _entities) {
      // Our copy of speed so we know how far to go.
      DVect move = entity.getVelocity()[] * Fps.FpsControl.getSpeedFactor();
      onMove(entity, move);
    }

    // We detect collisions before calling 'onCollision' to prevent
    // an entity from reacting in a way that invalidates later detection.
    // e.g. Bullet his Mario and explodes before Mario detects collision.
    Collidable[2][] collisions;
    foreach (entity; _entities) {
      // FIXME: Add entity data structure that makes it clear who may collide.
      //   e.g. Divide the area into sections, and assign entities to their
      //        sections, and only check collisions within a section.
      Rectangle boundary = entity.getCollisionBoundary();
      foreach (entity2; _entities) {
        if (entity is entity2)
          continue;
        if (boundary.isIntersect(entity2.getCollisionBoundary())) {
          collisions ~= [entity, entity2];
        }
      }
    }

    foreach (collision; collisions) {
      collision[0].onCollision(collision[1]);
    }
  }
}
