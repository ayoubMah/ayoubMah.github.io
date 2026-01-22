---
title: Contains Duplicate (LeetCode 217)
date: 2025-12-11T00:42:08+01:00
draft: false
tags: []
categories:
  - ILT
  - DSA
  - java
---
# Contains Duplicate (LeetCode 217)
the link of the problem [here](https://leetcode.com/problems/contains-duplicate/description/)

Given an integer array `nums`, return `true` if any value appears **at least twice** in the array, and return `false` if every element is distinct.

**Example 1:**
**Input:** nums = [1,2,3,1]
**Output:** true
**Explanation:**
The element 1 occurs at the indices 0 and 3.

**Example 2:**
**Input:** nums = [1,2,3,4]
**Output:** false
**Explanation:**
All elements are distinct.
**Example 3:**
**Input:** nums = [1,1,1,3,3,4,3,2,4,2]
**Output:** true

---
First attempt was like this

![Pasted image 20251211004536](/images/Pasted%20image%2020251211004536.png)


```java
class Solution {

	public boolean containsDuplicate(int[] nums) {
		for(int i = 0; i < nums.length - 1; i++) {
			for(int j = i+1; j < nums.length; j++ ) {
				if(nums[i] == nums[j]) return true;
			}
		}
		return false;
	}
}
```
compare the first eml with all others and move to the second elm and compare it with the all others , and so on

so it's a $O(n^2)$ : Quadratic Time
not acceptable :)
why? cuz imagine you have an array with 100,000 elm
with this approach, my code will do 5,000,000,000 comparisons

---
### we should use sets :)
cuz set is a DS that not accept the duplicated elms 



so the acceptable solution looks like
```java
import java.util.HashSet;

class Solution {
public boolean containsDuplicate(int[] nums) {
	HashSet<Integer> myset = new HashSet<>();
		for(int i = 0; i < nums.length; i++) {
			if(myset.contains(nums[i])) return true;
				myset.add(nums[i]);
		}
		return false;
	}
}
```

