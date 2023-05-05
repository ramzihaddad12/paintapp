# Final Project
Features: (clients can use keyboard input or mouse clicks to use these features)
- undo/redo of painting actions
- change brush sizes
- change brush types
- eraser
- color selection
## Building Software

1. Make sure you have sdl installed in your machine before running our software!
2. Download and extract the zip, or `git clone` it to your environment.
3. Within the *paint-app-server* directory of the project repository, run `dub run`.
4. Enter the IP and port information of your system to begin the server.
**This information can be found by running the getIP script located within the *paint-app-server* directory.**
5. In a separate terminal, change to the *paint-app* directory of the project repository and run `dub run`.
6. Enter the same server IP and port information to launch an SDL drawing client application.
7. For each additional client, start a new terminal and run `dub run` within the *paint-app* directory.
