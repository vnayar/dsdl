module game;

import std.file : read;
import std.xml;
import std.conv;
import std.string : fromStringz;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
//import derelict.opengl3.glu;

import constants, surface, event, entityconfig, entity, player, projectile;
import area, camera, background, foreground, level;
import physics.types, physics.collision, physics.gravity;
import resource.image;

debug import std.stdio : writeln, writefln;

alias Scancode = int;

class Game {
  private bool _running;

  private SDL_Window* _sdlWindow;
  private SDL_Renderer* _sdlRenderer;
  private SDL_Texture* _sdlTexture;

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
        parser.onEndTag["shootProjectile"] = (in Element e) {
          _scanCodeDownHandlers[to!int(e.text())] = delegate() {
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
  }

  public int execute() {
    //writeln("onExecute()");
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

  public bool init() {
    //writeln("onInit()");
    initSDL();

    initImageBank();

    loadPlayersFromXmlFile("./config/players.xml");

    _eventDispatcher.onLoad("./config/controls.xml");

    debug writeln("Players: ", _players);
    // Load our background image.
    //_background.onLoad("./gfx/Natural_Dam,_Ozark_National_Forest,_Arkansas.jpg");

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

    _waterLevel = Area.AreaControl.getHeight();
    _foreground.load("./maps/Water.tmx");
    _foreground.setFollowCameraX(true);
    _foreground.setY(_waterLevel);

    return true;
  }

  private void initSDL() {
    DerelictSDL2.load();
    DerelictSDL2Image.load();
    DerelictGL3.load();
    //DerelictGLU.load();

    if (SDL_Init(SDL_INIT_VIDEO) < 0)
    {
      throw new Exception("Couldn't init SDL: " ~ SDL_GetError().fromStringz().idup);
    }

    SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    _sdlWindow = SDL_CreateWindow("DSDL Game",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        WWIDTH,
        WHEIGHT,
        /* SDL_WINDOW_FULLSCREEN | */ SDL_WINDOW_INPUT_FOCUS);
    if (_sdlWindow == null) {
      throw new Exception("Failed to create window: " ~ SDL_GetError().fromStringz().idup);
    }

    _sdlRenderer = SDL_CreateRenderer(_sdlWindow, -1, 0);
    if (_sdlRenderer == null) {
      throw new Exception("Failed to get create renderer: " ~ SDL_GetError().fromStringz().idup);
    }

    //_sdlTexture = SDL_GetWindowSurface(_sdlWindow);
    //_sdlTexture = SDL_CreateTexture(_sdlRenderer,
    //    SDL_PIXELFORMAT_ARGB8888,
    //    SDL_TEXTUREACCESS_STATIC,
    //    WWIDTH, WHEIGHT);
    //if (_sdlTexture == null) {
    //     //SDL_SetVideoMode(WWIDTH, WHEIGHT, 32, SDL_HWSURFACE | SDL_DOUBLEBUF)) == null) {
    //  throw new Exception("Failed to get window surface: " ~ SDL_GetError().fromStringz().idup);
    //}
  }

  private void initImageBank() {
	ImageBank.load(_sdlRenderer, "./gfx", [".png", ".jpg"]);
	ImageBank.load(_sdlRenderer, "./tileset", [".png"]);
  }

  private void loadPlayersFromXmlFile(string fileName) {
    string xmlData = cast(string) read(fileName);
    auto xml = new DocumentParser(xmlData);
    EntityConfig[string] entityConfigs;

    xml.onStartTag["entityConfig"] = EntityConfig.getXmlParser(entityConfigs);
    xml.onStartTag["player"] = Player.getXmlParser(_players);
    xml.parse();

    foreach (player; _players) {
      EntityConfig entityConfig = entityConfigs[player.getEntityConfig()];
      player.load(entityConfig);
      player.getSprite().setAnimation("right");
      Entity.EntityList ~= player;

      // Create balloons for the player to throw.
      Projectile[] projectiles;
      foreach (i; 0 .. 3) {
        Projectile projectile = new Projectile();
        projectile.load(entityConfigs["balloon"]);
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
    _level.background.render(_sdlRenderer);

    // Draw our tiled area.
    Area.AreaControl.render(_sdlRenderer,
        Camera.CameraControl.getX(),
        Camera.CameraControl.getY());

    // Draw players and enemies.
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.render(_sdlRenderer);
    }

    _foreground.render(_sdlRenderer);

    // Swap the screen with our surface (prevents flickering while drawing)
    SDL_RenderPresent(_sdlRenderer);

    // FIXME: This is here to spare my poor CPU.
    SDL_Delay(50);
  }

  public void cleanup() {
    SDL_DestroyWindow(_sdlWindow);
    SDL_DestroyRenderer(_sdlRenderer);
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
