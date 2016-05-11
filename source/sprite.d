module sprite;

import std.algorithm : min, max;
import std.conv;
import std.xml;

import derelict.sdl2.sdl;

import animation;
import graphics;

debug import std.stdio;


/**
 * Object for displaying and animating a sprite.
 * A sprite consists of an image divided into a grid of frames,
 * and animation control which dictates what frames to cycle
 * between over time.
 */
class Sprite {
  string imageName;
  int frameWidth;
  int frameHeight;
  Animation[string] animations;

  private Image _image;
  private Animation _animation;

  @property
  Sprite dup() {
    Sprite sprite = new Sprite();
    sprite.imageName = imageName;
    sprite.frameWidth = frameWidth;
    sprite.frameHeight = frameHeight;

    foreach (id, animation; animations)
      sprite.animations[id] = animation.dup;

    sprite._image = _image;
    sprite._animation = _animation;

    return sprite;
  }

  void load(ImageLoader imageLoader)
    in {
      assert(frameWidth > 0);
      assert(frameHeight > 0);
    }
  body {
    _image = imageLoader.load(imageName);

    debug writeln("Sprite _image.width = ", _image.width, " _image.height = ", _image.height);
  }

  void setAnimation(string id)
    in {
      assert(id in animations, "Animation Id '" ~ id ~ "' not found.");
    }
  body {
    _animation = animations[id];
    _animation.setIsComplete(false);
    _animation.setFrameCurrent(_animation.getFrameStart());
  }

  /**
   * Advance the animation.
   * @return true when the animation has finished all frames.
   */
  bool animate()
    in {
      assert(_animation !is null, "Call setAnimation(string) first!");
    }
  body {
    _animation.animate();
    return _animation.isComplete();
  }

  void render(Display display, int x, int y)
    in {
      assert(_animation !is null, "Call setAnimation(string) first!");
      assert(_image != Image.init, "Call load() before rendering!");
    }
  body {
    if (x + frameWidth <= 0 || x >= display.width || y + frameWidth <= 0 || y >= display.height)
      return;

    int frame = _animation.getFrameCurrent();
    int frameX = frame % (_image.width / frameWidth);
    int frameY = frame / (_image.width / frameWidth);

    int srcX = frameX * frameWidth + max(0, -x);
    int srcY = frameY * frameHeight + max(0, -y);
    int srcWidth = frameWidth - max(0, -x);
    int srcHeight = frameHeight - max(0, -y);

    display.renderImage(max(x, 0), max(y, 0),
        _image, srcX, srcY,
        min(srcWidth, display.width - x), min(srcHeight, display.height - y));
  }

  static void delegate(ElementParser) getXmlParser(out Sprite sprite) {
    debug writeln("Entering Sprite.getXmlParser.");
    return (ElementParser parser) {
      debug writeln("Parsing Sprite.");
      sprite = new Sprite();

      parser.onEndTag["image"] = (in Element e) {
        sprite.imageName = e.text();
      };
      parser.onEndTag["frameWidth"] = (in Element e) {
        sprite.frameWidth = to!int(e.text());
      };
      parser.onEndTag["frameHeight"] = (in Element e) {
        sprite.frameHeight = to!int(e.text());
      };

      parser.onStartTag["animation"] = Animation.getXmlParser(sprite.animations);

      parser.parse();
    };
  }
}

unittest {
  string spriteXml = q"EOF
<?xml version="1.0" encoding="UTF-8"?>
<data>
  <sprite>
    <image>./gfx/yoshi3.png</image>
    <frameWidth>32</frameWidth>
    <frameHeight>32</frameHeight>
    <animations>
      <animation id="bob"></animation>
      <animation id="cat"></animation>
    </animations>
  </sprite>
</data>
EOF";

  Sprite sprite;
  auto xml = new DocumentParser(spriteXml);
  xml.onStartTag["sprite"] = Sprite.getXmlParser(sprite);

  xml.parse();

  assert(sprite.frameWidth == 32);
  assert(sprite.frameHeight == 32);
  assert(sprite.imageName == "./gfx/yoshi3.png");
  assert(sprite.animations.length == 2);
}
