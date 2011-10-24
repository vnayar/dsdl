module game;

import derelict.sdl.sdl;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
import std.stdio;

import surface;
import event;

class Game {
	private bool _running;
	private SDL_Surface* _surfDisplay;
	private SDL_Surface* _surfTest;

	// Our inner-class defines how we handle events.
	private class GameEventDispatcher : EventDispatcher {
		public:
			override void onExit() {
				this.outer._running = false;
			}

			override void onKeyDown(SDLKey sym, SDLMod mod, Uint16 unicode) {
				if(sym == SDLK_ESCAPE)
					this.outer._running = false;
			}
	}

	// Allow multiple subtyping by creating an alias for this.
	private GameEventDispatcher _eventDispatcher;
	alias _eventDispatcher this;



	public this() {
		writeln("this()");
		_running = true;
		_eventDispatcher = this.new GameEventDispatcher();
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
		DerelictGL.load();
		DerelictGLU.load();

		if (SDL_Init(SDL_INIT_VIDEO) < 0)
		{
			throw new Exception("Couldn't init SDL: " ~ toDString(SDL_GetError()));
		}

		SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

		//if ((_surfDisplay = SDL_SetVideoMode(1024, 768, 0, SDL_OPENGL | SDL_DOUBLEBUF)) == null)
		if ((_surfDisplay =
					SDL_SetVideoMode(640, 480, 32, SDL_HWSURFACE | SDL_DOUBLEBUF)) == null)
		{
			throw new Exception("Failed to set video mode: " ~ toDString(SDL_GetError()));
		}

		if ((_surfTest = Surface.onLoad("golgi.bmp")) == null) {
			throw new Exception("Could not load golgi.bmp");
		}

		writeln("_surfTest has value: ", _surfTest);

		//DerelictGL.loadExtendedVersions(GLVersion.GL20);
		//DerelictGL.loadExtensions();
		return true;
	}

	public void onLoop() {}

	public void onRender() {
		writeln("onRender");
		Surface.onDraw(_surfTest, _surfDisplay, 0, 0);
		Surface.onDraw(_surfTest, 0, 0, 80, 50, _surfDisplay, 160, 100);
		SDL_Flip(_surfDisplay);
		//SDL_GL_SwapBuffers();
		SDL_Delay(1000);
	}

	public void onCleanup() {
		SDL_FreeSurface(_surfTest);
		SDL_FreeSurface(_surfDisplay);
		if(SDL_Quit !is null)
			SDL_Quit();
	}
}

void main() {
	Game theGame = new Game;
	return theGame.onExecute();
}
