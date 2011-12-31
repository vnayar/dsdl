module game;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
import std.stdio;

import constants, surface, animation, event, entity;
import area, map, camera;

class Game {
	private bool _running;
	private SDL_Surface* _surfDisplay;
  private SDL_Surface* _surfTileset;
  //private SDL_Surface* _surfYoshi;
  //private Animation _animYoshi;

  private Entity _entity1;
  private Entity _entity2;
  private Map _map;

	// Our inner-class defines how we handle events.
	private class GameEventDispatcher : EventDispatcher {
		public:
			override void onExit() {
				this.outer._running = false;
			}

			override void onKeyDown(SDLKey sym, SDLMod mod, Uint16 unicode) {
        switch (sym) {
				  case SDLK_ESCAPE: _running = false; break;
          case SDLK_UP:     Camera.CameraControl.onMove( 0,  5); break;
          case SDLK_DOWN:   Camera.CameraControl.onMove( 0, -5); break;
          case SDLK_LEFT:   Camera.CameraControl.onMove( 5,  0); break;
          case SDLK_RIGHT:  Camera.CameraControl.onMove(-5,  0); break;
          default:          break;
        }
      }
	}

	// Allow multiple subtyping by creating an alias for this.
	private GameEventDispatcher _eventDispatcher;
	alias _eventDispatcher this;


	public this() {
		_running = true;
		_eventDispatcher = this.new GameEventDispatcher();
    _entity1 = new Entity();
    _entity2 = new Entity();
    _map = new Map();
    //_animYoshi = new Animation();
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

    //writeln("Loading image.");
		//_surfYoshi = Surface.onLoad("./gfx/yoshi.bmp");
    //writeln("Image loaded.");
		//Surface.setTransparent(_surfYoshi, 255, 0, 255);
    //_animYoshi.setMaxFrames(8);
    //_animYoshi.setOscillate(true);

    if (_entity1.onLoad("./gfx/yoshi.bmp", 64, 64, 8) == false) {
      return false;
    }

    if (_entity2.onLoad("./gfx/yoshi.bmp", 64, 64, 8) == false) {
      return false;
    }

    _entity2.setX(100.0f);
    Entity.EntityList ~= _entity1;
    Entity.EntityList ~= _entity2;

    //if (_map.onLoad("./maps/1.map") == false) {
    //  return false;
    //}
    //_surfTileset = Surface.onLoad("./tileset/1.png");
    //_map.setTileset(_surfTileset);
    if (Area.AreaControl.onLoad("./maps/1.area") == false) {
      return false;
    }

    SDL_EnableKeyRepeat(1, SDL_DEFAULT_REPEAT_INTERVAL / 3);

		return true;
	}

	public void onLoop() {
    //_animYoshi.onAnimate();
    foreach (entity; Entity.EntityList) {
      if (!entity) continue;
      entity.onLoop();
    }
  }

	public void onRender() {
		//writeln("onRender");
    //Surface.onDraw(_surfYoshi, 0, _animYoshi.getCurrentFrame() * 64,
    //  64, 64,
    //  _surfDisplay, 200, 150);
    //_map.onRender(_surfDisplay, 0, 0);
    Area.AreaControl.onRender(_surfDisplay, Camera.CameraControl.getX(),
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
		//SDL_FreeSurface(_surfYoshi);
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

void main() {
	Game theGame = new Game;
	return theGame.onExecute();
}
