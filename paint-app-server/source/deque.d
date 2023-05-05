/**
 * @module app.deque
 * This module provides an implementation of a double-ended queue.
 */

import std.stdio;
import std.math.operations;
import std.exception;
import core.exception : AssertError;

/**
 * The interface for a Deque data structure.
 * Generally speaking we call these containers.
 *
 * Observe how this interface is a templated (i.e. Container(T)),
 * where 'T' is a placeholder for a data type.
 */
interface Container(T){
    /**
     * Adds an element to the front of the container.
     * @param x the element to add to the container.
     */
    void push_front(T x);

    /**
     * Adds an element to the back of the container.
     * @param x the element to add to the container.
     */
    void push_back(T x);

    /**
     * Removes an element from the front of the container and returns it.
     * @return the element that was removed from the front of the container.
     * @throws AssertError if the container is empty.
     */
    T pop_front();

    /**
     * Removes an element from the back of the container and returns it.
     * @return the element that was removed from the back of the container.
     * @throws AssertError if the container is empty.
     */
    T pop_back();

    /**
     * Retrieves a reference to the element at the given position.
     * @param pos the position of the element to retrieve.
     * @return a reference to the element at the given position.
     * @throws AssertError if the container is empty or if the position is out of range.
     */
    ref T at(size_t pos);

    /**
     * Retrieves a reference to the element at the back of the container.
     * @return a reference to the element at the back of the container.
     * @throws AssertError if the container is empty.
     */
    ref T back();

    /**
     * Retrieves a reference to the element at the front of the container.
     * @return a reference to the element at the front of the container.
     * @throws AssertError if the container is empty.
     */
    ref T front();

    /**
     * Retrieves the number of elements currently in the container.
     * @return the number of elements currently in the container.
     */
    size_t size();
}


/**

This is an implementation of the Deque data structure, which is a double-ended queue that allows for

efficient insertion and removal of elements at both ends.

The Deque class implements the Container interface, which defines a set of methods that are common to

all container types. The Deque class is generic, with a type parameter T that specifies the type of elements

stored in the deque.
*/
class Deque(T) : Container!(T) {

    /**

    Private field used to store the elements in the deque as a dynamic array.
    */
    private T[] array;
    /**

    Inserts an element at the front of the deque.
    @param x the element to insert
    */
    override void push_front(T x) {
        this.array = [x] ~ array;
    }
    /**

    Inserts an element at the back of the deque.
    @param x the element to insert
    */
    override void push_back(T x) {
        this.array = array ~ [x];
    }
    /**

    Removes and returns the element at the front of the deque.
    @returns the element at the front of the deque
    @throws AssertError if the deque is empty
    */
    override T pop_front() {
        assert(size() > 0, "Deque is empty");
        auto removed = array[0];
        this.array = array[1..$];
        return removed;
    }
    /**

    Removes and returns the element at the back of the deque.
    @returns the element at the back of the deque
    @throws AssertError if the deque is empty
    */
    override T pop_back() {
        assert(size() > 0, "Deque is empty");
        auto removed = array[$-1];
        this.array = array[0..$-1];
        return removed;
    }
    /**

    Returns a reference to the element at the specified position in the deque.
    @param pos the position of the element to return
    @returns a reference to the element at the specified position
    @throws AssertError if the deque is empty or the position is out of range
    */
    override ref T at(size_t pos) {
        assert(size() > 0, "Deque is empty");
        assert(pos >= 0 && pos <= size() - 1, "Position is out of range");
        return this.array[pos];
    }
    /**

    Returns a reference to the element at the back of the deque.
    @returns a reference to the element at the back of the deque
    @throws AssertError if the deque is empty
    */
    override ref T back() {
        assert(size() > 0, "Deque is empty");
        return this.array[$-1];
    }
    /**

    Returns a reference to the element at the front of the deque.
    @returns a reference to the element at the front of the deque
    @throws AssertError if the deque is empty
    */
    override ref T front() {
        assert(size() > 0, "Deque is empty");
        return this.array[0];
    }
    /**

    Returns the number of elements in the deque.
    @returns the number of elements in the deque
    */
    override size_t size() {
        return array.length;
    }
}