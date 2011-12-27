module animation;

import std.stdio;
import std.conv;

import derelict.sdl.sdl;

class Animation {
  private:
    int _currentFrame;
    int _frameInc;
    int _frameRate; // Milliseconds
    long _oldTime;
    int _maxFrames;
    bool _oscillate;
  public:
    this() {
      _currentFrame = 0;
      _maxFrames = 0;
      _frameInc = 1;
      _frameRate = 100; // Milliseconds
      _oldTime = 0;
      _oscillate = false;
    }

    void onAnimate() {
      writeln("Frame: " ~ to!string(_currentFrame));
      writeln("FrameInc: " ~ to!string(_frameInc));
      writeln("MaxFrames: " ~ to!string(_maxFrames));
      // Wait until the time has come to advance to the next frame.
      if (_oldTime + _frameRate > SDL_GetTicks()) {
        return;
      }

      _oldTime += _frameRate;
      _currentFrame += _frameInc;

      if (_oscillate && 
          (_currentFrame >= _maxFrames - 1 || _currentFrame <= 0)) {
        writeln("Oscillating.");
        _frameInc = -_frameInc;
      } else if (_currentFrame >= _maxFrames - 1) {
        writeln("Wrap around.");
        _currentFrame = 0;
      }
    }

    void setOscillate(bool oscillate) {
      _oscillate = oscillate;
    }

    void setMaxFrames(int maxFrames) {
      _maxFrames = maxFrames;
    }

    void setFrameRate(int rate) {
      _frameRate = rate;
    }

    void setCurrentFrame(int frame) 
    in {
      assert(frame < 0 || frame >= _maxFrames, "Frame is " ~ to!string(frame) ~  " out of bounds.");
    } body {
      _currentFrame = frame;
    }

    int getCurrentFrame() {
      return _currentFrame;
    }
}
