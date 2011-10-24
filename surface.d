module surface;

import derelict.sdl.sdl;
import std.stdio;

class Surface {
	public this() {}
	public static SDL_Surface* onLoad(in const (char*) file) {
		SDL_Surface* surfTemp, surfReturn;
		if ((surfTemp = SDL_LoadBMP(file)) == null) {
			return null;
		}
		surfReturn = SDL_DisplayFormat(surfTemp);
		SDL_FreeSurface(surfTemp);

		return surfReturn;
	}

	public static bool onDraw(SDL_Surface* surfSrc,
			SDL_Surface* surfDest, short x, short y) {
		if (surfDest == null || surfSrc == null) {
			return false;
		}
		SDL_Rect destR;
		destR.x = x;
		destR.y = y;
		auto ret = SDL_BlitSurface(surfSrc, null, surfDest, &destR);
		writeln("Blit return value: ", ret);

		return true;
	}

	public static bool onDraw(SDL_Surface* surfSrc,
			short xSrc, short ySrc, short width, short height,
			SDL_Surface* surfDest,
			short xDest, short yDest) {
		if (surfDest == null || surfSrc == null) {
			return false;
		}

		SDL_Rect srcR;
		srcR.x = xSrc;
		srcR.y = ySrc;
		srcR.w = width;
		srcR.h = height;

		SDL_Rect destR;
		destR.x = xDest;
		destR.y = yDest;

		auto ret = SDL_BlitSurface(surfSrc, &srcR, surfDest, &destR);
		writeln("Blit return value: ", ret);

		return true;
	}
}
