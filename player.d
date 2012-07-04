module player;

import std.xml;
import std.conv;

import entity;
import physics.types;
import resource.image;


class Player : /*extends*/ Entity {
  this() {
  }

  // FIXME: Find a logical place for this.
  static void delegate(ElementParser) getDVectParser(ref DVect vect) {
    return (ElementParser parser) {
      int index = 0;
      parser.onEndTag["value"] = (in Element e) {
        vect[index++] = to!float(e.text());
      };
      parser.parse();
    };
  }

  static void delegate(ElementParser) getXmlParser(out Player[string] players) {
    return (ElementParser parser) {
      Player player = new Player();
      string image;
      string id = parser.tag.attr["id"];

      parser.onStartTag["maxVelocity"] = getDVectParser(player._maxVelocity);
      parser.onStartTag["moveAccel"] = getDVectParser(player._moveAccel);
      parser.onStartTag["jumpVelocity"] = getDVectParser(player._jumpVelocity);
      parser.onStartTag["sprite"] = (ElementParser parser) {
        parser.onEndTag["image"] = (in Element e) {
          player._surfEntity = ImageBank.IMAGES[e.text()];
        };
        parser.onEndTag["width"] = (in Element e) { player._width = to!int(e.text()); };
        parser.onEndTag["height"] = (in Element e) { player._height = to!int(e.text()); };
        parser.onEndTag["maxFrames"] = (in Element e) {
          player._animControl.setMaxFrames(to!int(e.text()));
        };
        parser.parse();
      };
      parser.onStartTag["collisionBoundary"] = (ElementParser parser) {
        parser.onStartTag["location"] = getDVectParser(player._collisionBoundary.location);
        parser.onStartTag["width"] = getDVectParser(player._collisionBoundary.width);
        parser.parse();
      };
      parser.onStartTag["location"] = getDVectParser(player._location);

      parser.parse();

      players[id] = player;
    };
  }
}
