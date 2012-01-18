module camera;

import std.algorithm;

import constants; 
import physics.types;

class Camera {
  enum TargetMode {NORMAL, CENTER};

  static Camera CameraControl;

  private int _x;
  private int _y;

  private Locatable _target;
  private bool _hasBounds;
  private Rectangle _bounds;

  TargetMode _targetMode;

  static this() {
    CameraControl = new Camera();
  }

  void onMove(int moveX, int moveY) {
    _x += moveX;
    _y += moveY;
  }

  int getX() {
    int x = _x;
    if (_target !is null) {
      DVect targetPos = _target.getLocation();
      if (_targetMode == TargetMode.CENTER) {
        x = cast(int) targetPos[0] - (WWIDTH / 2);
      } else {
        x = cast(int) targetPos[0];
      }
    }
    if (_hasBounds) {
      x = max(x, cast(int) _bounds.location[0]);
      x = min(x, cast(int)(_bounds.location[0] + _bounds.width[0]));
    }
    return x;
  }

  int getY() {
    int y = _y;
    if (_target !is null) {
      DVect targetPos = _target.getLocation();
      if (_targetMode == TargetMode.CENTER) {
        y = cast(int) targetPos[1] - (WHEIGHT / 2);
      } else {
        y = cast(int) targetPos[1];
      }
    }
    if (_hasBounds) {
      y = max(y, cast(int) _bounds.location[1]);
      y = min(y, cast(int)(_bounds.location[1] + _bounds.width[1]));
    }
    return y;
  }

  void setPos(int x, int y) {
    _x = x;
    _y = y;
  }

  void setBounds(Rectangle bounds) {
    _hasBounds = true;
    _bounds = bounds;
  }

  void setTarget(Locatable target, TargetMode mode=TargetMode.CENTER) {
    _target = target;
    _targetMode = mode;
  }
}
