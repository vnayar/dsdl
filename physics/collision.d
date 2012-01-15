module physics.collision;

import physics.types;

import std.stdio;
import std.conv, std.math;

// FIXME: Remove these dependencies later.
import constants, area, tile, fps;


class CollisionField : Field {
  private Collidable[] _entities;

  private bool isIntersect(Rectangle r1, Rectangle r2) {
    foreach (i; 0 .. DVect.length) {
      if (r1.location[i] + r1.width[i] < r2.location[i] ||
          r2.location[i] + r2.width[i] < r1.location[i])
        return false;
    }
    return true;
  }

  /**
   * FIXME: The set of colliders should not be hard-coded, but each one
   *   should be an object added to this one.
   */
  private bool isLocationValid(Collidable entity, DVect location) {
    return true;
    //return isLocationValidTile(entity, location);
  }

  private bool isLocationValidTile(Collidable entity, DVect location) {
    auto collision = entity.getCollisionBoundary();

    // In absolute coordinates, the boundary if entity moved to location.
    int[DVect.length] startLoc = (cast(int[]) location)[] + 
        (cast(int[]) collision.location)[];
    int[DVect.length] endLoc = startLoc[] + (cast(int[]) collision.width)[];

    // Convert our boundaries into tile numbers.
    startLoc[] = startLoc[] / TILE_SIZE;
    endLoc[] = endLoc[] / TILE_SIZE;

    for (auto tileX = startLoc[0]; tileX <= endLoc[0]; tileX++) {
      for (auto tileY = startLoc[1]; tileY < endLoc[1]; tileY++) {
        auto tile = Area.AreaControl.getTile(tileX * TILE_SIZE, tileY * TILE_SIZE);
        // No collision if there's nothing to collide with.
        if (tile is null)
          continue;
        if (tile.type == Tile.Type.BLOCK) {
          // TODO:  Add logic to add a new collision.
          return false;
        }
      }
    }

    return true;
  }

  private bool isLocationValidEntity(Collidable entity, DVect location) {
    // TODO
    return true;
  }

  private void onMove(Collidable entity, DVect move) {
    auto location = entity.getLocation();
    // FIXME:  Calculate the movement vector, then incrementally move rather
    //   than by a single coordinate at a time.
    foreach (i; 0 .. DVect.length) {
      // The total distance to move on this coordinate.
      float scale = abs(move[i]);
      // Gives -1 for negative numbers, +1 for positive numbers.
      float unit = 1 - 2 * signbit(move[i]);
      while (scale > 0) {
        auto nextLocation = location;
        nextLocation[i] += unit;
        // This may trigger a collision event.
        if (isLocationValid(entity, nextLocation)) {
          location[i] += unit;
          scale -= 1;
        } else {
          // Stop moving in the direction in which we collide.
          scale = 0;
        }
      }
    }
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
  }
}
