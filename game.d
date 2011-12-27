module game;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
import std.stdio;

import surface;
import animation;
import event;

class Game {
	private bool _running;
	private SDL_Surface* _surfDisplay;
  private SDL_Surface* _surfYoshi;
  private Animation _animYoshi;

	// Our inner-class defines how we handle events.
	private class GameEventDispatcher : EventDispatcher {
		public:
			override void onExit() {
				this.outer._running = false;
			}

			override void onKeyDown(SDLKey sym, SDLMod mod, Uint16 unicode) {
				if(sym == SDLK_ESCAPE)
					_running = false;
			}
	}

	// Allow multiple subtyping by creating an alias for this.
	private GameEventDispatcher _eventDispatcher;
	alias _eventDispatcher this;


	public this() {
		_running = true;
		_eventDispatcher = this.new GameEventDispatcher();
    _animYoshi = new Animation();
	}

	public int onExecute() {
		writeln("onExecute()");
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
		writeln("onInit()");
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
					SDL_SetVideoMode(600, 600, 32, SDL_HWSURFACE | SDL_DOUBLEBUF)) == null)
		{
			throw new Exception("Failed to set video mode: " ~ toDString(SDL_GetError()));
		}

    writeln("Loading image.");
		_surfYoshi = Surface.onLoad("./gfx/yoshi.bmp");
    writeln("Image loaded.");
		Surface.setTransparent(_surfYoshi, 255, 0, 255);

    _animYoshi.setMaxFrames(8);
    //_animYoshi.setOscillate(true);

		return true;
	}

	public void onLoop() {
    _animYoshi.onAnimate();
  }

	public void onRender() {
		writeln("onRender");
    Surface.onDraw(_surfYoshi, cast(short) 0, cast(short)(_animYoshi.getCurrentFrame() * 64),
      cast(short)64, cast(short)64,
      _surfDisplay, cast(short)200, cast(short)150);
		SDL_Flip(_surfDisplay);
		SDL_Delay(50);
	}

	public void onCleanup() {
		SDL_FreeSurface(_surfDisplay);
		SDL_FreeSurface(_surfYoshi);

		if(SDL_Quit !is null)
			SDL_Quit();
	}

}

void main() {
	Game theGame = new Game;
	return theGame.onExecute();
}
