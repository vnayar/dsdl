module physics.types;

// Dimentional Vector.  May upgrade to 3D in the future.
alias float[2] DVect;

struct Rectangle {
  DVect location;
  DVect width;
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
  void onCollision();
}

// Objects that gravity may act upon implement Gravitable.
interface Massable : Movable {
  float getMass();
}

// Fields are special containers that perform logic on the contained entities.
interface Field {
  void add(Object entity);
  void onLoop();
}
