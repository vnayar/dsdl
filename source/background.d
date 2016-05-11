module background;

import std.format : format;
import std.xml : ElementParser, Element;
import std.algorithm : min;
import derelict.sdl2.sdl;

import camera, constants;
import physics.types;
import graphics;



/**
 * A background and all associated effects.
 * This may include parallax, redrawing only 'dirty' portions, etc.
 */
class Background {
  private string _imageName;
  private Image _image;

  private bool _hasParallaxBounds;
  private Rectangle _parallaxBounds;

  public void load(ImageLoader imageLoader) {
    _image = imageLoader.load(_imageName);
  }

  public void render(Display display) {
    int[2] offset = getParallaxOffset();
    int width = min(_image.width-offset[0], display.width);
    int height = min(_image.height-offset[1], display.height);

    display.renderImage(0, 0, _image, offset[0], offset[1], width, height);
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
          format("Invalid parallax boundary!  Use setParallaxBounds() first.\n" ~
                 "_hasParallaxBounds = %d, _parallaxBounds.width[0] = %f, " ~
                 "_parallaxBounds.width[1] = %f",
                 _hasParallaxBounds, _parallaxBounds.width[0], _parallaxBounds.width[1]));
    }
  body {
    if (!_hasParallaxBounds)
      return [0, 0];

    int[2] offset;
    int[2] offsetMax = [
      _image.width > WWIDTH ? _image.width - WWIDTH - 1 : 0,
      _image.height > WHEIGHT ? _image.height - WHEIGHT - 1 : 0
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
      string imageName;
      background = new Background();

      parser.onEndTag["image"] = (in Element e) {
        background._imageName = e.text();
      };
      parser.parse();
    };
  }
}
