module graphics.imageloader;

import std.algorithm : endsWith;
import std.exception : Exception;
import std.file : dirEntries, SpanMode;
import std.string : toStringz, fromStringz;

import derelict.sdl2.image;
import derelict.sdl2.sdl;

import graphics.image : Image;

debug import std.stdio : writeln;


/**
 * A central loader for image files.
 * This exists to prevent duplicate image loads.
 */
class ImageLoader {
  private SDL_Renderer* renderer;
  private Image[string] imageCache;

  this(SDL_Renderer* renderer) {
    this.renderer = renderer;
  }

  public ~this() {
    unload();
  }

  /**
   * Insert an already existing image into the cache.
   * Mostly useful for unittests.
   */
  public void cache(string fileName, Image image)
    in {
      assert(fileName !in imageCache);
    }
  body {
    imageCache[fileName] = image;
  }

  /**
   * Free memory in the ImageLoader's cache by unloading images.
   */
  public void unload() {
    foreach (image; imageCache) {
      SDL_DestroyTexture(image.texture);
    }
    // Remove all image references.
    imageCache = typeof(imageCache).init;
  }

  /**
   * Finds a file in the filesystem, creates an Image, and also caches the Image
   * in case it is later needed.
   */
  public Image load(string fileName) {
    if (fileName in imageCache) {
      return imageCache[fileName];
    } else {
      SDL_Texture* texture = IMG_LoadTexture(renderer, fileName.toStringz());
      if (texture == null) {
        throw new Exception("Unable to load texture from file " ~ fileName ~ ": "
            ~ SDL_GetError().fromStringz().idup);
      }
      int width, height;
      SDL_QueryTexture(texture, null, null, &width, &height);
      Image image = Image(texture, width, height);
      cache(fileName, image);
      return image;
    }
  }

  /**
   * Initialize the image bank with image files matching a pattern.
   * Params:
   *   dir      = The base search path.
   *   patterns = File name patterns to match.
   */
  public void cacheAll(in string dir, in string[] patterns) {
    // Start at the base search path, and go breadth first.
    foreach (string name; dirEntries(dir, SpanMode.breadth)) {
      bool found = false;
      foreach (pattern; patterns) {
        if (endsWith(name, pattern)) {
          found = true;
          break;
        }
      }
      if (!found) continue;

      debug writeln("Loading image:  ", name);
      load(name);
    }
  }
}

