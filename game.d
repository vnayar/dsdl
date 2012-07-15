module game;

import std.xml;
import std.conv;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;

import constants, surface, event, entityconfig, entity, player;
import area, camera, background, level;
import physics.types, physics.collision, physics.gravity;
import resource.image;

debug import std.stdio;

class Game {
  private bool _running;

  private SDL_Surface* _surfDisplay;
  private SDL_Surface* _surfTileset;

  //private Player _player1;
  private Player[string] _players;

  private SimpleGravityField _gravityField;
  private CollisionField _collisionField;

  // Eventually store all level-specific data here.
  private Level _level;

  // Our inner-class defines how we handle events.
  private class GameEventDispatcher : EventDispatcher {
    private void delegate()[int] _scanCodeDownHandlers;
    private void delegate()[int] _scanCodeUpHandlers;

    public void onLoad(string fileName)
      in {
        debug writeln("_players.length = ", _players.length);
        assert(_players.length > 0, "Call loadPlayersFromXML() before loading controls.");
      }
    body {
      string xmlData = cast(string) std.file.read(fileName);
      auto xml = new DocumentParser(xmlData);
      xml.onStartTag["control"] = (ElementParser parser) {
        string id = parser.tag.attr["id"];
        if (id !in _players)
          throw new Exception("Cannot find player '" ~ id ~ "'.");
        Player player = _players[id];

        parser.onEndTag["quit"] = (in Element e) {
          _scanCodeDownHandlers[to!int(e.text())] = delegate() {
            _running = false;
          };
        };
        parser.onEndTag["jump"] = (in Element e) {
          _scanCodeDownHandlers[to!int(e.text())] = delegate() {
            player.jump();
          };
        };
        parser.onEndTag["moveLeft"] = (in Element e) {
          _scanCodeDownHandlers[to!int(e.text())] = delegate() {
            player.setMoveLeft(true);
          };
          _scanCodeUpHandlers[to!int(e.text())] = delegate() {
            player.setMoveLeft(false);
          };
        };
        parser.onEndTag["moveRight"] = (in Element e) {
          _scanCodeDownHandlers[to!int(e.text())] = delegate() {
            player.setMoveRight(true);
          };
          _scanCodeUpHandlers[to!int(e.text())] = delegate() {
            player.setMoveRight(false);
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

      override void onKeyDown(SDLKey sym, SDLMod mod, Uint16 unicode) {
        if (sym in _scanCodeDownHandlers)
          _scanCodeDownHandlers[sym]();
      }

      override void onKeyUp(SDLKey sym, SDLMod mod, Uint16 unicode) {
        if (sym in _scanCodeUpHandlers)
          _scanCodeUpHandlers[sym]();
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
  }

  public int onExecute() {
    //writeln("onExecute()");
    if (onInit() == false) {
      return -1;
    }

    SDL_Event event;

    while (_running) {
      while (SDL_PollEvent(&event)) {
        this.onEvent(event);
      }
      onLoop();
      onRender();
    }

    onCleanup();

    return 0;
  }

  public bool onInit() {
    //writeln("onInit()");
    initSDL();

    initImageBank();

    loadPlayersFromXmlFile("./config/players.xml");

    _eventDispatcher.onLoad("./config/controls.xml");

    debug writeln("Players: ", _players);
    // Load our background image.
    //_background.onLoad("./gfx/Natural_Dam,_Ozark_National_Forest,_Arkansas.jpg");

    // Load graphics for our Yoshi.
    //if (_player1.onLoad("./gfx/yoshi3.png", 32, 32, 8) == false) {
    //  return false;
    //}
    //_player1.setLocation([20.0f, 20.0f]);
    //_player1.setCollisionBoundary(Rectangle([6, 0], [20, 32]));
    //Entity.EntityList ~= _player1;

    // Now load the landscape we we play on.
    _level.loadFromXmlFile("./levels/level1.xml");

    // Set up our fields.
    foreach (entity; Entity.EntityList) {
      _gravityField.add(entity);
      _collisionField.add(entity);
    }

    // Set bounds for how far the camera may move.
    Rectangle cameraBounds = Rectangle(
      [0, 0],
      [
        Area.AreaControl.getWidth() - WWIDTH,
        Area.AreaControl.getHeight() - WHEIGHT
      ]
    );
    Camera.CameraControl.setBounds(cameraBounds);
    // Let the background parallax with the camera.
    _level.background.setParallaxBounds(cameraBounds);
    
    // Set the camera to track our Yoshi.
    Camera.CameraControl.setTarget(_players["player1"]);


    return true;
  }

  private void initSDL() {
    DerelictSDL.load();
    DerelictSDLImage.load();
    DerelictGL.load();
    DerelictGLU.load();

    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
      throw new Exception("Couldn't init SDL: " ~ toDString(SDL_GetError()));
    }

    SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    if ((_surfDisplay =
          SDL_SetVideoMode(WWIDTH, WHEIGHT, 32, SDL_HWSURFACE | SDL_DOUBLEBUF)) == null)
    {
      throw new Exception("Failed to set video mode: " ~ toDString(SDL_GetError()));
    }
  }

  private void initImageBank() {
	ImageBank.load("./gfx", [".png", ".jpg"]);
	ImageBank.load("./tileset", [".png"]);
  }

  private void loadPlayersFromXmlFile(string fileName) {
    string xmlData = cast(string) std.file.read(fileName);
    auto xml = new DocumentParser(xmlData);
    EntityConfig[string] entityConfigs;

    xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);
    xml.onStartTag["player"] = Player.getXmlParser(_players);
    xml.parse();

    foreach (player; _players) {
      EntityConfig entityConfig = entityConfigs[player.getEntityConfig()];
      player.load(entityConfig);
      Entity.EntityList ~= player;
    }
  }

  public void onLoop() {
    _gravityField.onLoop();
    _collisionField.onLoop();
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.loop();
    }
  }

  public void onRender() {
    //writeln("onRender");
    // Draw the background below everything else.
    _level.background.onRender(_surfDisplay);

    // Draw our tiled area.
    Area.AreaControl.render(_surfDisplay,
        Camera.CameraControl.getX(),
        Camera.CameraControl.getY());

    // Draw players and enemies.
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.render(_surfDisplay);
    }

    // Swap the screen with our surface (prevents flickering while drawing)
    SDL_Flip(_surfDisplay);

    // FIXME: This is here to spare my poor CPU.
    SDL_Delay(50);
  }

  public void onCleanup() {
    SDL_FreeSurface(_surfDisplay);
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.cleanup();
    }
    Entity.EntityList = new Entity[0];

    Area.AreaControl.cleanup();

    if(SDL_Quit !is null)
      SDL_Quit();
  }

}
