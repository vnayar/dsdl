module surface;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.string : toStringz, fromStringz;
debug import std.stdio;

/**
 * Wrapper utility for loading SDL surfaces.
 */
class Surface {
  public this() {}
  public static SDL_Surface* loadSurface(string file) {
    SDL_Surface* surfTemp, surfReturn;
    if ((surfTemp = IMG_Load(file.toStringz())) == null) {
      throw new Exception("Could not open file " ~ file ~ ": "
          ~ SDL_GetError().fromStringz().idup);
    }
    // TODO: No longer supported in SDL 2.0, find alternative.
    // surfReturn = SDL_DisplayFormatAlpha(surfTemp);
    SDL_FreeSurface(surfTemp);

    return surfReturn;
  }

  public static SDL_Texture* loadTexture(SDL_Renderer* renderer, string file) {
    SDL_Texture* texture = IMG_LoadTexture(renderer, file.toStringz());
    if (texture == null) {
      throw new Exception("Unable to load texture from file " ~ file ~ ": "
                          ~ SDL_GetError().fromStringz().idup);
    }
    return texture;
  }

  public static void renderTexture(SDL_Renderer* renderer,
      int xOffsetDst, int yOffsetDst, SDL_Texture* srcTexture) {
    int w, h;
    SDL_QueryTexture(srcTexture, null, null, &w, &h);
    renderTexture(renderer, xOffsetDst, yOffsetDst, srcTexture, 0, 0, w, h);
  }

  public static void renderTexture(SDL_Renderer* renderer, int xOffsetDst, int yOffsetDst,
      SDL_Texture* srcTexture,  int xOffsetSrc, int yOffsetSrc, int width, int height)
    in {
      assert(renderer != null);
      assert(srcTexture != null);
    }
  body {
    SDL_Rect srcRect;
    srcRect.x = cast(short) xOffsetSrc;
    srcRect.y = cast(short) yOffsetSrc;
    srcRect.w = cast(short) width;
    srcRect.h = cast(short) height;

    SDL_Rect dstRect;
    dstRect.x = cast(short) xOffsetDst;
    dstRect.y = cast(short) yOffsetDst;
    dstRect.w = cast(short) width;
    dstRect.h = cast(short) height;

    if (SDL_RenderCopy(renderer, srcTexture, &srcRect, &dstRect)) {
      throw new Exception("Error rendering texture: " ~ SDL_GetError().fromStringz().idup);
    }
  }

  // public static bool setTransparent(SDL_Texture* texture, ubyte R, ubyte G, ubyte B)
  //   in {
  //     assert(texture != null);
  //   }
  // body {
  //   //if (surfDest == null) {
  //   //  return false;
  //   //}
  //   //SDL_SetColorKey(surfDest, SDL_SRCCOLORKEY | SDL_RLEACCEL,
  //   //                SDL_MapRGB((*surfDest).format, R, G, B));
  //   return true;
  // }
}
