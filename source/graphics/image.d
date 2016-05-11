module graphics.image;

import derelict.sdl2.sdl : SDL_Texture;

struct Image {
  package SDL_Texture* texture;
  int width;
  int height;
}
