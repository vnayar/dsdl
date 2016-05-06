module background;

import std.xml;
import std.algorithm : min;
import derelict.sdl2.sdl;

import surface, camera, constants;
import physics.types;
import resource.image;


/**
 * A background and all associated effects.
 * This may include parallax, redrawing only 'dirty' portions, etc.
 */
class Background {
  private SDL_Texture* _sdlTexture;
  private int _w, _h;

  private bool _hasParallaxBounds;
  private Rectangle _parallaxBounds;

  public void load(in string image) {
    _sdlTexture = ImageBank.IMAGES[image];
    SDL_QueryTexture(_sdlTexture, null, null, &_w, &_h);
  }

  public void render(SDL_Renderer* sdlRenderer) {
    int width = min(_w, WWIDTH);
    int height = min(_h, WHEIGHT);
    int[2] offset = getParallaxOffset();

    Surface.renderTexture(sdlRenderer, 0, 0, _sdlTexture, offset[0], offset[1], width, height);
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
    }
  body {
    if (!_hasParallaxBounds)
      return [0, 0];

    int[2] offset;
    int[2] offsetMax = [
      _w > WWIDTH ? _w - WWIDTH - 1 : 0,
      _h > WHEIGHT ? _h - WHEIGHT - 1 : 0
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

  static void delegate (ElementParser) getXmlParser(out Background background) {
    return (ElementParser parser) {
      string image;
      background = new Background();

      parser.onEndTag["image"] = (in Element e) {
        image = e.text();
      };
      parser.parse();

      background.load(image);
    };
  }
}
