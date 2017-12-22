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

Usually a variable’s value should not be optional, because this is the safest, bug minimizing situation. 

When a variable's value is made optional, there is the consequence that it must be checked for nil right before the value is accessed. 

You should try to convert an optional value to non-optional one as early during execution as possible, so that further processing of the value can proceed as if it was non-optional.

That being said there are many situations where optional values are warranted - both regular Optionals and Implicitly Unwrapped Optionals.

### What should be optional

The best reason for a value to be typed as an Optional is when its functional domain definition states that its optional. For example, in a structure below, middleName and address2 are optional, because the business rules say so.



```swift
struct Person{
    firstName: String
	middleName: String?
    lastName: String
	address: String
    address2: String?
  	city: String
} 
```

In contrast, all of the other properties are mandatory, so they should never be marked optional. 

Here is another example: 

```swift
public enum Topic {
    case articleUpdate
    case newComment
    case newLike
    case connectionRequest
    case connectionAccepted
    case articleShare
}

struct NotificationModel {
  	let	topic: Topic
    let title: String?
    let createdAt: String?
    let avatarImageUrl: URL?
    let headerImageUrl: URL?
    let articleId: String?
    var read: Bool
    let sectionId: String?
}
```

In the NotificationModel, above, most of the properties are optional. But the domain says otherwise. It stated that all notifications required 4 common fields, only of which was truly optional. The other 3 fields where not optional, but existed as non-optionals dependent on the notification topic. 

```swift
enum NotificationModel {

    struct Common {
        let title: String
        let createdAt: String
        let avatarImageUrl: URL?
        var read: Bool
    }

    case articleUpdate(common: Common, articleId: String, headerImageUrl: URL?)
    case newComment(common: Common, articleId: String, sectionId: String)
    case newLike(common: Common, storyId: String, sectionId: String)
    case connectionRequest(common: Common)
    case connectionAccepted(common: Common)
    case articleShare(common: Common, articleId: String)

    var common: Common {
        get {
            switch self {
            case .articleUpdate(let common, _, _),
                 .newComment(let common, _, _),
                 .newLike(let common, _, _),
                 .connectionRequest(let common),
                 .connectionAccepted(let common),
                 .articleShare(let common, _):
                return common
            }
        }
    }
}
```

Using enums in this way makes the code more understandable because it states what is optional and what variables are of interest in each situation. 





There are very few reasons for a value to be typed as an Implicitly Unwrapped Optional (IUO) - but its fine to use them when necessary - usually as public properties.

You <u>must</u> always check an optional value for nil - either via `if let` or `?` - before you access it and do the approrate action if it is nil. There is no free lunch here. The compiler does not just take care of it. You should never check an IUO value for for nil - it should always be assumed to be non-nil. You must make sure that it gets assigned a value.

### Property Initialization

Normally a property should be initialized at construction. The only exception to this is when you have no
control over the instantiation, because you are building a subclass, as is typical with viewControllers.

### 

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

