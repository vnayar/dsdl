import derelict.sdl.sdl;
import derelict.opengl.gl;
import derelict.opengl.glu;
import derelict.util.compat;
import std.stdio;

void main()
{
    DerelictSDL.load();
    DerelictGL.load();
    DerelictGLU.load();

    if(SDL_Init(SDL_INIT_VIDEO) < 0)
    {
        throw new Exception("Couldn't init SDL: " ~ toDString(SDL_GetError()));
    }
    scope(exit)
    {
        if(SDL_Quit !is null)
            SDL_Quit();
    }

    SDL_GL_SetAttribute(SDL_GL_BUFFER_SIZE, 32);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 16);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

    if(SDL_SetVideoMode(1024, 768, 0, SDL_OPENGL) == null)
    {
        throw new Exception("Failed to set video mode: " ~ toDString(SDL_GetError()));
    }

    //DerelictGL.loadExtendedVersions(GLVersion.GL20);
    DerelictGL.loadExtensions();

    glClearColor(0.0, 0.0, 1.0, 1.0);

    bool running = true;

    while(running)
    {
        SDL_Event event;
        while(SDL_PollEvent(&event))
        {
            switch(event.type)
            {
                case SDL_KEYDOWN:
                    if(SDLK_ESCAPE == event.key.keysym.sym)
                        running = false;
                    break;
                case SDL_QUIT:
                    running = false;
                    break;
                default:
                    break;
            }
        }
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        SDL_GL_SwapBuffers();
        SDL_Delay(1);
    }
}
