module event;

debug import std.stdio : writefln;
debug import std.conv : to;

import derelict.sdl2.sdl;

class EventDispatcher {
public:
  this() {
  }

  ~this() {
  }

  // Main dispatcher function checking even status to pick callback.
  void onEvent(const SDL_Event event) {
    //debug writefln("Received event: %X", event.type);
    switch(event.type) {
    case SDL_KEYDOWN:
      SDL_Keysym keysym = event.key.keysym;
      onKeyDown(keysym.scancode, keysym.sym, keysym.mod, keysym.unicode);
      break;

    case SDL_KEYUP:
      SDL_Keysym keysym = event.key.keysym;
      onKeyUp(keysym.scancode, keysym.sym, keysym.mod, keysym.unicode);
      break;

    case SDL_QUIT:
      onExit();
      break;

    default:
      break;
    }
  }

  void onKeyDown(SDL_Scancode scancode, SDL_Keycode sym, Uint16 mod, Uint32 unicode) {}

  void onKeyUp(SDL_Scancode scancode, SDL_Keycode sym, Uint16 mod, Uint32 unicode) {}

  void onExit() {}
}
