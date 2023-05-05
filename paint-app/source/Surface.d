
module app.Surface; 

import app.SDLApp;
import std.typecons; 
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;


public class Surface {
	public SDL_Surface* imgSurface; 
	public SDL_Window* window;
	
	this() { 
		window = SDL_CreateWindow("D SDL Painting",
											SDL_WINDOWPOS_UNDEFINED,
											SDL_WINDOWPOS_UNDEFINED,
											640,
											32 + 480, 
											SDL_WINDOW_SHOWN);
		// space for us to draw on
		imgSurface = SDL_CreateRGBSurface(0,640,32+480,32,0,0,0,0);
		
		// Create palette surface
		// add the rectangles that are all 32x32
		SDL_Rect paletteRect = { 0, 0, 32, 32 };

		SDL_FillRect(imgSurface, &paletteRect, SDL_MapRGB(imgSurface.format, 255, 0, 0)); // Red rectangle
		paletteRect.x += 32;
		SDL_FillRect(imgSurface, &paletteRect, SDL_MapRGB(imgSurface.format, 0, 255, 0)); // Green rectangle
		paletteRect.x += 32;
		SDL_FillRect(imgSurface, &paletteRect, SDL_MapRGB(imgSurface.format, 0, 0, 255)); // Blue rectangle

		SDL_Surface* eraserSurface = SDL_LoadBMP("source/images/eraser.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(eraserSurface, null, imgSurface, &paletteRect); // Eraser icon

		SDL_Surface* undoSurface = SDL_LoadBMP("source/images/undo.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(undoSurface, null, imgSurface, &paletteRect); // Undo icon

		SDL_Surface* redoSurface = SDL_LoadBMP("source/images/redo.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(redoSurface, null, imgSurface, &paletteRect); // Redo icon

		SDL_Surface* plusSurface = SDL_LoadBMP("source/images/plus.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(plusSurface, null, imgSurface, &paletteRect); // Plus icon

		SDL_Surface* minusSurface = SDL_LoadBMP("source/images/minus.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(minusSurface, null, imgSurface, &paletteRect); // Minus icon

		SDL_Surface* squareSurface = SDL_LoadBMP("source/images/square.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(squareSurface, null, imgSurface, &paletteRect); // Minus icon

		SDL_Surface* diamondSurface = SDL_LoadBMP("source/images/diamond.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(diamondSurface, null, imgSurface, &paletteRect); // Minus icon

		SDL_Surface* circleSurface = SDL_LoadBMP("source/images/circle.bmp");
        paletteRect.x += 32;
        SDL_BlitSurface(circleSurface, null, imgSurface, &paletteRect); // Minus icon
		
	}

	~this() { 
		SDL_FreeSurface(imgSurface);
		SDL_DestroyWindow(window);
	}

	void UpdateSurfacePixel(int xPos, int yPos, int[] colors) { 
		
		SDL_LockSurface(imgSurface);

		scope(exit) SDL_UnlockSurface(imgSurface);

		ubyte* pixelArray = cast(ubyte*)imgSurface.pixels;
		pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel+0] = cast(ubyte)colors[2];
		pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel+1] = cast(ubyte)colors[1];
		pixelArray[yPos*imgSurface.pitch + xPos*imgSurface.format.BytesPerPixel+2] = cast(ubyte)colors[0];
	}

	Tuple!(int,int,int) GetPixelColor(int x, int y) {  
		SDL_LockSurface(imgSurface);
		
		scope(exit) SDL_UnlockSurface(imgSurface);

		ubyte* pixelArray = cast(ubyte*)imgSurface.pixels;

		Tuple!(int, int, int) color = tuple(
                        pixelArray[x * imgSurface.pitch + y * imgSurface.format.BytesPerPixel + 0],
                        pixelArray[x * imgSurface.pitch + y * imgSurface.format.BytesPerPixel + 1],
                        pixelArray[x * imgSurface.pitch + y * imgSurface.format.BytesPerPixel + 2]
                );

		return color; 
	}


	void UpdateSurface() {
			SDL_BlitSurface(imgSurface,null,SDL_GetWindowSurface(window),null);
			SDL_UpdateWindowSurface(window);
			SDL_Delay(16);
	}

	SDL_Surface* getSurface(){
		return this.imgSurface;
	}


}
