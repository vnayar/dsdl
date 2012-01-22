module game;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
import std.stdio;

import constants, surface, event, entity, player;
import area, camera;
import physics.types, physics.collision, physics.gravity;

class Game {
  private bool _running;
  private SDL_Surface* _surfDisplay;
  private SDL_Surface* _surfTileset;

  private Player _player1;
  private Entity _entity2;

  private SimpleGravityField _gravityField;
  private CollisionField _collisionField;

  // Our inner-class defines how we handle events.
  private class GameEventDispatcher : EventDispatcher {
    public:
      override void onExit() {
        this.outer._running = false;
      }

      override void onKeyDown(SDLKey sym, SDLMod mod, Uint16 unicode) {
        switch (sym) {
          case SDLK_ESCAPE: _running = false; break;
          case SDLK_UP:     _player1.jump(); break;
          case SDLK_LEFT:   _player1.setMoveLeft(true); break;
          case SDLK_RIGHT:  _player1.setMoveRight(true); break;
          default:          break;
        }
      }

      override void onKeyUp(SDLKey sym, SDLMod mod, Uint16 unicode) {
        switch (sym) {
          case SDLK_LEFT:  _player1.setMoveLeft(false); break;
          case SDLK_RIGHT: _player1.setMoveRight(false); break;
          default: break;
        }
      }
  }

  // Allow multiple subtyping by creating an alias for this.
  private GameEventDispatcher _eventDispatcher;
  alias _eventDispatcher this;


  public this() {
    _running = true;
    _eventDispatcher = this.new GameEventDispatcher();
    _player1 = new Player();
    _entity2 = new Entity();
    _gravityField = new SimpleGravityField([0.0f, 3.0f]);
    _gravityField.add(_player1);
    _gravityField.add(_entity2);
    _collisionField = new CollisionField();
    _collisionField.add(_player1);
    _collisionField.add(_entity2);
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

    // Load graphics for our Yoshi.
    if (_player1.onLoad("./gfx/yoshi2.png", 64, 64, 8) == false) {
      return false;
    }
    _player1.setLocation([20.0f, 75.0f]);
    _player1.setCollisionBoundary(Rectangle([16, 0], [40, 64]));
    Entity.EntityList ~= _player1;

    // A nemesis?  I don't like the look in his eye.
    if (_entity2.onLoad("./gfx/yoshi2.png", 64, 64, 8) == false) {
      return false;
    }

    _entity2.setLocation([300.0f, 25.0f]);
    _entity2.setCollisionBoundary(Rectangle([16, 0], [40, 64]));
    Entity.EntityList ~= _entity2;

    // Now load the landscape we we play on.
    if (Area.AreaControl.onLoad("./maps/1.area") == false) {
      return false;
    }

    // Set the camera to track our Yoshi.
    Camera.CameraControl.setBounds(Rectangle(
      [0, 0],
      [
        Area.AreaControl.getWidth() - WWIDTH,
        Area.AreaControl.getHeight() - WHEIGHT
      ]
    ));
    Camera.CameraControl.setTarget(_player1);

    return true;
  }

  public void onLoop() {
    _gravityField.onLoop();
    _collisionField.onLoop();
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.onLoop();
    }
  }

  public void onRender() {
    //writeln("onRender");
    Area.AreaControl.onRender(_surfDisplay,
        Camera.CameraControl.getX(),
        Camera.CameraControl.getY());
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.onRender(_surfDisplay);
    }
    SDL_Flip(_surfDisplay);
    SDL_Delay(50);
  }

  public void onCleanup() {
    SDL_FreeSurface(_surfDisplay);
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.onCleanup();
    }
    Entity.EntityList = new Entity[0];

    Area.AreaControl.onCleanup();

    if(SDL_Quit !is null)
      SDL_Quit();
  }

}
