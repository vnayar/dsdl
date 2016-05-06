module resource.image;

import std.stdio;
import std.file;
import std.exception;
import std.algorithm;

import derelict.sdl2.sdl;

import surface : Surface;

/**
 * A central loader for image files.
 * This exists to prevent duplicate image loads.
 */
class ImageBank {
  public static SDL_Texture*[string] IMAGES;

  public static ~this() {
	unload();
  }

  public static void unload() {
	foreach (image; IMAGES) {
	  SDL_DestroyTexture(image);
	}
	// Remove all image references.
	IMAGES = (SDL_Texture*[string]).init;
  }

  /**
   * Initialize the image bank with image files matching a pattern.
   * Params:
   *   dir      = The base search path.
   *   patterns = File name patterns to match.
   */
  public static void load(SDL_Renderer* renderer, in string dir, in string[] patterns) {
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

	  writeln("Loading image:  ", name);
	  IMAGES[name] = Surface.loadTexture(renderer, name);
	  enforce(IMAGES[name] != null, "Could not load image " ~ name);
	}
  }
}
