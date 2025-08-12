---
title: Singly Linked List
date: 2025-08-12
draft: false
tags:
  - java
  - DSA
categories:
  - ILT
---
Before you read this if you want a deep dive on Singly LinkedList and DSA with java in general please read the "Chapter 3. Fundamental Data Structures" p.122 by MICHEAL T.GOODRICH
# 1. Node

First let's define a node, so a node it's a data structure that can store an object and point to another node

like this
![Pasted image 20250812133629](/images/Pasted%20image%2020250812133629.png)

we can define it in java like
```java
public class Node<E> {

    private E data;
    private Node<E> next;

    public Node(E data){
        this.data = data;
        this.next = null;
    }

    public E getData() {
        return data;
    }

    public void setData(E data) {
        this.data = data;
    }

    public Node<E> getNext() {
        return next;
    }

    public void setNext(Node<E> next) {
        this.next = next;
    }

    public String toString(){
        return "("+data+") =>(null)";
    }
}

```  

As you can see in the code, the constructor of the Node initializes the next pointer to null, which is what we want.

# 2. Singly LinkedList

so basically a linked list is a chain of nodes whatever the type of this linked list singly,doubly ...
singly linked list 
A singly linked list is a sequence of nodes that every node point to the next node
and it has a head and a tail so we can dentify the first and last Nodes.

![Pasted image 20250812174713](/images/Pasted%20image%2020250812174713.png)

let's imp a simple version of singly linked list in java
```java
public class SinglyLikedList<E>{

  private Node node;
  private Node head;
  private Node tail;
  private E first;

  // so o guess a singly linked list with one node 
  // is one node that the head and the tail in the same time put on it
  public SinglyLikedList(E first) {
    node = new Node(first);
    head = node;
    tail = node;
  } 
  
  public void addFirst(Node<E> n){
    n.setNext(head);
    head = n;
  }

  public void addLast(Node<E> last) {
    tail.setNext(last);
    tail = last;
  }



  public String toString(){
      Node current = head;
      String result = "";
      while (current.getNext() != null) {
        result += "(" + current.getData() +")";
        if (current.getNext() != null) {
          result += "=>";
        }
        current = current.getNext();
      }
      result += "(null)";
      return result;
  }

}

```


let's test our code 

```java
public class Main {
    public static void main(String[] args) {
        System.out.println("==============================");
        //Node node1 = new Node(10);
        //node1.setNext(new Node(33));
        //String s = node1.toString();
        //System.out.println(s);

        System.out.println("========================");
        SinglyLikedList sl = new SinglyLikedList(10);
        sl.addLast(new Node(9));
        System.out.println(sl.toString());
        sl.addLast(new Node(8));
        System.out.println(sl.toString());
        sl.addLast(new Node(7));
        System.out.println(sl.toString());

        sl.addFirst(new Node(33));
        System.out.println(sl.toString());
        sl.addFirst(new Node(44));
        System.out.println(sl.toString());
        sl.addFirst(new Node(77));
        System.out.println(sl.toString());
        System.out.println("==============================");
        
    }
}

```

so we get this beautiful result

```terminal
==============================
========================
(10)=>(null)
(10)=>(9)=>(null)
(10)=>(9)=>(8)=>(null)
(33)=>(10)=>(9)=>(8)=>(null)
(44)=>(33)=>(10)=>(9)=>(8)=>(null)
(77)=>(44)=>(33)=>(10)=>(9)=>(8)=>(null)
==============================
```
