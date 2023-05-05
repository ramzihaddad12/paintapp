/**
 * This is the main module for the server application.
 */

import std.socket;
import std.stdio;
import std.conv;
import std.string;
import core.stdc.string;
import server : runServer; 

/**
 * This is the main entry point for the server application.
 */
void main(){
    write("Enter server IP address: ");
    string ip = strip(readln());
    
    write("Enter server port number: ");
    ushort port = to!ushort(strip(readln()));
    
    writeln("Starting server...");
    writeln("Running on IP addess: ", ip, " Port number: ", port);
    
    // Create and bind a socket for the server
    // auto listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    auto listener = new TcpSocket(AddressFamily.INET);
    
    scope(exit) listener.close();
    
    auto address = new InternetAddress(ip, port);
    
    runServer(listener, address); 
}