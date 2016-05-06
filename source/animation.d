module animation;

import std.xml;
import std.conv;

import derelict.sdl2.sdl;

debug import std.stdio;

class Animation {
private:
  int _frameCurrent = 0;
  int _frameInc     = 1;   // The direction to increment frames (-1 or +1).
  int _frameRate    = 100; // Milliseconds
  long _oldTime     = 0;
  int _frameStart   = 0;
  int _frameEnd     = 0;
  bool _oscillate   = false;

  bool _isComplete  = false;  // Indicates if all frames have been animated.

public:

  @property
  Animation dup() {
    Animation anim = new Animation();
    anim._frameCurrent = _frameCurrent;
    anim._frameInc = _frameInc;
    anim._frameRate = _frameRate;
    anim._oldTime = _oldTime;
    anim._frameStart = _frameStart;
    anim._frameEnd = _frameEnd;
    anim._oscillate = _oscillate;

    return anim;
  }

  void animate() {
    // Wait until the time has come to advance to the next frame.
    if (_oldTime + _frameRate > SDL_GetTicks()) {
      return;
    }

    // Advance our frame and remember when we did it.
    _oldTime += _frameRate;
    _frameCurrent += _frameInc;

    // Either wrap-around or reverse direction depending on oscillate settings.
    if (_oscillate && 
        (_frameCurrent > _frameEnd || _frameCurrent < _frameStart)) {
      _frameInc = -_frameInc;
    } else if (_frameCurrent > _frameEnd) {
      _frameCurrent = _frameStart;
      _isComplete = true;
    }
  }

  void setOscillate(bool oscillate) {
    _oscillate = oscillate;
  }

  int getFrameStart() {
    return _frameStart;
  }

  void setFrameStart(int frameStart) {
    _frameStart = frameStart;
  }

  void setFrameEnd(int frameEnd) {
    _frameEnd = frameEnd;
  }

  void setFrameRate(int rate) {
    _frameRate = rate;
  }

  void setFrameCurrent(int frame) 
    in {
      assert(frame >= _frameStart && frame < _frameEnd, "Frame " ~ to!string(frame) ~
             "is out of bounds " ~ to!string(_frameStart) ~
             " to " ~ to!string(_frameEnd));
    }
  body {
    _frameCurrent = frame;
  }

  bool isComplete() {
    return _isComplete;
  }

  void setIsComplete(bool isComplete) {
    _isComplete = isComplete;
  }

  int getFrameCurrent() {
    return _frameCurrent;
  }

  static void delegate(ElementParser) getXmlParser(out Animation[string] animations) {
    debug writeln("Entering Animation.getXmlParser.");
    return (ElementParser parser) {
      debug writeln("Animation parser.");
      Animation animation = new Animation();
      string id = parser.tag.attr["id"];

      parser.onEndTag["frameInc"] = (in Element e) {
        animation._frameInc = to!int(e.text());
      };
      parser.onEndTag["frameStart"] = (in Element e) {
        animation._frameStart = to!int(e.text());
      };
      parser.onEndTag["frameEnd"] = (in Element e) {
        animation._frameEnd = to!int(e.text());
      };

      parser.parse();

      animations[id] = animation;
    };
  }
}

// XML Parsing test.
unittest {
  string animationsXml = q"EOF
<?xml version="1.0" encoding="UTF-8"?>
<animations>
  <animation id="left">
    <frameInc>2</frameInc>
    <frameStart>0</frameStart>
    <frameEnd>7</frameEnd>
  </animation>
  <animation id="right">
    <frameInc>2</frameInc>
    <frameStart>8</frameStart>
    <frameEnd>15</frameEnd>
  </animation>
</animations>
EOF";

  Animation[string] animations;
  auto xml = new DocumentParser(animationsXml);
  xml.onStartTag["animation"] = Animation.getXmlParser(animations);

  xml.parse();

  assert(animations.length == 2, "animations.length = " ~ to!string(animations.length) ~
         ", expected 2.");
  assert("left" in animations, "Missing animation with id 'left'.");

  Animation animLeft = animations["left"];

  assert(animLeft._frameInc == 2, "animLeft._frameInc = " ~
         to!string(animLeft._frameInc) ~ ", expected 2.");
  assert(animLeft._frameStart == 0, "animLeft._frameStart = " ~
         to!string(animLeft._frameStart) ~ ", expected 0.");
  assert(animLeft._frameEnd == 7, "animLeft._frameEnd = " ~
         to!string(animLeft._frameEnd) ~ ", expected 7.");
}
