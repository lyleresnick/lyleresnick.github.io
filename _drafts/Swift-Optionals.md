# Swift Optionals

## Introduction
There is a lot of confusion surrounding the proper use of swift optionals. This confusion stems from misunderstandings about:

1. the use of `?` and `!` as either 
	- type modifiers or
	- operators
2. when it is appropriate for a value to be optional and most importantly
3. when it is appropriate to fail and 


## What is safety anyway?

Is safety defined as not allowing an app to fail?

Apple, in its book The Swift Programming Language defines type safety as

> “Type safety helps you catch and fix errors as early as possible in the development process.”


## To Fail or not to Fail

Let's cover point 3 first, as it sets up the context for the rest of this article.
When it comes to App failure, there are clearly two groups of thought. One group believes that code should be written to prevent an app from failing even if the app behaves incorrectly.
The other group believes that an app should
fail if it behaves incorrectly.

The way in which one uses optionals has a lot to with what group you are in.

An simple example of incorrect app behavior is this: a value must be displayed but upon determining that the value does not exist the code either does nothing or
displays an incorrect value. This kind of bad behavior will only serve to confuse the user and ultimately will cause the user to mistrust the app.

## Use of Optional Type Modifiers
The optional type modifiers are used at variable declaration, rather than when the variables are used.

### Use of the `?` Modifier

When `?` is added to the end of a variable type, it means that it's value may be nil.

In practice, this means that the value represented by the variable should be optional due to its definition in the app requirement. A variable's optionality should not due to an artifact, such as a variable in a struct returned from a service layer that should not be optional or an injected property that should be an IUO.

Every Optional variable must be routinely checked for nil via `if let`, `while let`, etc statements or the `?` operator.

Although these statements and the operator can make the app ‘safe’ by preventing it from  crashing, it can lead to many hard to track bugs.
We will come back to this later.

If the value is not optional in the app requirement, the variable's type should not be optional. You must make sure of this, as you will be writing code to check for nil many times over - for absolutely no reason.

You should expect that an Optional value may be assigned to nil after it has already been assigned to a value.

#### Examples of `?`

A simple example is a Person class that contains an age property. This property cannot possibly be nil, since every person has an age.

Another example is a function that requires a non-nil value for a parameter in order to continue processing.
The parameter should not
be made optional just because a caller of the function may want to pass an optional. The caller must check the optional before calling the function with an `if let`.

### Use of the `!` Modifier

When `!` is added to the end of a property's type, it means that the property's value may not be nil when it is accessed, but it will be nil when it is declared.
This is a contract that you are making with the compiler.

In practice, this means that the value that an Implicitly Unwrapped Optional (IUO) variable represents is not optional in its requirement.

An IUO value should not be assigned to nil. If you find you need to do this, use a `?`.

### Examples of the `!` Modifier

The best example of when to use the `!` modifier is an IBOutlet. 
Although it is always preferable to initialize a property via `init`. An IBOutlet represents a typical situation where, for some reason, a property cannot be initialized directly by `init`. 

In the case of IBOutlets, init is called in a standard manner by IB and IB passes a parameter to `init`  which contains the information required to complete the injections of the views.

Properties like these are never intended to be
optional. They are intended to be initialized either by some external entity or by the class itself when further information comes along.

All IUO must be initialized to non-nil before they are used. This is precisely what the `!` modifier means. If the property is not private, the modifier is a contract with the instantiator of the class.
 
If this contract is not met, it is entirely correct that the runtime system should abort the app. This is the correct action to take because, if the property is not initialized, the class is not being used correctly and the code must be fixed. 

It is not OK to check if the property is not nil and then take no action if it is nil. This is a bug, plain and simple. 
Running the app under this condition should produce a crash at the position where the invalid access occurred, so the problem can be easily identified and solved.

Just as a non-private `?` modifier specifies that  it's ok not to set a value, `!` specifies that it's not ok to leave a value unset.

Most private `!` modifiers are usually a code smell. We will look at this later.

If a private resource is expensive to create, use a lazy assignment.

## Use of Optional Type Operators

The optional type operators are used at variable access, rather than at declaration.

### Use of the `?`  (nil-coalescing) Operator

The ? operator allows a property of an optional type to be accessed regardless of whether the object is nil or not. The operator will return nil, if the value of the property is nil, otherwise it will return the value of the property. In either case the type of the returned value will be optional.

If you need to use ? operator more than once in a code block, use an unwrap statement for clarity instead.

### Use of the `!` Operator

The force unwrap operator is generally used to unwrap an optional value that is known to be non-nil.

This the most
misunderstood aspect of optionality.

This operator will cause a runtime error if the value is nil. This is exactly the correct behavior. Tests should be used to prove that the code will not fail.
If the code is not supposed to fail, that is a nil may be expected, a conditional statement should
be used to check for nil and an alternative code
path must be supplied. The alternative should not be a fail, as that is a waste of the readers and dev debuggers  time.



## TODO Failing code
examples

In the following code a client Id is passed to viewController so that the view controller can fetch the details of the client.

The fetch(clientId:) method takes a clientId parameter that is a non-nil String. The string must not be nil because by definition a client cannot have a nil id, and therefore it could never be fetched.

The client id is defined outside the viewController, so when it is initialized the client id property will be nil. Some other object must set the value of the clientId before it is used by *viewDidLoad*. 

The Swift language definition states that if a variable cannot be set at initialization, it must be declared either as an optional or an implicitly unwrapped optional. 

Lets look at what happens if we declare it as an optional. 
```
class customerDetailViewController: UIViewController {

	var clientId: String?
	override func viewDidLoad() {
		guard let clientId = clientId  else {return}
		fetch(clientId: clientId) { result  in
			 process(result: result)
		}
		otherFunc()
	}

private func fetch(clientId: String, callback: (ResultType) -> () ) {
     urlsession.get(etc, callback)
}
```
Somehow the optional client id has to be converted to a non-optional one. The example uses an *guard let* to do the job. 
There is a problem with this code. Can you spot it? This code says that its OK to be nil when viewDidLoad is called. It is doubtful that this is acceptable, since it defeats the purpose of the calling the viewcontroller in the first place.

Although the code will run without crashing, it just confuses everyone. 
testers and users won’t understand the behaviour of the app when nothing is displayed by the viewController and developers who have to fix the problem will have to debug the app to understand how to fix it.

By using a guard let with a return, the developer is just passing the problem of a non-initialized variable on to someone else.

What if we replaced the `return` with 
`fatalError(“clientId is not initialized”)`?
Assuming that one tests the presentation of the viewController, this would definitely cause the app to crash. It identifies the problem precisely and the cause would be easy to fix, since XCode will point out the offending line.

Another way to handle this is to convert the optional to an implicitly unwrapped optional and remove the `guard` altogether. When the code is run the the app will crash and XCode will point out the offending line.

At this point it becomes obvious that the clientId should simply be declared as an implicitly unwrapped optional, thus avoiding having to convert it at every usage. 

The clientId was never really optional in the first place.

`maybe your not testing
your code!` 


```
	/*override */func viewDidLoad()

		load(clientId: clientId!)

	}
}
}
```

* domain oriented
	* you just don’t get one for free
	* finish the entity (from core data or network) 
		* just because it’s optional in deserializer doesn’t mean its optional in the domain
		* if you dont finish every one who uses it will have to finish it
	* use of ? vs let 
	* use of !
		* Bad examples of using guard instead of exclamation
		* just bad examples  of guarding


if you change an api interface you need
to retest the app 
if it blows
up you need to fix it
not jut do nothing 