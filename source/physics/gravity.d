module physics.gravity;

import fps;
import physics.types;

import std.conv, std.stdio;

class SimpleGravityField : Field {
  private Movable[] _entities;
  private DVect _g;

  this(DVect g) {
    _g = g;
  }

  void add(Object entity)
  out {
    assert((_entities.length > 0) && (_entities[$ - 1] !is null));
  } body {
    _entities ~= cast(Movable) entity;
  }

  void onLoop() {
    foreach (entity; _entities) {
      DVect velocity = entity.getVelocity();
      velocity[] += _g[] * Fps.FpsControl.getSpeedFactor();
      entity.setVelocity(velocity);
    }
  }
}

// Unit test for SimpleGravityField.
unittest {
  class Entity : Massable {
    private DVect _location;
    private DVect _velocity;

    this() {
      _location = [0.0f, 0.0f];
      _velocity = [0.0f, 0.0f];
    }

    DVect getLocation() {
      return _location;
    }

    void setLocation(DVect location) {
      _location = location;
    }

    DVect getVelocity() {
      return _velocity;
    }

    void setVelocity(DVect velocity) {
      _velocity = velocity;
    }

    float getMass() {
      return 1.0f;
    }
  }

  SimpleGravityField grav = new SimpleGravityField([0f, 0.5f]);
  Entity bob = new Entity();

  grav.add(bob);
  foreach (i; 0 .. 100) {
    grav.onLoop();
  }

  DVect velocity = bob.getVelocity();

  assert(velocity[0] == 0, "X velocity modified. " ~ to!string(velocity[0]));

  // Allow up to 0.02% error after 100 iterations.
  assert(49.99 < velocity[1] && velocity[1] < 50.01f,
    "Y velocity out of bounds. " ~ to!string(velocity[1]));
}
