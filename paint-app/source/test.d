module app.test;  

import app.SDLApp; 
import app.Surface;
import std.typecons;
import bindbc.sdl;
import std.stdio; 
import color; 
import shape; 
import std.json;
import std.socket;

@("test if updateSurfacePixel assigns colors the pixel on provided x and y coordinate")
unittest {
	SDLApp myApp = new SDLApp("0.0.0.0", 50002);
    Surface surface = new Surface;

    surface.UpdateSurfacePixel(0, 0, Color.Red);
    surface.UpdateSurfacePixel(10, 10, Color.Blue);
    surface.UpdateSurfacePixel(15,15, Color.Green);
    surface.UpdateSurface();

    // Verify that pixels are updated correctly
    SDL_Surface* windowSurface = SDL_GetWindowSurface(surface.window);
    ubyte* pixelArray = cast(ubyte*)windowSurface.pixels;

	// color of pixel 0,0
	Tuple!(int, int, int) actualColor0_0 = tuple(
                pixelArray[0],
                pixelArray[1],
                pixelArray[2]
            );

    Tuple!(int, int, int) actualColor10_10 = tuple(
		pixelArray[10 * windowSurface.pitch + 10 * windowSurface.format.BytesPerPixel + 0],
		pixelArray[10 * windowSurface.pitch + 10 * windowSurface.format.BytesPerPixel + 1],
		pixelArray[10 * windowSurface.pitch + 10 * windowSurface.format.BytesPerPixel + 2]
	);


	Tuple!(int, int, int) actualColor15_15 = tuple(
			pixelArray[15 * windowSurface.pitch + 15 * windowSurface.format.BytesPerPixel + 0],
			pixelArray[15 * windowSurface.pitch + 15 * windowSurface.format.BytesPerPixel + 1],
			pixelArray[15 * windowSurface.pitch + 15 * windowSurface.format.BytesPerPixel + 2]
	);

	assert(actualColor0_0 == tuple(0,0,255));
    assert(actualColor10_10 == tuple(255,0,0));
    assert(actualColor15_15 == tuple(0,255,0)); 
}



@("test handle keyboard events function")
unittest {
	SDLApp drawingBoard = new SDLApp("0.0.0.0", 50002);
    Surface surface = new Surface;

    SDL_Event event = SDL_Event();
    event.type = SDL_KEYDOWN;
    event.key.keysym.sym = SDLK_u;

    drawingBoard.handleKeyboardEvents(event);

    // Assert that the undo function was called on the drawing board
    assert(drawingBoard.undoCalled);

    // Call handleKeyboardEvents with the SDLK_r key pressed
    event.key.keysym.sym = SDLK_r;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the redo function was called on the drawing board
    assert(drawingBoard.redoCalled);

    // Call handleKeyboardEvents with the SDLK_e key pressed
    event.key.keysym.sym = SDLK_e;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the brush color was set to black on the drawing board
    assert(drawingBoard.getSelectedPaletteColor() == Color.Black);

    // Call handleKeyboardEvents with the SDLK_p key pressed

    event.key.keysym.sym = SDLK_p;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the brush size was increased on the drawing board
    assert(drawingBoard.getSelectedBrushSize() == 5);


    // Call handleKeyboardEvents with the SDLK_m key pressed
    event.key.keysym.sym = SDLK_m;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the brush size was decreased on the drawing board
    assert(drawingBoard.getSelectedBrushSize() == 4);

    // Call handleKeyboardEvents with the SDLK_s key pressed
    event.key.keysym.sym = SDLK_s;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the shape was set to square on the drawing board
    assert(drawingBoard.getSelectedShape() == Shape.Square);

    // Call handleKeyboardEvents with the SDLK_d key pressed
    event.key.keysym.sym = SDLK_d;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the shape was set to diamond on the drawing board
    assert(drawingBoard.getSelectedShape() == Shape.Diamond);

    // Call handleKeyboardEvents with the SDLK_c key pressed
    event.key.keysym.sym = SDLK_c;
    drawingBoard.handleKeyboardEvents(event);

    // Assert that the shape was set to circle on the drawing board
    assert(drawingBoard.getSelectedShape == Shape.Circle);

}

class MockSocket {
    string[] receivedMessages;

    void send(string message) {
        receivedMessages ~= message;
    }
}

class MockSDL {
    MockSocket socket;

    this(MockSocket socket) {
        this.socket = socket;
    }

