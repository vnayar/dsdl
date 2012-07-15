module player;

import std.xml;
import std.conv;

import entity;

debug import std.stdio;

class Player : /*extends*/ Entity {
  static void delegate (ElementParser) getXmlParser(out Player[string] players) {
    debug writeln("Entering Player.getXmlParser");
    return (ElementParser parser) {
      debug writeln("Player parser");
      Player player = new Player();
      string id = parser.tag.attr["id"];
      
      player.setEntityConfig(parser.tag.attr["config"]);
      
      parser.onStartTag["location"] = getDVectParser(player._location);

      parser.parse();

      players[id] = player;
    };
  }
}
