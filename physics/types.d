module physics.types;

// Dimentional Vector.  May upgrade to 3D in the future.
alias float[2] DVect;

struct Rectangle {
  DVect location;
  DVect width;

  bool isIntersect(in Rectangle r2) {
    foreach (i; 0 .. DVect.length) {
      if (location[i] + width[i] <= r2.location[i] ||
          r2.location[i] + r2.width[i] <= location[i])
        return false;
    }
    return true;
  }
  unittest {
    Rectangle r1 = Rectangle([10, 10], [10, 10]);
    Rectangle r2 = Rectangle([20, 10], [10, 10]);
    Rectangle r3 = Rectangle([19, 19], [2, 2]);

    assert(r1.isIntersect(r2) == false);
    assert(r1.isIntersect(r3) == true);

    assert(r1.isIntersect(r2) == r2.isIntersect(r1));
    assert(r1.isIntersect(r3) == r3.isIntersect(r1));
  }
}

interface Locatable {
  DVect getLocation();
  void setLocation(DVect location);
}

interface Movable : Locatable {
  DVect getVelocity();
  void setVelocity(DVect velocity);
}

// Objects that can collide define their boundaries.
interface Collidable : Movable {
  Rectangle getCollisionBoundary();
  void onCollision(Collidable entity);
}

// Objects that gravity may act upon implement Gravitable.
interface Massable : Movable {
  float getMass();
}

// Fields are special containers that perform logic on the contained entities.
interface Field {
  void add(Object entity)
  in {
    assert(entity !is null, "Cannot insert null into field!");
  }

  void onLoop();
}
