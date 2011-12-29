module tictac;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
import std.stdio;

import surface;
import event;

class TicTac {
	private bool _running;
	private int _currentPlayer = 0;
	private SDL_Surface* _surfDisplay;
	private SDL_Surface* _surfGrid;
	private SDL_Surface* _surfX;
	private SDL_Surface* _surfO;

	private enum GridState {NONE, X, O};
	GridState[] _grid;

	// Our inner-class defines how we handle events.
	private class TicTacEventDispatcher : EventDispatcher {
		public:
			override void onExit() {
				this.outer._running = false;
			}

			override void onKeyDown(SDLKey sym, SDLMod mod, Uint16 unicode) {
				if(sym == SDLK_ESCAPE)
					_running = false;
			}

			override void onLButtonDown(int mX, int mY) {
				writeln("LButton: mX=", mX, " mY=", mY);
				int index = mX / 200;
				index += (mY / 200) * 3;

				if (_grid[index] != GridState.NONE) {
					return;
				}

				if (_currentPlayer == 0) {
					setCell(index, GridState.X);
					_currentPlayer = 1;
				} else {
					setCell(index, GridState.O);
					_currentPlayer = 0;
				}
			}
	}

	// Allow multiple subtyping by creating an alias for this.
	private TicTacEventDispatcher _eventDispatcher;
	alias _eventDispatcher this;


	public this() {
		_running = true;
		_eventDispatcher = this.new TicTacEventDispatcher();
		_grid = new GridState[9];
	}

	public int onExecute() {
		writeln("onExecute()");
		if (onInit() == false) {
			return -1;
		}

		SDL_Event event;
    int eventStatus;

		while (_running) {
      SDL_WaitEvent(&event);
      do {
				this.onEvent(event);
      } while (SDL_PollEvent(&event)); 
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

		//_surfGrid = Surface.onLoad("./gfx/golgi.bmp");
		_surfGrid = Surface.onLoad("./gfx/grid.png");
		_surfX = Surface.onLoad("./gfx/x.png");
		_surfO = Surface.onLoad("./gfx/o.png");

		Surface.setTransparent(_surfX, 255, 0, 255);
		Surface.setTransparent(_surfO, 255, 0, 255);

		reset();

		return true;
	}

	public void onLoop() {}

	public void onRender() {
		writeln("onRender");
		Surface.onDraw(_surfGrid, _surfDisplay, 0, 0);
		for (int i = 0; i < _grid.length; i++) {
			int x = (i % 3) * 200;
			int y = (i / 3) * 200;
			if (_grid[i] == GridState.X) {
				Surface.onDraw(_surfX, _surfDisplay, x, y);
			} else if (_grid[i] == GridState.O) {
				Surface.onDraw(_surfO, _surfDisplay, x, y);
			}
		}
					
		SDL_Flip(_surfDisplay);
	}

	public void onCleanup() {
		SDL_FreeSurface(_surfDisplay);
		SDL_FreeSurface(_surfGrid);
		SDL_FreeSurface(_surfX);
		SDL_FreeSurface(_surfO);

		if(SDL_Quit !is null)
			SDL_Quit();
	}

	private void reset() {
		foreach (cell; _grid) {
			cell = GridState.NONE;
		}
	}

	private void setCell(int index, GridState state) {
		if (index < 0 || index > _grid.length) return;
		_grid[index] = state;
	}
}

void main() {
	TicTac ticTac = new TicTac;
	return ticTac.onExecute();
}
