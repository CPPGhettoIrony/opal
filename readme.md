The raygui header file must be downloaded and put on the base directory in order for it to compile.

Execute "make DEF=-DNVIDIA_DESKTOP" if your desktop x session uses the nvidia graphics card, otherwise it will get stuck after opening the window
otherwise, if you want the raymarcher to run and your desktop isnt rendered with the nvidia card by default, just execute make without it.

to change width and height of the window:
    DEF="-DWIDTH=x -DHEIGHT=y"