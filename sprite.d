module sprite;

import std.xml;
import std.conv;

import derelict.sdl.sdl;

import surface, animation;
import resource.image;

debug import std.stdio;


/**
 * Object for displaying and animating a sprite.
 * A sprite consists of an image divided into a grid of frames,
 * and animation control which dictates what frames to cycle
 * between over time.
 */
class Sprite {
  string image;
  int frameWidth;
  int frameHeight;
  Animation[string] animations;

  private SDL_Surface* _surface;
  private Animation _animation;
  private int _width;
  private int _height;
  
  @property
  Sprite dup() {
    Sprite sprite = new Sprite();
    sprite.image = image;
    sprite.frameWidth = frameWidth;
    sprite.frameHeight = frameHeight;
    
    foreach (id, animation; animations)
      sprite.animations[id] = animation.dup;

    sprite._surface = _surface;
    sprite._animation = _animation;
    sprite._width = _width;
    sprite._height = _height;

    return sprite;
  }

  void load()
    in {
      assert(frameWidth > 0);
      assert(frameHeight > 0);
    }
  body {
    _surface = ImageBank.IMAGES[image];
    Surface.setTransparent(_surface, 255, 0, 255);
    _width = _surface.w / frameWidth;
    _height = _surface.h / frameHeight;

    debug writeln("Sprite _width = ", _width, " _height = ", _height);
  }

  void setAnimation(string id)
    in {
      assert(id in animations, "Animation Id '" ~ id ~ "' not found.");
    }
  body {
    _animation = animations[id];
  }

  void animate()
    in {
      assert(_animation !is null, "Call setAnimation(string) first!");
    }
  body {
    _animation.animate();
  }

  void render(SDL_Surface* surfDisplay, int x, int y)
    in {
      assert(_animation !is null, "Call setAnimation(string) first!");
      assert(_surface !is null, "Call load() before rendering!");
      assert(_width > 0);
      assert(_height > 0);
    }
  body {
    int frame = _animation.getFrameCurrent();
    int frameX = frame % _width;
    int frameY = frame / _width;
    Surface.onDraw(_surface,
                   frameX * frameWidth, frameY * frameHeight,
                   frameWidth, frameHeight,
                   surfDisplay, x, y);
  }

  static void delegate(ElementParser) getXmlParser(out Sprite sprite) {
    debug writeln("Entering Sprite.getXmlParser.");
    return (ElementParser parser) {
      debug writeln("Parsing Sprite.");
      sprite = new Sprite();

      parser.onEndTag["image"] = (in Element e) {
        sprite.image = e.text();
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
  assert(sprite.image == "./gfx/yoshi3.png");
  assert(sprite.animations.length == 2);
}