module background;

import derelict.sdl.sdl;

import surface, camera, constants;
import physics.types;


/**
 * A background and all associated effects.
 * This may include parallax, redrawing only 'dirty' portions, etc.
 */
class Background {
  private SDL_Surface* _sdlSurface;

  private bool _hasParallaxBounds;
  private Rectangle _parallaxBounds;

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
    int[2] offset = getParallaxOffset();

    Surface.onDraw(_sdlSurface, offset[0], offset[1], width, height,
        surfDisplay, 0, 0);

  }

  public void setParallaxBounds(Rectangle parallaxBounds) {
    _hasParallaxBounds = true;
    _parallaxBounds = parallaxBounds;
  }

  // Computes what part of the image to show based on camera
  // position and parallax bounds.
  private int[2] getParallaxOffset()
  in {
    assert(!_hasParallaxBounds ||
        (_parallaxBounds.width[0] > 0 && _parallaxBounds.width[1] > 0),
        "Invalid parallax boundary!  Use setParallaxBounds() first.");
  } body {
    if (!_hasParallaxBounds)
      return [0, 0];

    int[2] offset;
    int[2] offsetMax = [
      _sdlSurface.w > WWIDTH ? _sdlSurface.w - WWIDTH - 1 : 0,
      _sdlSurface.h > WHEIGHT ? _sdlSurface.h - WHEIGHT - 1 : 0
    ];

    // Compute what fraction of the bounds the camera is at.
    float[2] cameraLoc = [Camera.CameraControl.getX(), Camera.CameraControl.getY()];
    float[2] parallax = (cameraLoc[] - _parallaxBounds.location[]) / 
      _parallaxBounds.width[];

    // Remember to cast any time data is lost (float to int).
    offset[0] = cast(int)(offsetMax[0] * parallax[0]);
    offset[1] = cast(int)(offsetMax[1] * parallax[1]);

    return offset;
  }
}
