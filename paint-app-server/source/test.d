import std.socket;
import std.stdio; 
import std.json; 
import server : broadcastPacket; 
import std.string;

class MockSocket : Socket
{   
    public bool messageSent = false; 
    private char[1024] buffer;
    alias Socket.send send;


    override @trusted long send(scope const(void)[] buf, SocketFlags flags = SocketFlags.NONE)
    {
        messageSent = true; 
        buffer[] = 0; // clear the buffer before storing new data
        buffer[0 .. buf.length] = cast(char[]) buf;
        return buf.length;
    }

    char[] getBuffer() { return buffer; }

}

unittest { 
    auto clients = [cast(Socket) new MockSocket, cast(Socket) new MockSocket, cast(Socket) new MockSocket];
    auto currentClient = clients[1];
    auto msg = JSONValue(1);

    broadcastPacket(msg, clients, currentClient);

    assert((cast(MockSocket)clients[0]).getBuffer()[0] == '1');
    assert((cast(MockSocket)clients[0]).messageSent == true);
   
    assert((cast(MockSocket)clients[1]).messageSent == false);
   
    assert((cast(MockSocket)clients[2]).getBuffer()[0] == '1');
    assert((cast(MockSocket)clients[2]).messageSent == true);
    
}