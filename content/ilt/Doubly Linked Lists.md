---
title: Doubly Linked Lists
date: 2025-09-08T23:23:40+02:00
draft: false
tags:
  - DSA
  - java
categories:
  - ILT
---
In this blog we'll see how we can implementing a doubly linked list 
if you haven’t seen the Singly Linked List yet it's better to check it [here](https://ayoubmah.github.io/ilt/2025/08/12/singly-linked-list/) first, because the concept is almost the same with just a few changes.

the main difference is in the node itself 
this time a node referenced by the **next** node and the **prev** node
as you can see in this image

![dob](/images/dob.jpeg)

let's implemented in java

```java
public class Node<E> {
    private E elm;
    private Node<E> next;
    private Node<E> prev;

    public Node(Node<E> prev, E elm , Node<E> next){
        this.prev = prev;
        this.elm = elm;
        this.next = next;
    }
    
    public E getElm() {return elm;}
    public void setElm(E elm) {this.elm = elm;}
    public Node<E> getNext() {return next;}
    public void setNext(Node<E> next) {this.next = next;}
    public Node<E> getPrev() {return prev;}
    public void setPrev(Node<E> prev) {this.prev = prev;}
}
```

Now that our `Node` is ready, we can implement the **Doubly Linked List**

```java
public class DoublyLinkedList<E> {

    private Node<E> head ;
    private Node<E> tail ;
    private int size = 0;

    public DoublyLinkedList(){
        head = new Node(null,null,null);
        tail = new Node(head,null,null);
        head.setNext(tail);
    }

    public int size(){
        return size;
    }

    public boolean isEmpty(){
        return size() == 0;
    }

    public E first(){
        if (isEmpty() == true) return null;
        Node<E> firstOne = head.getNext();
        return firstOne.getElm();
    }

    public E last(){
        if (isEmpty() == true) return null;
        Node<E> lastOne = tail.getPrev();
        return lastOne.getElm();
    }
    
    public void addBetween(Node<E> precedore , E elm , Node<E> successor){
        Node<E> newest = new Node<>(precedore, elm , successor);
        precedore.setNext(newest);
        successor.setPrev(newest);

        size++ ;
    }

    public void addFirst(E elm){
        addBetween(head , elm , head.getNext());
    }

    public void addLast(E elm){
        addBetween(tail.getPrev() , elm , tail);
    }

    // remove method => remove the node and return the elm of this node
    public E remove(Node<E> node){
        Node<E> thePrev = node.getPrev();
        Node<E> theNext = node.getNext();
        
        thePrev.setNext(theNext);
        theNext.setPrev(thePrev);

        // this will help the GC
        node.setNext(null);
        node.setPrev(null);
        
        size -- ;
        return node.getElm();
    }

    public E removeFirst(){
        if (isEmpty() == true) return null;
        E result = remove(head.getNext());
        return result;
    }

    public E removeLast(){
        if (isEmpty() == true) return null;
        E result = remove(tail.getPrev());
        return result;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("[");
        Node<E> current = head.getNext();
        while (current != tail) {
            sb.append(current.getElm());
            current = current.getNext();
            if (current != tail) sb.append(", ");
        }
        sb.append("]");
        return sb.toString();
    }
}
```

nice :)
now let's test this

 ```java
 public static void main(String[] args) {
    DoublyLinkedList<Integer> list = new DoublyLinkedList<>();

    System.out.println("Empty: " + list);

    list.addFirst(10);
    list.addFirst(5);
    list.addLast(20);
    list.addLast(25);
    System.out.println("After adding: " + list); // [5, 10, 20, 25]

    System.out.println("First removed: " + list.removeFirst()); // 5
    System.out.println("Last removed: " + list.removeLast());   // 25
    System.out.println("Now: " + list); // [10, 20]

    System.out.println("First element: " + list.first()); // 10
    System.out.println("Last element: " + list.last());   // 20
    System.out.println("Size: " + list.size());           // 2
}
 ```