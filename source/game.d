module game;

import std.file : read;
import std.xml;
import std.conv;
import std.string : fromStringz;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

import constants, event, entityconfig, entity, player, projectile;
import area, camera, background, foreground, level;
import physics.types, physics.collision, physics.gravity;
import graphics;

debug import std.stdio : writeln, writefln;

alias Scancode = int;

class Game {
  private bool _running;

  private Display display;

  private Player[string] _players;

  private SimpleGravityField _gravityField;
  private CollisionField _collisionField;

  // Eventually store all level-specific data here.
  private Level _level;
  private Foreground _foreground;

  private int _waterLevel;

  // Our inner-class defines how we handle events.
  private class GameEventDispatcher : EventDispatcher {
    private void delegate()[Scancode] _scanCodeDownHandlers;
    private void delegate()[Scancode] _scanCodeUpHandlers;

    public void onLoad(string fileName)
      in {
        debug writeln("_players.length = ", _players.length);
        assert(_players.length > 0, "Call loadPlayersFromXML() before loading controls.");
      }
    body {
      string xmlData = cast(string) read(fileName);
      auto xml = new DocumentParser(xmlData);
      xml.onStartTag["control"] = (ElementParser parser) {
        string id = parser.tag.attr["id"];
        if (id !in _players)
          throw new Exception("Cannot find player '" ~ id ~ "'.");
        Player player = _players[id];

        parser.onEndTag["quit"] = (in Element e) {
          _scanCodeDownHandlers[to!Scancode(e.text())] = delegate() {
            _running = false;
          };
        };
        parser.onEndTag["jump"] = (in Element e) {
          _scanCodeDownHandlers[to!Scancode(e.text())] = delegate() {
            player.jump();
          };
        };
        parser.onEndTag["moveLeft"] = (in Element e) {
          _scanCodeDownHandlers[to!Scancode(e.text())] = delegate() {
            player.setMoveLeft(true);
          };
          _scanCodeUpHandlers[to!Scancode(e.text())] = delegate() {
            player.setMoveLeft(false);
          };
        };
        parser.onEndTag["moveRight"] = (in Element e) {
          _scanCodeDownHandlers[to!Scancode(e.text())] = delegate() {
            player.setMoveRight(true);
          };
          _scanCodeUpHandlers[to!Scancode(e.text())] = delegate() {
            player.setMoveRight(false);
          };
        };
        parser.onEndTag["shootProjectile"] = (in Element e) {
          _scanCodeDownHandlers[to!Scancode(e.text())] = delegate() {
            player.shootProjectile();
          };
        };
        parser.parse();
      };
      xml.parse();
    }

    public:
      override void onExit() {
        this.outer._running = false;
      }

      override void onKeyDown(SDL_Scancode scancode, SDL_Keycode sym, Uint16 mod, Uint32 unicode) {
        debug writefln("onKeyDown scancode=%d, sym=%d", scancode, sym);
        if (scancode in _scanCodeDownHandlers)
          _scanCodeDownHandlers[scancode]();
      }

      override void onKeyUp(SDL_Scancode scancode, SDL_Keycode sym, Uint16 mod, Uint32 unicode) {
        if (scancode in _scanCodeUpHandlers)
          _scanCodeUpHandlers[scancode]();
      }

  }

  // Allow multiple subtyping by creating an alias for this.
  private GameEventDispatcher _eventDispatcher;
  alias _eventDispatcher this;


  public this() {
    _running = true;
    _eventDispatcher = this.new GameEventDispatcher();
    _gravityField = new SimpleGravityField([0.0f, 3.0f]);
    _collisionField = new CollisionField();

	_level = new Level();
    _foreground = new Foreground();

    display = new Display(WWIDTH, WHEIGHT);
  }

  public int execute() {
    if (init() == false) {
      return -1;
    }

    SDL_Event event;

    while (_running) {
      while (SDL_PollEvent(&event)) {
        this.onEvent(event);
      }
      loop();
      render();
    }

    cleanup();

    return 0;
  }

  // TODO: Cleanly separate init and load phases.
  //   init = Simple data initialization, reading from XML, etc.
  //   load = Memory allocation laden loading, such as image files.
  public bool init() {
    display.init();

    loadPlayersFromXmlFile("./config/players.xml", display.getImageLoader());

    _eventDispatcher.onLoad("./config/controls.xml");

    // Now load the landscape we we play on.
    _level.loadFromXmlFile("./levels/level1.xml", display.getImageLoader());

    // Set up our fields.
    foreach (entity; Entity.EntityList) {
      _gravityField.add(entity);
      _collisionField.add(entity);
    }

    // Set bounds for how far the camera may move.
    Rectangle cameraBounds = Rectangle(
      [0, 0],
      [
        Area.AreaControl.getWidth() - display.width,
        Area.AreaControl.getHeight() - display.height
      ]
    );
    Camera.CameraControl.setBounds(cameraBounds);
    // Let the background parallax with the camera.
    _level.background.setParallaxBounds(cameraBounds);

    // Set the camera to track our Yoshi.
    Camera.CameraControl.setTarget(_players["player1"]);

    _waterLevel = Area.AreaControl.getHeight();
    _foreground.load("./maps/Water.tmx", display.getImageLoader());
    _foreground.setFollowCameraX(true);
    _foreground.setY(_waterLevel);

    return true;
  }

  // TODO: Move this code into player.d.
  private void loadPlayersFromXmlFile(string fileName, ImageLoader imageLoader) {
    string xmlData = cast(string) read(fileName);
    auto xml = new DocumentParser(xmlData);
    EntityConfig[string] entityConfigs;

    xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);
    xml.onStartTag["player"] = Player.getXmlParser(_players);
    xml.parse();

    foreach (player; _players) {
      EntityConfig entityConfig = entityConfigs[player.getEntityConfig()];
      player.load(entityConfig, imageLoader);
      player.getSprite().setAnimation("right");
      Entity.EntityList ~= player;

      // Create balloons for the player to throw.
      Projectile[] projectiles;
      foreach (i; 0 .. 3) {
        Projectile projectile = new Projectile();
        projectile.load(entityConfigs["balloon"], imageLoader);
        projectile.getSprite().setAnimation("spin");
        projectile.setIsCollidable(false);
        projectiles ~= projectile;
        Entity.EntityList ~= projectile;
      }
      player.setProjectiles(projectiles);
    }

  }

  public void loop() {
    _gravityField.onLoop();
    _collisionField.onLoop();
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.loop();
    }
    _waterLevel--;
    _foreground.setY(_waterLevel);
  }

  public void render() {
    //writeln("onRender");
    // Draw the background below everything else.
    _level.background.render(display);

    // Draw our tiled area.
    Area.AreaControl.render(display,
        Camera.CameraControl.getX(),
        Camera.CameraControl.getY());

    // Draw players and enemies.
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.render(display);
    }

    _foreground.render(display);

    // Update the actual display with all the changes made since the last call.
    display.render();

    // FIXME: This is here to spare my poor CPU.
    SDL_Delay(50);
  }

  public void cleanup() {
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.cleanup();
    }
    Entity.EntityList = new Entity[0];

    Area.AreaControl.cleanup();
  }

}
