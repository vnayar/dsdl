module camera;

import constants; 
import physics.types;

class Camera {
  enum TargetMode {NORMAL, CENTER};

  static Camera CameraControl;

  private int _x;
  private int _y;

  private Locatable _target;

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
      DVect targetPos = _target.getLocation();
      if (_targetMode == TargetMode.CENTER) {
        return cast(int) targetPos[0] - (WWIDTH / 2);
      }
      return cast(int) targetPos[0];
    }
    return _x;
  }

  int getY() {
    if (_target !is null) {
      DVect targetPos = _target.getLocation();
      if (_targetMode == TargetMode.CENTER) {
        return cast(int) targetPos[1] - (WHEIGHT / 2);
      }
      return cast(int) targetPos[1];
    }
    return _y;
  }

  void setPos(int x, int y) {
    _x = x;
    _y = y;
  }

  void setTarget(Locatable target, TargetMode mode=TargetMode.CENTER) {
    _target = target;
    _targetMode = mode;
  }
}
