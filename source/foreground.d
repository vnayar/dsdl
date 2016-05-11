module foreground;

import derelict.sdl2.sdl;

import graphics;
import camera;
import map;

debug import std.stdio;


class Foreground {
  private Map _map;
  private int _x;
  private int _y;
  private bool _followCameraX;
  private bool _followCameraY;

  this() {
    _map = new Map();
  }

  void load(in string fileName, ImageLoader imageLoader) {
    _map.loadFromTmxFile(fileName, imageLoader);
  }

  void render(Display display) {
    int screenX = 0;
    if (!_followCameraX)
      screenX = _x - Camera.CameraControl.getX();

    int screenY = 0;
    if (!_followCameraY)
      screenY = _y - Camera.CameraControl.getY();

    _map.render(display, screenX, screenY);
  }

  void setFollowCameraX(bool followCameraX) {
    _followCameraX = true;
  }

  void setFollowCameraY(bool followCameraY) {
    _followCameraY = true;
  }

  void setX(int x) {
    _x = x;
  }

  void setY(int y) {
    _y = y;
  }
}
