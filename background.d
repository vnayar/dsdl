module background;

import derelict.sdl.sdl;

import surface, camera, constants;


/**
 * A background and all associated effects.
 * This may include parallax, redrawing only 'dirty' portions, etc.
 */
class Background {
  private SDL_Surface* _sdlSurface;

  public this() {}
  public ~this() {
    if (_sdlSurface)
      SDL_FreeSurface(_sdlSurface);
  }

  public void onLoad(in string file) {
    // Make sure we don't send the old surface into space.
    if (_sdlSurface)
      SDL_FreeSurface(_sdlSurface);

    _sdlSurface = Surface.onLoad(file);
  }

  public void onRender(SDL_Surface* surfDisplay) {
    int width = _sdlSurface.w < WWIDTH ? _sdlSurface.w : WWIDTH;
    int height = _sdlSurface.h < WHEIGHT ? _sdlSurface.h : WHEIGHT;
    Surface.onDraw(_sdlSurface, 0, 0, width, height,
        surfDisplay, 0, 0);
  }
}
