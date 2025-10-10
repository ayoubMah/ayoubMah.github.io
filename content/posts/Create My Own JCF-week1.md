---
title: Create My Own JCF-week1
date: 2025-10-11T00:59:35+02:00
draft: false
tags:
  - java
  - DSA
  - project
categories:
  - blog
---
# JCF: Java Collection Framework

_Bfore starting implementing JCF should you know the Iterable<E> interface

- Iterable interface is a builtin interface in java it allow us using "for-each" loop thanks to Iterator method

let's take an example 
if you work with arrays in java and suppose you create an new array

```java
int[] arr = new Interger[]{1,2,3}
```
and you want to make the forEach loop like this ``` for(int n : arr) ``` => this will give you a compiler error

you can create a custom one let's say **MyArray** and implement the Iterable interface 

```java
class MyArray<T> implements Iterable<T> {
    private T[] data;
    private int size;

    public MyArray(T[] data) {
        this.data = data;
        this.size = data.length;
    }

    @Override
    public Iterator<T> iterator() {
        return new Iterator<T>() {
            int index = 0;
            public boolean hasNext() { return index < size; }
            public T next() { return data[index++]; }
        };
    }
}
```
now you can use:
```java
MyArray<Integer> arr = new MyArray<>(new Integer[]{1, 2, 3});
for (int n : arr) {
    System.out.println(n);
}
```
and boom your class works with forEach loop 