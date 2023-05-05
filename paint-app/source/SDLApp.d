// client is part of this
module app.SDLApp; 

import std.stdio;
import std.string;
import std.socket;
import std.json;
import std.math;
import shape;
import color; 

// Load the SDL2 library
import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import app.Surface;
import deque : Deque;

public class SDLApp { 
	private SDLSupport ret;
	private Surface surface;
    private bool runApplication = true;
    private bool drawing = false;

	// client part
	private string address;
    private ushort port;
    private Socket socket;
    private Deque!(int[]) history;
	private Deque!(int[]) undoHistory;
	private Deque!(SDL_Surface*) surfaceHistory;
	private Deque!(SDL_Surface*) undoSurfaceHistory;
	private Color colors;
	private int brushSize;
	private Shape shape;

	// test related properties
	public bool undoCalled  = false; 
	public bool redoCalled = false; 

	this(string ip, ushort port) {
		version(Windows){
			writeln("Searching for SDL on Windows");
			ret = loadSDL("SDL2.dll");
		}
		version(OSX){
			writeln("Searching for SDL on Mac");
			ret = loadSDL();
		}
		version(linux){ 
			writeln("Searching for SDL on Linux");
			ret = loadSDL();
		}

		// Error if SDL cannot be loaded
		if(ret != sdlSupport){
			writeln("error loading SDL library");
			
			foreach( info; loader.errors){
				writeln(info.error,':', info.message);
			}
		}
		if(ret == SDLSupport.noLibrary){
			writeln("error no library found");    
		}
		if(ret == SDLSupport.badLibrary){
			writeln("Eror badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
		}

		if(SDL_Init(SDL_INIT_EVERYTHING) !=0){
			writeln("SDL_Init: ", fromStringz(SDL_GetError()));
		}

		this.surface = new Surface();

		// non-blocking, no waiting for other to finish
		// In blocking socket mode, a system call event halts the execution until 
		// an appropriate reply has been received. In non-blocking sockets, 
		// it continues to execute even if the system call has been invoked and 
		// deals with its reply appropriately later
		this.address = ip;
		this.port = port;
		this.socket = new TcpSocket(AddressFamily.INET);
		this.socket.blocking(false);
		this.socket.connect(new InternetAddress(this.address,this.port));

		// stores each surface history before user changes anything
		this.history = new Deque!(int[]);
		this.undoHistory = new Deque!(int[]);
		this.surfaceHistory = new Deque!(SDL_Surface*);
		this.undoSurfaceHistory = new Deque!(SDL_Surface*);
		this.colors = Color.Red; // default color is red 
		this.brushSize = 4; // default brushsize is 4
		this.shape = Shape.Square; // default shape is square
	}

	~this() { 
		SDL_Quit();
		this.socket.close();// close the connection
		writeln("Goodbye for now! You are disconnected from our network.");
	}

	void handleDrawClick(int xPos, int yPos, ref Shape shape, ref int brushSize, ref Color colors) {
		auto rectIndex = xPos / 32;
		if (yPos < 0 || yPos >= 32) {
			return;
		}

		switch (rectIndex) {
			case 0: handleSetColor(Color.Red); break; // Red rectangle clicked
			case 1: handleSetColor(Color.Green); break; // Green rectangle clicked
			case 2: handleSetColor(Color.Blue); break; // Blue rectangle clicked
			case 3: handleSetColor(Color.Black); break; // Eraser clicked
			case 4: undo(); sendUndoRedoToServer("undo"); break; // Undo clicked
			case 5: redo(); sendUndoRedoToServer("redo"); break; // Redo clicked
			case 6: handleIncreaseBrushSize(); break;
			case 7: handleDecreaseBrushSize(); break;
			case 8: handleSetSquareShape(); break;
			case 9: handleSetDiamondShape(); break;
			case 10: handleSetCircleShape(); break;
			default: break;
		}
	}	


	/// Print out all possible user keyboard command
	void printUserCommands() { 
		writeln("Press 'U' on keyboard to undo or click on the icon!");
		writeln("Press 'R' on keyboard to redo or click on the icon! ");
		writeln("Press 'E' on keyboard to set current brush to eraser or click on the icon!");
		writeln("Press 'P' on keyboard to increase the brush size or click on the icon!");
		writeln("Press 'M' on keyboard to decrease the brush size or click on the icon!");
		writeln("Press 'S' on keyboard to change the brush type to square or click on the icon!");
		writeln("Press 'D' on keyboard to change the brush type to diamond or click on the icon!");
		writeln("Press 'C' on keyboard to change the brush type to circle or click on the icon!");
	}

	/// Handle mouse events for down, up, and move
	void handleSDLMouseEvents(SDL_Event e) { 
		switch(e.type) {
			case SDL_MOUSEBUTTONDOWN:
				onMouseDown(e);
				break;
			case SDL_MOUSEBUTTONUP:
				onMouseUp();
				break;
			case SDL_MOUSEMOTION:
				onMouseMove(e);
				break;
			default:
				break; 
		}
	}

	/// Handle each of the possible keyboard events
	void handleKeyboardEvents(SDL_Event e) { 
		if(e.type == SDL_KEYDOWN){
			auto keyPressed = e.key.keysym.sym;
			switch(keyPressed){
				case SDLK_u:
					this.handleUndo();
					this.sendUndoRedoToServer("undo");
					break;
				case SDLK_r:
					this.handleRedo();
					this.sendUndoRedoToServer("redo");
					break;
				case SDLK_e:
					this.handleEraser();
					break;
				case SDLK_p:
					this.handleIncreaseBrushSize();
					break;
				case SDLK_m:
					this.handleDecreaseBrushSize();
					break;
				case SDLK_s:
					this.handleSetSquareShape();
					break;
				case SDLK_d:
					this.handleSetDiamondShape();
					break;
				case SDLK_c:
					this.handleSetCircleShape();
					break;
				default: break;
			}
		}
	}

	/// Assign drawing as true on mouse down
	void onMouseDown(SDL_Event e) { 
		drawing=true;
		// retrieve the position
		int xPos = e.button.x;
		int yPos = e.button.y;

		handleDrawClick(xPos, yPos, this.shape, this.brushSize, this.colors);

	}

	/// Assign drawing as false on mouse up
	void onMouseUp() { 
		drawing=false;
	}

	/// If the mouse is down and moving, then the draw function is initiated
	void onMouseMove(SDL_Event e) { 
		// retrieve the position
		if(drawing) {
			int xPos = e.button.x;
			int yPos = e.button.y;
			// added bounds to the drawing area
			if(xPos <= 640 && xPos >= 0 && yPos >= 32 && yPos <= 480+32){
				// keep track of the pixels
				history.push_back([xPos, yPos]);
				// send this msg to server, so other connected client can see your live drawing
				JSONValue serverPayload;
				serverPayload["action"] = "sync";
				serverPayload["x"] = xPos;
				serverPayload["y"] = yPos;
				serverPayload["r"] = this.colors[0];
				serverPayload["g"] = this.colors[1];
				serverPayload["b"] = this.colors[2];
				serverPayload["brushSize"] = this.brushSize;
				// to send shape info over json we would assume it to be certain int value
				// for example we assume square to have the value of 0
				if (this.shape == Shape.Square) { 
					serverPayload["shape"] = 0; 
				}
				
				if (this.shape == Shape.Diamond) {
					serverPayload["shape"] = 1; 
				}
				
				if (this.shape == Shape.Circle) {
					serverPayload["shape"] = 2; 
				}
				
				this.socket.send(serverPayload.toString);
				this.draws(xPos,yPos,this.colors, brushSize, shape);
			}	
		}
	}
	
	/// handle undo action
	void handleUndo() {
		this.undoCalled = true; 
		this.undo();
	}

	/// handle redo action
	void handleRedo() {
		this.redoCalled = true; 
		this.redo();
	}

	/// handle eraser action
	void handleEraser() {
		this.colors = Color.Black;
	}

	/// handle increase brush size action
	void handleIncreaseBrushSize() {
		this.brushSize++;
	}

	/// handle decrease brush size action
	void handleDecreaseBrushSize() {
		if (this.brushSize>1){
			this.brushSize--;
		}
	}

	/// handle change to square brush action
	void handleSetSquareShape() {
		this.shape=Shape.Square;
	}

	/// handle change to diamond brush action
	void handleSetDiamondShape() {
		this.shape=Shape.Diamond;
	}

	/// handle change to circle brush action
	void handleSetCircleShape() {
		this.shape=Shape.Circle;
	}

	/// handle change color action
	void handleSetColor(Color color) {
		this.colors=color; 
	}

	/// main function for handling user input and client-server communication
	void mainApplicationLoop() {

		this.printUserCommands(); 

		while(runApplication){
			SDL_Event e;
			// Handle events
			// Events are pushed into an 'event queue' internally in SDL, and then
			// handled one at a time within this loop for as many events have
			// been pushed into the internal SDL queue. Thus, we poll until there
			// are '0' events or a NULL event is returned.
			while(SDL_PollEvent(&e) !=0){
				if(e.type == SDL_QUIT){
					runApplication= false;
				}
				this.handleSDLMouseEvents(e); 
				this.handleKeyboardEvents(e); 
			}

			// runs forever to listen to server side input
			this.listenForServer();
			this.surface.UpdateSurface(); 
		}	
	}

	/// listens for updates from server
	void listenForServer(){
		char[100024] buffer;
		auto received = this.socket.receive(buffer);
		if(received > 0){ // has content
			// process the server side json
			string m = cast(string)buffer[0..received];
			string process;
			foreach(n;m){
				process ~= n;
				if(n == '}') {
					// writeln(process); // here is the individual json
					auto jsonva = parseJSON(process);
					string action = jsonva["action"].str;
					// checks the action field if its history, then populate client 
					// duque with server side deque data, to get previous drawing
					// get the previous drawing thats stored on server side duque
					switch(action){
						//history and sync share same code block
						case "history": case "sync":
							int x = cast(int)jsonva["x"].integer;
							int y = cast(int)jsonva["y"].integer;
							int r = cast(int)jsonva["r"].integer;
							int g = cast(int)jsonva["g"].integer;
							int b = cast(int)jsonva["b"].integer;
							int size = cast(int)jsonva["brushSize"].integer;
							int jShape = cast(int)jsonva["shape"].integer;

							if(jShape == 0) {
								this.handleSetSquareShape(); 
							}
							else if(jShape == 1) {
								this.handleSetDiamondShape(); 
							}
							else if(jShape == 2) {
								this.handleSetCircleShape(); 
							}

							int[] colors = [r, g, b];
							history.push_back([x,y,r,g,b,size,jShape]);
							this.draws(x,y,colors,size,shape);

							break;
									
						case "welcome":
							string welcome = jsonva["msg"].str;
							writeln(welcome);
							break;
						
						case "undo":
							this.undo();
							break;
						
						case "redo":
							this.redo();
							break;
						default: break;
					}
					process = ""; // clear the process	
				}
			}	
		}
	}

	/// check that the user is drawing within the proper dimensions
	bool checkValid(Shape s, int w, int h, int brushSize){
		switch(s){
			case Shape.Diamond:
				return (abs(w) + abs(h) <= brushSize);
			case Shape.Circle:
				return (w*w + h*h <= brushSize*brushSize);
			case Shape.Square:
				return true;
			default:
				return false;
		}
	}

	/// given x and y position, handles drawing action
	void draws(int x, int y, int[] colors, int brushSize, Shape shape){
		// keep track of the surfaces history, before user draws
		this.trackSurface();
		for(int w=-brushSize; w < brushSize; w++){
			for(int h=-brushSize; h < brushSize; h++){
				// if y < 32, then we are just going to assume that the user is trying to draw
				// on the palette surface which would not be allowed 
				if (y > 32 && checkValid(shape, w, h, brushSize)) {
					this.surface.UpdateSurfacePixel(x+w,y+h, colors);
				}
			}
		}
	}

	/// keeps tracks for surface history before user action, easier for us to undo and redo
	void trackSurface(){
		// create a surface
		SDL_Surface* copy = SDL_CreateRGBSurface(0,640,480+32,32,0,0,0,0);
		// stores the current surface
		auto currentSurface = this.surface.getSurface();
      	SDL_BlitSurface(currentSurface, null, copy, null); 
		// track the surface in our deque
      	surfaceHistory.push_back(copy);
	}

	/// redo surface and sets current surface to the one we just undo and redo data for current client
	void redo(){
		if (undoSurfaceHistory.size() > 0){
			// get the previous surface and set it to the current surface
			auto lastRemoved = undoSurfaceHistory.pop_back();
			surfaceHistory.push_back(lastRemoved);
			this.surface.imgSurface = lastRemoved;
		}
		if (undoHistory.size() > 0){
			auto lastRemoved = undoHistory.pop_back();
			history.push_back(lastRemoved);
		}
	}

	/// undo surface and sets current surface to the previous one and undo data for current client
	void undo(){
		if (surfaceHistory.size() > 0){
			// get the previous surface and set it to the current surface
			auto surfaceRemoved = surfaceHistory.pop_back();
			undoSurfaceHistory.push_back(surfaceRemoved);
			this.surface.imgSurface = surfaceRemoved;
		}
		if (history.size() > 0){
			auto removed = history.pop_back();
			undoHistory.push_back(removed);
		}
	}

	/// sends undo action to connceted client
	void sendUndoRedoToServer(string action){
		JSONValue message;
		message["action"] = action;
		this.socket.send(message.toString);
	}

	/// returns current selected palette color
	Color getSelectedPaletteColor() {
		return colors; 
	}

	/// returns current selected brush size
	int getSelectedBrushSize() {
		return brushSize; 
	}

	/// returns current selected brush shape
	Shape getSelectedShape() {
		return shape; 
	}
}

	
