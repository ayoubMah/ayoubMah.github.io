---
title: Collection Interfece
date: 2025-10-14T01:15:28+02:00
draft: false
tags:
  - java
  - DSA
  - basics
categories:
  - blog
---
the collection interface extends Iterable interface from java.lang
we have a method 
**boolean add(E e)** that return true if the collection changed (the elem e added) and false if not
**boolean addAdd(Collection < ? extends E> c)** , that take a collection of type E of subtype of E and return true if the collection changed (all elm added)

So if you have a `Collection<Animal>` and another `Collection<Dog>`,  
you can add the `Dog`s into the `Animal` collection because `Dog` **extends** `Animal`.

**void clear();** // remove add elms of this collection

**boolean contains(Object o);** 

**boolean containsAll(Collection <? > c);**  the ? means that i don't care about the type of the collection I can check if i contains those objects
example:
```java
List<Integer> list = List.of(1, 2, 3, 4);
List<Object> other = List.of(2, 3);

boolean result = list.containsAll(other);
System.out.println(result); // true
```

