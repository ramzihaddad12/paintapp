import std.socket;
import std.stdio;
import std.algorithm; 
import std.array;
import std.json;
import std.conv;
import std.string;

import core.stdc.string;
import std.stdio;

import deque : Deque;

/**
    This function broadcasts a JSON message to all clients in a client list except for the current client.
    @param msg The JSON message to be broadcasted.
    @param clientList The list of clients to broadcast the message to.
    @param currentClient The client that sent the original message and should be excluded from the broadcast.
*/
void broadcastPacket(JSONValue msg, Socket[] clientList, Socket currentClient) {
    foreach(client; clientList) {
        if(client != currentClient) { 
            client.send(msg.toString);
        }
    }
}


/**
    Runs a server that listens for incoming connections and broadcasts incoming messages to all connected clients.
    @param listener The TcpSocket used to listen for incoming connections.
    @param address The InternetAddress used to bind the listener to a specific address.
*/
void runServer(TcpSocket listener, InternetAddress address) {
    listener.bind(address);

    // Allow 4 connections to be queued up
    listener.listen(4);
    writeln("Awaiting client connections");

    // Set up variables for tracking connected clients
    auto readSet = new SocketSet();
    Socket[] connectedClientsList;

    // Message buffer will be large enough to send/receive Packet.sizeof
    char[100024] buffer;
    bool serverIsRunning = true;
    auto historyCommand = new Deque!(int[]); // [[x,y,r,g,b]]
    auto undoHistory = new Deque!(int[]);
    // Main application loop for the server
    while(serverIsRunning)
    {
        // Clear the readSet
        readSet.reset();

        // Add the listener and all connected clients to the readSet
        readSet.add(listener);
        foreach(client; connectedClientsList)
            readSet.add(client);

        // Wait for incoming data from any socket in the readSet
        if(Socket.select(readSet, null, null))
        {
            // Handle incoming data for each connected client
            foreach(client; connectedClientsList)
            {
                if(readSet.isSet(client))
                {
                    // Receive data from the client
                    auto receivedBytes = client.receive(buffer);

                    if(receivedBytes == 0) { // empty msg
                        // Client disconnected
                        client.close();
                        connectedClientsList = array(connectedClientsList.filter!(c => c != client));
                        writeln("> client removed from connectedClientsList");
                    }
                    else { // process client input here, if recevied data is not empty
                        // add that x,y to server deque
                        // then broadcast this action to other clients to sync their drawings
                        auto msg = parseJSON(cast(string) buffer);
                        string action = msg["action"].str;
                        switch(action){
                            case "sync":
                                int x = cast(int)msg["x"].integer;
                                int y = cast(int)msg["y"].integer;
                                int r = cast(int)msg["r"].integer;
                                int g = cast(int)msg["g"].integer;
                                int b = cast(int)msg["b"].integer;
                                int brushSize = cast(int)msg["brushSize"].integer;
                                int shape = cast(int)msg["shape"].integer;
                                // adding to server side deque
                                historyCommand.push_back([x,y,r,g,b,brushSize,shape]); // adding [x,y] to the back of deque
                                // send this msg to other client that is connected
                                broadcastPacket(msg, connectedClientsList, client); 
                                break;
                            case "undo":
                                if(historyCommand.size() > 0){
                                    auto removedCommand = historyCommand.pop_back();
                                    // writeln("received undo command from client");
                                    undoHistory.push_back(removedCommand);
                                    broadcastPacket(msg, connectedClientsList, client);
                                }
                                break;
                            case "redo":
                                if(undoHistory.size() > 0){
                                    auto lastRemoved = undoHistory.pop_back();
                                    // writeln("received redo command from client");
                                    historyCommand.push_back(lastRemoved);
                                    broadcastPacket(msg, connectedClientsList, client);
                                }
                                break;
                            default: break;
                        }
                        
                    }
                    
                }
            }

            // Check if a new client is attempting to connect
            if(readSet.isSet(listener))
            {
                auto newSocket = listener.accept();
                // Send a welcome message to the new client
                // newSocket.send("Welcome from server, you are now in our connectedClientsList");
                JSONValue welcome;
                welcome["action"] = "welcome";
                welcome["msg"] = "Hello! Welcome from server! You are now connceted to our network!";
                newSocket.send(welcome.toString);
                // Add the new client to the list of connected clients
                connectedClientsList ~= newSocket;
                writeln("> client", connectedClientsList.length, " added to connectedClientsList");
                
                // send history content to that just connected client
                // this way every newly connected client would have previous drawing
                for (int i = 0; i < historyCommand.size(); i++){
                    auto pair = historyCommand.at(i);
					JSONValue historyPacket;
                    historyPacket["action"] = "history";
					historyPacket["x"] = pair[0];
					historyPacket["y"] = pair[1];
                    historyPacket["r"] = pair[2];
                    historyPacket["g"] = pair[3];
                    historyPacket["b"] = pair[4];
                    historyPacket["brushSize"] = pair[5];
                    historyPacket["shape"] = pair[6];
                    newSocket.send(historyPacket.toString);
                }
            }
        }
    }
}