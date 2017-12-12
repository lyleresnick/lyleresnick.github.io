---
layout: post
title: "Swift Optionals"
date: 2017-12-04
---

## Introduction

There is a lot of confusion surrounding the proper use of swift optionals. This confusion stems from misunderstandings about what it means to be optional from a class interface point of view.

Remember that there is no such thing as a local IUO, you can only force an optional value to be not optional and then you should be using exceptions if you control the code (null returns from objc excepted here)

Thats it



public

when you look at the signature you know 

they <u>must</u> be set right after initialization, they are independent, they are *injection* sites.

IUOs are effectively not optional - they must be set in order for the class to operate

the class can operate only if set - they will not be checked for null

( a test must fail if you add a new one and all instantiation sites are not augmented )

public optional means the class will operate if its not set - usually some change to behaviour like no output or response as its optional.



private 

private optional means the class is doing something private and the value may be null at any given time and needs to be handled by anyone who makes a change to the class - it should usually mean there is no value



private IUO is problematic 

if its a string, array, set or dict, it should be initialized to "", [] or [:]  respectively and cleared either functionally or by reassignment the null counterparts.

if its a scalar it is questionable why it is an IUO basically a private IUO should not occur

