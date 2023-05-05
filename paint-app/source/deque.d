import std.stdio;
import std.math.operations;
import std.exception;
import core.exception : AssertError;

/*
    The following is an interface for a Deque data structure.
    Generally speaking we call these containers.
    
    Observe how this interface is a templated (i.e. Container(T)),
    where 'T' is a placeholder for a data type.
*/
interface Container(T){
    // Element is on the front of collection
    void push_front(T x);
    // Element is on the back of the collection
    void push_back(T x);
    // Element is removed from front and returned
    // assert size > 0 before operation
    T pop_front();
    // Element is removed from back and returned
    // assert size > 0 before operation
    T pop_back();
    // Retrieve reference to element at position at index
    // assert pos is between [0 .. $] and size > 0
    ref T at(size_t pos);
    // Retrieve reference to element at back of position
    // assert size > 0 before operation
    ref T back();
    // Retrieve element at front of position
    // assert size > 0 before operation
    ref T front();
    // Retrieve number of elements currently in container
    size_t size();
}

/*
    A Deque is a double-ended queue in which we can push and
    pop elements.
    
    Note: Remember we could implement Deque as either a class or
          a struct depending on how we want to extend or use it.
          Either is fine for this assignment.
*/
class Deque(T) : Container!(T){
    // Implement here
    private T[] array; // dynamic array

    override void push_front(T x) {
        this.array = [x] ~ array; // adding element to the front of the array
    }

    override void push_back(T x) {
        this.array = array ~ [x]; // adding element to the back of the array
    }

    override T pop_front() {
        assert(size() > 0);
        auto removed = array[0]; // first element
        this.array = array[1..$]; // exclude the first element
        return removed;
    }

    override T pop_back() {
        assert(size()>0);
        auto removed = array[$-1]; // last element
        this.array = array[0..$-1]; // exclude the last element
        return removed;
    }

    override ref T at(size_t pos) {
        assert(size()>0);
        assert(pos >= 0 && pos <= size() - 1);
        return this.array[pos];
    }

    override ref T back() {
        assert(size()>0);
        return this.array[$-1];
    }

    override ref T front() {
        assert(size()>0);
        return this.array[0];
    }

    override size_t size() {
        return array.length;
    }
}