    void sendUndoRedoToServer(string action){
        JSONValue message;
        message["action"] = action;
        this.socket.send(message.toString);
    }
}

@("test undo sent to server")
unittest {
    // Create a mock socket for testing
    auto socket = new MockSocket();

    // Initialize a mock instance of the class that contains the function
    auto instance = new MockSDL(socket);

    // Call the function with a sample action
    instance.sendUndoRedoToServer("undo");

    // Check that the message sent to the server is correct
    JSONValue expectedMessage;
    expectedMessage["action"] = "undo";
    auto expectedString = expectedMessage.toString();
    assert(socket.receivedMessages[0] == expectedString);
}

@("test redo sent to server")
unittest {
    // Create a mock socket for testing
    auto socket = new MockSocket();

    // Initialize a mock instance of the class that contains the function
    auto instance = new MockSDL(socket);

    // Call the function with a sample action
    instance.sendUndoRedoToServer("redo");

    // Check that the message sent to the server is correct
    JSONValue expectedMessage;
    expectedMessage["action"] = "redo";
    auto expectedString = expectedMessage.toString();
    assert(socket.receivedMessages[0] == expectedString);
}

@("test brush type feature")
unittest {
    SDLApp drawingBoard = new SDLApp("0.0.0.0", 50002);

    //assert that the default shape for the drawing board is a Square
    assert(drawingBoard.getSelectedShape == Shape.Square);

    //check that the brush size can be assigned to each of the supported shapes
    drawingBoard.handleSetCircleShape();
    assert(drawingBoard.getSelectedShape == Shape.Circle);
    drawingBoard.handleSetDiamondShape();
    assert(drawingBoard.getSelectedShape == Shape.Diamond);
    drawingBoard.handleSetSquareShape();
    assert(drawingBoard.getSelectedShape == Shape.Square);
}

@("test brush size feature")
unittest {
    SDLApp drawingBoard = new SDLApp("0.0.0.0", 50002);
    //assert default brush size is 4
    assert(drawingBoard.getSelectedBrushSize == 4);

    //check brush size decreases work in proper increments
    drawingBoard.handleDecreaseBrushSize();
    assert(drawingBoard.getSelectedBrushSize == 3);
    drawingBoard.handleDecreaseBrushSize();
    assert(drawingBoard.getSelectedBrushSize == 2);
    drawingBoard.handleDecreaseBrushSize();
    assert(drawingBoard.getSelectedBrushSize == 1);

    //check that brush size never goes below 1
    drawingBoard.handleDecreaseBrushSize();
    assert(drawingBoard.getSelectedBrushSize == 1);
    drawingBoard.handleDecreaseBrushSize();
    assert(drawingBoard.getSelectedBrushSize == 1);
    
    //instantiate new drawing board to test increases
    SDLApp drawingBoard2 = new SDLApp("0.0.0.0", 50002);
    assert(drawingBoard2.getSelectedBrushSize == 4);

    //check brush size increases work in proper increments
    drawingBoard2.handleIncreaseBrushSize();
    assert(drawingBoard2.getSelectedBrushSize == 5);
    drawingBoard2.handleIncreaseBrushSize();
    assert(drawingBoard2.getSelectedBrushSize == 6);
    drawingBoard2.handleIncreaseBrushSize();
    assert(drawingBoard2.getSelectedBrushSize == 7);
}

@("test color change feature")
unittest {
    SDLApp drawingBoard = new SDLApp("0.0.0.0", 50002);
    //assert default color is red
    assert(drawingBoard.getSelectedPaletteColor == Color.Red);

    //check color changes according to handleSetColor function
    drawingBoard.handleSetColor(Color.Blue);
    assert(drawingBoard.getSelectedPaletteColor == Color.Blue);
    drawingBoard.handleSetColor(Color.Black);
    assert(drawingBoard.getSelectedPaletteColor == Color.Black);
    drawingBoard.handleSetColor(Color.Green);
    assert(drawingBoard.getSelectedPaletteColor == Color.Green);

    //check that setting the color the same as what's currently selected keeps it the same
    drawingBoard.handleSetColor(Color.Green);
    assert(drawingBoard.getSelectedPaletteColor == Color.Green);

    //check that changing back to the default red color works
    drawingBoard.handleSetColor(Color.Red);
    assert(drawingBoard.getSelectedPaletteColor == Color.Red);

}