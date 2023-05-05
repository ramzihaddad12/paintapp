/// Run with: 'dub'

// Import D standard libraries
module app.main; 

import std.string;
import std.algorithm;
import std.stdio;
import std.conv;

import app.SDLApp;


/**
 * The entry point of the application.
 *
 * This function initializes an instance of `SDLApp` with the IP address and
 * port number entered by the user and starts the main application loop.
 * 
 * @returns void
 */
void main()
{
	write("Enter server IP address of the server: ");
    string ip = strip(readln());
    write("Enter server port number for the server: ");
    ushort port = to!ushort(strip(readln()));
	writeln("Connecting to server IP: ", ip, " On port: ", port);
	writeln();
	auto myApp = new SDLApp(ip, port);
  	myApp.mainApplicationLoop();	
}
