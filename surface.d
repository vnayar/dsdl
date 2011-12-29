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
			SDL_Surface* surfDest, int x, int y) {
		if (surfDest == null || surfSrc == null) {
			return false;
		}
		SDL_Rect destR;
		destR.x = cast(short) x;
		destR.y = cast(short) y;
		auto ret = SDL_BlitSurface(surfSrc, null, surfDest, &destR);

		return true;
	}

	public static bool onDraw(SDL_Surface* surfSrc,
			int xSrc, int ySrc, int width, int height,
			SDL_Surface* surfDest,
			int xDest, int yDest) {
		if (surfDest == null || surfSrc == null) {
			return false;
		}

		SDL_Rect srcR;
		srcR.x = cast(short) xSrc;
		srcR.y = cast(short) ySrc;
		srcR.w = cast(short) width;
		srcR.h = cast(short) height;

		SDL_Rect destR;
		destR.x = cast(short) xDest;
		destR.y = cast(short) yDest;

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
