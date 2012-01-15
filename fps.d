module fps;

import derelict.sdl.sdl;

class Fps {
  static Fps FpsControl;

  private int _oldTime;
  private int _lastTime;

  private float _speedFactor = 1.0f;

  private int _numFrames;
  private int _frames;

  static this() {
    FpsControl = new Fps();
  }

  void onLoop() {
    if (_oldTime + 1000 < SDL_GetTicks()) {
      _oldTime = SDL_GetTicks();

      _numFrames = _frames;
      _frames = 0;
    }

    _speedFactor = ((SDL_GetTicks() - _lastTime) / 1000.0f) * 32.0f;

    _lastTime = SDL_GetTicks();

    _frames++;
  }

  int getFps() {
    return _numFrames;
  }

  float getSpeedFactor() {
    return _speedFactor;
  }
}
