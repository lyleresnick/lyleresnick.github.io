---
layout: post
title: "Swift Optionals"
date: 2017-12-04
---

## Introduction

There is a lot of confusion around the proper use of swift optionals. This confusion stems from misunderstandings about

1. when is it appropriate for a value to be optional,
2. the use of `?` and `!` as either 
   - type modifiers or
   - operators
3. the implications for the  class or struct  interface, and most importantly
4. when is it appropriate to fail



## When is it appropriate for a value to be optional ?

In general, a value should not be optional, because this is the safest, bug minimizing situation. When a value is optional, you open yourself up for bugs. Many decisions must be made regarding how to process an Optional. You should do everything you can to convert an optional to non-optional as early as possible.

There is only one good reason for a value to be typed as an Optional and that is when its functional domain definition states that its optional. For example, in a structure, a String representing a second address line, or a middle name might be optional. When values are required by their domain definition, such as a first name or a credit card number they should never be marked optional.

There are very few reasons for a value to be typed as an Implicitly Unwrapped Optional (IUO) - but its fine to use them when necessary - usually as public properties.

You <u>must</u> always check an optional value for nil - either via `if let` or `?` - before you access it and do the approrate action if it is nil. There is no free lunch here. The compiler does not just take care of it. You should never check an IUO value for for nil - it should always be assumed to be non-nil. You must make sure that it gets assigned a value.



Remember that there is no such thing as a local IUO, you can only force an optional value to be non-optional and then you should be using exceptions if you control the code (null returns from objc excepted here)



 A parameter representing a dependency should be marked as a IUO optional, and should be initialized to a default initializer. 

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



```Swift
print( "\( thing(first: 7))")

func thing(first: Int! = 6) -> Int {
    
    return  first + 6
}
```

