module camera;

import constants, entity;

class Camera {
  enum TargetMode {NORMAL, CENTER};

  static Camera CameraControl;

  private int _x;
  private int _y;

  private Entity _target;

  TargetMode _targetMode;

  static this() {
    CameraControl = new Camera();
  }

  void onMove(int moveX, int moveY) {
    _x += moveX;
    _y += moveY;
  }

  int getX() {
    if (_target !is null) {
      if (_targetMode == TargetMode.CENTER) {
        return cast(int) _target.getX() - (WWIDTH / 2);
      }
      return cast(int)_target.getX();
    }
    return _x;
  }

  int getY() {
    if (_target !is null) {
      if (_targetMode == TargetMode.CENTER) {
        return cast(int) _target.getY() - (WHEIGHT / 2);
      }
      return cast(int)_target.getY();
    }
    return _y;
  }

  void setPos(int x, int y) {
    _x = x;
    _y = y;
  }

  void setTarget(Entity target) {
    _target = target;
  }
}
