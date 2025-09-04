---
title: Leet-Code-Day001
date: 2025-09-04T23:34:00+02:00
draft: false
tags:
  - java
  - leetcode
  - DSA
categories:
  - ILT
---
you can see the problem here
[Merge Two Sorted Lists](https://leetcode.com/problems/merge-two-sorted-lists/)


The idea is that we have **two sorted singly linked lists**
and we want **a single merged linked list containing all the elements from the two original lists in sorted order** like this:

![WhatsApp Image 2025-09-04 at 11.50.26 PM](/images/WhatsApp%20Image%202025-09-04%20at%2011.50.26%20PM.jpeg)


before looking at the steps of the solution, let's see the implementation of the singly linked list with int value (you can see the generic version here [Singularly Linked List](https://ayoubmah.github.io/ilt/2025/08/12/singly-linked-list/) )

```java
public class ListNode {
    int val;          // the value stored
    ListNode next;    // pointer to the next node

    // constructors
    ListNode() {}                             // default, empty node
    ListNode(int val) { this.val = val; }     // value only
    ListNode(int val, ListNode next) {        // value + next pointer
        this.val = val;
        this.next = next;
    }
}
```

## Example

```java
ListNode node3 = new ListNode(20); // value only node point on null
ListNode node2 = new ListNode(10, node3);
ListNode node1 = new ListNode(5, node2);
```

this is how it looks in memory

![WhatsApp Image 2025-09-04 at 11.51.26 PM](/images/WhatsApp%20Image%202025-09-04%20at%2011.51.26%20PM.jpeg)


## How to traverse it ?

```java
ListNode current = node1;
// as i mentioned before the last node points to null
while (current != null){ 
	System.out.println(current.val);
	current = current.next;
}
```

the output looks like:
5
10 
20

# Solution:

Suppose we have

`list1`: 1 → 2 → 4
and
`list2`: 1 → 2 → 3 → 4 → 5

and we want: 
result: 1 → 1 → 2 → 2 → 3 → 4 → 4 → 5

## Step 1: Fake head and tail
we start by creating a dummy (fake head) and a tail

```java
ListNode dummy = new ListNode(0);  // fake head
ListNode tail = dummy;             // tail points to the last node in merged list
```

## Step 2: iterations

While both list1 and list2 are not `null`:

- Compare their values.
    
- Attach the smaller one to `tail.next`.
    
- Move `tail` forward, and also move the pointer (`list1` or `list2`) you just used.

### Iteration 1:
- compare list1.val = 1 and list2.val = 1
-  1 <= 1 (yes) → attached list1 to tail.next
- move list1 → list1 = list1.next → now we are pointing on 2
- move the tail of the LinkedLinst → tail = tail.next → now we are in 1

### Iteration 2:
- compare list1.val = 2 and list2.val = 1
-  2 <= 1 (no) so do it for list2 → attached list2 to tail.next
- move list2 → list2 = list2.next → now we are pointing on 2
- move the tail of the LinkedLinst → tail = tail.next → now we are in 2
  
### And So On ....

## Step 3: Attach remaining nodes

If one of the lists reaches the end, the remaining nodes of the other list should be attached
we can do it with

```java
tail.next = (list1 != null) ? list1 : list2;
```

## Step 4: return the merged list (skip dummy)

Now we have our merged list like this
0 → 1 → 1 → 2 → 2 → 3 → 4 → 4 → 5

We don’t want to include the dummy, so we return `dummy.next`
# Final Code

```java
public class Solution {
    public ListNode mergeTwoLists(ListNode list1, ListNode list2) {
        // Step 1: create a dummy node to simplify handling the head
        ListNode dummy = new ListNode(0);
        ListNode tail = dummy;

        // Step 2: iterate while both lists have nodes
        while (list1 != null && list2 != null) {
            if (list1.val <= list2.val) {
                tail.next = list1;
                list1 = list1.next;
            } else {
                tail.next = list2;
                list2 = list2.next;
            }
            tail = tail.next;  // move tail forward
        }

        // Step 3: attach the remaining nodes
        tail.next = (list1 != null) ? list1 : list2;

        // Step 4: return the merged list (skip dummy)
        return dummy.next;
    }
}
```


