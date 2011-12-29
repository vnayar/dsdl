module entity;

import derelict.sdl.sdl;

import surface, animation;

class Entity {
  public:
    static Entity[] EntityList;

  protected:
    Animation _animControl;
    SDL_Surface* _surfEntity;

  public:
    float _x;
    float _y;

    int _width;
    int _height;

    int _animState;

    static this() {
      EntityList = new Entity[0];
    }

    this() {
      _surfEntity = null;
      _x = 0.0f;
      _y = 0.0f;
      _width = 0;
      _height = 0;
      _animState = 0;
      _animControl = new Animation();
    }

    void setX(float x) {
      _x = x;
    }

    void setY(float y) {
      _y = y;
    }

    bool onLoad(string file, int width, int height, int maxFrames) {
      if ((_surfEntity = Surface.onLoad(file)) == null) {
        return false;
      }

      Surface.setTransparent(_surfEntity, 255, 0, 255);

      _width = width;
      _height = height;

      _animControl.setMaxFrames(maxFrames);
      return true;
    }

    void onLoop() {
      _animControl.onAnimate();
    }

    void onRender(SDL_Surface* surfDisplay) {
      if (_surfEntity == null || surfDisplay == null) return;

      Surface.onDraw(_surfEntity, 
        _animState * _width, _animControl.getCurrentFrame() * _height,
        _width, _height,
        surfDisplay, cast(int)_x, cast(int)_y);
    }

    void onCleanup() {
      if (_surfEntity) {
        SDL_FreeSurface(_surfEntity);
      }
      _surfEntity = null;
    }
}
