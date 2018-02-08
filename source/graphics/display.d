module graphics.display;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import std.string : toStringz, fromStringz;
import std.format : format;

import graphics.imageloader : ImageLoader;
import graphics.image : Image;

/**
 * Contains operations related to the display of graphical primitives onto a display device.
 */
public class Display {
  public immutable int width;
  public immutable int height;

  package SDL_Window* window;
  package SDL_Renderer* renderer;

  private ImageLoader imageLoader;

  /**
   * Params:
   *   width = The width, in pixels, of the display to create.
   *   height = The height, in pixels, of the display to create.
   */
  public this(int width, int height) {
    this.width = width;
    this.height = height;
  }

  public ~this() {
    cleanup();
  }

  public void init() {
    initSdl();
    initImageLoader();
  }

  private void initSdl() {
    DerelictSDL2.load(SharedLibVersion(2, 0, 1));
    DerelictSDL2Image.load();

    // TODO: Delete this section? BEGIN
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
      throw new Exception("Couldn't init SDL: " ~ SDL_GetError().fromStringz().idup);
    }
    SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    window = SDL_CreateWindow("DSDL Game",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        width,
        height,
        /* SDL_WINDOW_FULLSCREEN | */ SDL_WINDOW_INPUT_FOCUS);
    if (window == null) {
      throw new Exception("Failed to create window: " ~ SDL_GetError().fromStringz().idup);
    }

    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    if (renderer == null) {
      throw new Exception("Failed to get create renderer: " ~ SDL_GetError().fromStringz().idup);
    }
  }

  private void initImageLoader() {
    imageLoader = new ImageLoader(renderer);
    imageLoader.cacheAll("./gfx", [".png", ".jpg"]);
	imageLoader.cacheAll("./tileset", [".png"]);
  }

  public ImageLoader getImageLoader() {
    return imageLoader;
  }

  /**
   * Render an image onto the display.
   *
   * Params:
   *   x = The horizontal offset to display the image.
   *   y = The vertical offset to display the image.
   *   srcImage = The image to be rendered on the display.
   */
  public void renderImage(int x, int y, Image srcImage) {
    renderImage(x, y, srcImage, 0, 0, srcImage.width, srcImage.height);
  }

  /**
   * Render a section of an image onto the display.
   *
   * Params:
   *   x = The horizontal offset to display the image.
   *   y = The vertical offset to display the image.
   *   srcImage = The image to be rendered on the display.
   *   srcX = The horizontal offset at which the image section begins.
   *   srcY = The vertical offset at which the image section begins.
   *   srcWidth = The width of the image section to display.
   *   srcHeight = The height of the image section to display.
   */
  public void renderImage(int x, int y,
      Image srcImage, int srcX, int srcY, int srcWidth, int srcHeight)
    in {
      assert(renderer != null);
      assert(srcImage.texture != null);
      assert(srcX >= 0 && srcX + srcWidth <= srcImage.width,
          format("srcX %d and srcWidth %d are out of src bounds %d!",
              srcX, srcWidth, srcImage.width));
      assert(x >= 0 && x + srcWidth <= width,
          format("x %d and srcWidth %d are out of display bounds %d!",
              x, srcWidth, width));
      assert(srcY >= 0 && srcY + srcHeight <= srcImage.height,
          format("Display srcHeight out of src bounds!",
              srcY, srcWidth, srcImage.height));
      assert(y >= 0 && y + srcHeight <= height,
          format("y %d and srcHeight %d are out of display bounds %d!",
              y, srcHeight, height));

    }
  body {
    SDL_Rect srcRect = SDL_Rect(srcX, srcY, srcWidth, srcHeight);
    SDL_Rect dstRect = SDL_Rect(x, y, srcWidth, srcHeight);

    if (SDL_RenderCopy(renderer, srcImage.texture, &srcRect, &dstRect)) {
      throw new Exception("Error rendering texture: " ~ SDL_GetError().fromStringz().idup);
    }
  }

  public void render() {
    // Swap the screen with our surface (prevents flickering while drawing)
    SDL_RenderPresent(renderer);
  }

  public void cleanup() {
    SDL_DestroyWindow(window);
    SDL_DestroyRenderer(renderer);

    if(SDL_Quit !is null)
      SDL_Quit();
  }
}
