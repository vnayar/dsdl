module surface;

import derelict.sdl.sdl;
import derelict.sdl.image;
import derelict.util.compat;
import std.stdio;

class Surface {
	public this() {}
	public static SDL_Surface* onLoad(in string file) {
		SDL_Surface* surfTemp, surfReturn;
		//if ((surfTemp = SDL_LoadBMP(file.ptr)) == null) {
		if ((surfTemp = IMG_Load(file.ptr)) == null) {
			throw new Exception("Could not open file " ~ file ~ ": "
					~ toDString(SDL_GetError()));
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

		return true;
	}

	public static bool setTransparent(SDL_Surface* surfDest, ubyte R, ubyte G, ubyte B) {
		if (surfDest == null) {
			return false;
		}
		SDL_SetColorKey(surfDest, SDL_SRCCOLORKEY | SDL_RLEACCEL,
				SDL_MapRGB((*surfDest).format, R, G, B));
		return true;
	}
}
