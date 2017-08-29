---
layout: post
title: "A Crash Course on VIPER"
date: 2017-06-09
---

## Introduction

I've been exploring and using VIPER now for about 2 years. I think it is a really sensible solution for organizing and reducing the size of a massive View Controller. 

Reducing the size of a UIViewController is a notable goal, but how should it be done? 

One common way to architect an app is to layer the app into an interface layer and a service layer. 

The service layer is responsible for transferring data to and from the internet, local databases, audio and video for the use by the interface layer.  This layer may also perform other non-functional functions such as  caching, syncing, etc. 

The interface layer does something with all this data that is ultimately the purpose of the app.

This two layer architecture is too simple. It does not account for the placement of all of the responsibilities of the so called *interface layer*. A lot of processing happens in this layer. All of this processing ends up in a UIViewController.

In commercial applications, UIViewControllers get large. I've seen 2000 lines in a UIViewController.

VIPER is a micro-architecture - a predefined set of classes that work together to structure a solution. VIPER is an implementation of [Bob Martin's Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html). 

In the next article, I'm going to demonstrate that VIPER can be very simple to implement and its benefits can be realized very quickly.  I'll use the requirement and solution to the Complex UITableView from the last [post]({{site.url}}/blog/2017/06/29/Solving-a-Complex-UITableView-Part-2.html) as the basis of this example. A complete app which demonstrates the refactoring to Clean Architecture can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo). I will be explaining this app in the next post.

## VIPER Explained

The main purpose of the VIPER architecture is to reduce the amount of code in a ViewController class. VIPER does this by allocating almost all of the responsibilities of a typical ViewController into other classes that have predefined responsibilities. You may recall that this echoes the Single Responsibility Principle. 

Another purpose of the VIPER architecture is to reduce dependencies. It does this by honouring the layer boundaries, passing only values between the layers and demanding that explicit object dependencies only go in one direction.

All of this makes it easier to change code which is normally contained in a UIViewController. 

To understand VIPER you need to understand a bit about the the Clean Architecture. 

### Uncle Bob's Diagram

![Bob Martin's Clean Architecture](https://8thlight.com/blog/assets/posts/2012-08-13-the-clean-architecture/CleanArchitecture-5c6d7ec787d447a81b708b73abba1680.jpg)

As Uncle Bob's diagram shows, a Clean System is separated into layers:

- the User Interface is in the outermost layer of the  system 
- the Entities are at the centre of the system and are the results of applying Enterprise Business Rules. 
- the Application Business Rules reside in the layer which surrounds the Entities
- the Data Store and Network, which provide the entities, are in the outermost layer
- the Interface Adapters, and in particular the Presenters and Gateways are placed in a layer between the User Interface and Application Business logic layers

### Object Dependencies should point Towards the Centre 

In the Clean Architecture, object dependencies can only be explicit in one direction - towards the centre. This is shown in the diagram by the dependency arrow pointing inward. A class in a layer closer to the center cannot know the name of a class in a layer closer to the outside. All dependencies going in a direction away from the centre must be implemented as a dependency inversion, which means a protocol (in Swift, interface, in Java) must be used. 

All dependencies going in a direction away from the centre must be implemented as a dependency inversion. The inversion is implemented as a protocol and the object has to be injected into the layer. This works great for testing. 

The *Flow of control* diagram, on the right, shows the implementation of a dependency inversion where the Presenter implements the UseCaseOutput, which is produced by the UseCase. This makes it so that the UseCase has no idea who where it is sending its output. The relationship between the UI and the PresenterOutput is analogous.

### Copy Data Values

Another requirement of the Clean Architecture is that data must be copied from layer to layer. This means that we can't pass the same data or data structure from one layer to the next: we can only pass copies. 

In Swift we can pass singular values, `struct`s of values or `enum`s with values as parameters and they will be copied automatically. 

Copying data between layers by passing values, instead of objects prevents implementation changes in one layer accidentally affecting other layers. It also prevents errors due to implementation of concurrency.

### Honour The Layer Boundaries

Clean Architecture also requires that objects in one layer can only communicate to adjacent layers. Objects in non-adjacent layers cannot communicate with one another. 

Objects in a layer must not expose their implementation to any other layer. The implementation must be encapsulated. For example an array or dictionary in a layer must not be exposed by name to another layer. 

This is what I mean by honouring the layer boundaries.

### Viper Classes

In VIPER, 

- the ViewController(**V**) implements the User Interface. 
- the Presenter(**P**) implements 2 parts of the interface adapter layer: data conversion and selection of whether to Route to another scene or perform a UseCase 
- the Interactor(**I**), a.k.a the UseCase, implements the application business rules
- the Entities(**E**) are provided by an EntityGateway via Gateway Methods
- the Router(**R**) changes ViewControllers 

This diagram shows the relationships of the VIPER classes.

![Diagram of VIPER classes]({{ site.url }}/assets/VIPER Class Diagram.png)

The ViewController owns a Presenter, which in turn owns an Interactor.  The presenter has a one-way relationship with the Router. The Router owns and has a one-way relationship with child ViewControllers that it creates and manages

The ViewController sends messages to the Presenter, which in turn sends messages to the UseCase or the Router. 

Each ViewController, Presenter and UseCase are called the VIP stack. In a VIPER architected system one VIP stack is created whenever a new UIViewControler would be created.

The UseCase uses the EntityGateway to obtain access to EntityManagers.  EntityManagers are responsible for providing access to the Entities. The EntityGateway is used by all UseCases to  access  all available EntityManagers.

The Router is a VIP stack that knows about child ViewControllers. 

### Communication Between the Classes

Since VIPER is an implementation of the Clean Architecture, there a few rules to follow: 

1. Dependencies can only be explicit in one direction, towards the centre.
2. Data must be copied from layer to layer via values or structs of values


Entities are at the centre. In order to access the entities, the EntityGateway must be injected into the Use Case. In order to remove the explicit dependency of the UseCase on the EntityGateway, the gateway is implemented as a protocol.

In order to transmit the results of the UseCase to the ViewController, they must be first sent to the Presenter. The Presenter sends its converted results to the ViewController. Since these messages are moving away from the centre, the target classes are specified as protocols. 

The output of the UseCase is a protocol called the UseCaseOutput and the output of the Presenter is a protocol called the PresenterOutput. The ViewController implements the PresenterOutput protocol and the Presenter implements the UseCaseOutput protocol.

Although outside the scope of this blog, I want to mention that the EntityManagers, that the EntityGateway provides, should also be implemented as protocols.

## The VIPER Pipeline

You can think of VIPER as a pipeline. Each stage of the pipeline has a well defined job to do. 

Here is a diagram showing the event flow between the View Controller and the Entity Gateway

![Diagram of VIPER classes]({{ site.url }}/assets/VIPER UseCase Sequence.png)

The diagram shows that a user or device initiates a sequence by sending an event to a UIViewController. An event can be the result of a user touching a button or a device delivering a location or some other sensor data.

The event is passed to the ViewController as usual. 

In the case of repeating touchable areas displayed by UITable and UICollectionViews, a touch event should be sent to the UITable- or UICollectionViewCell, respectively. The index can be accessed from the cell's collection and then sent with the event.

It is useful think of the arrows as if they all pointed to the right as if in a waterfall. This promotes the idea that data flows in one direction only.

### The ViewController 

The ViewController's main role in VIPER is to the configure the View hierarchy. Most of this configuration should performed by Interface Builder.

In VIPER, the UIViewController sends <u>every</u> event coming from a UIControl or lifecycle method directly to the Presenter. The ViewController does not process the event in any way, whatsoever. It simply retrieves associated data, either input as text or selected by index, and sends it with the event to the Presenter. In the case of repeating UIControls contained in a UITableView or UICollectionView, the Cell receives the event and sends it to the Presenter.  Super simple!

As you can see in the diagram, the ViewController has another role: showing the result of the event. I will cover this later in the article.

### The Presenter

When the Presenter receives an event, it routes the event to either the UseCase or the Router. It converts the event's parameters from external format to an internal format that can be used directly by the UseCase or the router.   

Examples of input conversion might be from String to Int, formatted String date to Date, an Int from a UIPickerView to an enum - the list goes on. 

As you can see in the diagram, the Presenter has another role: presenting the result of the event - again, I will cover that shortly.

### The Router

When the event is sent to a Router, it is sent via a RouterRequest. RouterRequests can have callbacks.

I will leave the details of router implementation to a future article. 

### The UseCase

The UseCase has one responsibility: execute the application business requirement. The only code that belongs in a UseCase is that which implements the application business rules. The UseCase should not contain data conversion or external format validation - these are both the domain of the Presenter.

The UseCase typically uses the EntityGateway to access the system state in the form of Entities, processes the Entities against the incoming parameters, and updates the system state via the EntityGateway. It may do this over the course of responding to more than one event. One event may cause the entities to be accessed and output in some order and the next event may select one of the entities and the UseCase will update it in some way.

The results of executing the UseCase are passed as parameters to the UseCaseOutput protocol in a form known as the PresentationModel. 

Entities are never passed directly to the UseCaseOutput. PresentationModels are created from Entities, even when the Entity does not require much processing. The PresentationModel  contains only the data that is required for the output. The UseCase does not convert data for output - it does not know anything about the output format, localization or target view. Output via PresentationModels is kind of like logging without any descriptive text.

Data Conversion is performed by the Presenter and the EntityGateway. This allows the code in the UseCase to be free of conversion and data validation. 

A PresentationModel can be passed as a `struct`, as an `enum` or as simple scalars - whatever is most convenient. When a `struct` is used, a good practice is to initialize it by passing it the Entity.

The separation of the Entities in the UseCase from the PresentationModels used by the Presenter makes sure that the UseCase is decoupled from the Presenter, thus promoting a reduction of shared mutable state. This way the form of Entity can change without affecting the outer layers of the system.

 The UseCase has no direct dependencies - both the EntityGateway and the UseCaseOutput are protocols and are injected (by the Connector).

When the number of use cases that a scene supports becomes large, the number of methods on a single output protocol becomes even larger. It becomes really hard to tell at a glance which UseCaseOutput methods are used by what events. For this reason, it is a good practice to create one UseCaseOutput protocol for each event. Your code will be really organized when you place the implementation of each output protocol in its own extension.

### The EntityGateway and EntityManagers

The UseCase uses the EntityGateway to obtain access to EntityManagers. EntityManagers are responsible for providing access to the Entities and for updating them. Entity Managers are also known as Service Layer or Data Access Objects in other layered architectures.

The EntiryManagers are outside the scope of VIPER, but they are a very important aspect of the architecture as a whole. They provide access to and transform the state of the system. They can deliver Entities originating from either local data stores (CoreData or a local file system) and from the Internet. 

It is a good practice to create an EntityManager for each type of Entity that has its own lifecycle. 

The UseCase does not know where the data is coming from or where it is going to - that is the job of the EntityManager.

An EntityManager receives data originating as JSON, XML, or some other external format from an external store and converts it to either structs or classes. I suggest that Entities should be classes, since you will probably want to mutate them over the course of many events. 

The EntityManager creates the Entity by converting data from an external form to a form that can be used directly by the UseCase. Entities should not contain Strings that are actually numbers and enums, or unconverted JSON dictionaries. For example: date Strings should be converted to Dates, URL Strings should be converted to URLs, number Strings should be converted to their specific number type and exclusive values should be converted to enums. 

After processing, the UseCase sends an Entity with parameters to the EntityManager, where it combines them and sends the changes in an external format to an external store.

Data sent to an EntityManager should not require conversion by the UseCase. It is the job of the EntityManager to convert data from its internal form to its external form.

By providing the data conversion, the EntityManagers effectively decouple the UseCase from the physical form and location of external storage. 

As I mentioned, the EntityGateway is a protocol. It is defined as a protocol so that the UseCase is decoupled from the source of the data. EntityManagers should also be defined in terms of protocols. This makes it very easy to unit test the UseCase. You can inject an alternate implementation of an EntityManager to control the data for a test.

### The Transformer

The Transformer is not formally part of VIPER, but due of the number of events that a typical UseCase has  to process, I find it useful to create one Transformer for each event that changes the state of the system.  

Normally the function of a Transformer would simply be rendered as a method of a UseCase. I convert the method to a *method-object* and then call it from the UseCase event method. The Transformer usually consists of a constructor and a method called `transform` . In the UseCase method, I initialize the constructor with the required EntityManagers obtained from the EntityGateway and any data required from previously run UseCases. 

I pass the event parameters from UseCase to the `transform` method along with the reference to the Presenter (for output).

You will see that this setup makes is very easy to test the Transformer. It separates the UseCase's responsibilities from one another, making it very easy to understand the code.

There are occasions when a UseCase does not use a transformer. An example of this is when the UseCase involves collecting data from multiple fields. The events would deliver individual data items to the UseCase, for validation and temporary storage. Finally, an event would cause the changes to be saved. The UseCase would then call a Transformer with the saved data as parameters. 

### The Presenter as UseCaseOutput

The Presenter's second responsibility is to convert the data received as PresentationModels to a format called a ViewModel. The Presenter implements the UseCaseOutput protocol. 

The role of the Presenter as UseCaseOutput is to format the data received in the PresentationModel into a format that can be used directly by the ViewController. The formatted output is called a ViewModel. This usually means Strings, but depending on the requirements of the output controls, it may be an enum or a boolean.

If data must be localized, made accessible, or otherwise converted in any way, the process of conversion is done by the Presenter.

 A ViewModel can be implemented as an immutable struct or as a set of scalars, whichever is easier. When implemented as scalars, the values are passed directly as parameters to the methods of the PresentationOutput protocol. 

If the number of parameters is large, it is better to put the values in a struct and them pass them as a parameter. In this case the conversion can take place in the init of the struct.

When the input to the Presenter is repetitive, the Presenter holds the ViewModel structures in an array and delivers them via an indexed method call.

When the input to the Presenter is repetitive and heterogeneous, it is a good practice to use *associated-value* `enum`s to hold the data. Although, due to syntax, I find that when an enum contains a large number of associated values, the extraction of values is painful, not to mention that every time a value is added you have to add another '-' . An even better practice is to use enums whose sole associated-value is a struct. This would allow you to use names to extract values, instead of positions.

### The ViewController as PresenterOutput

The ViewController's second responsibility is to assign the data, obtained from the Presenter, into the Views.  The ViewController implements the PresenterOutput protocol.

The ViewController obtains from the Presenter's data in one of two ways, depending on whether the data is repeating or non-repeating. 

In the case of non-repeating data, the ViewController obtains the ViewModel data directly from the Presenter via a PresenterOutput method, either as individual parameter values or as an immutable struct parameter.

In the case of repeating data, the data is acquired from the Presenter via an indexed accessor method. The methods are used by a UITableView-, UIPicker-, UICollectionView- or other DataSource. The accessor method returns a ViewModel containing the data to be displayed

For the same reasons that I mentioned regarding the UseCaseOutput, it is a good practice to create one PresenterOutput protocol for each event. 

### The Connector

You may be wondering how each VIPER stack is created.

A ViewController is normally defined via Interface Builder, so we cannot use its init. Usually the ViewController allocates everything it needs, but: 

We do not want the ViewController to know anything about the Interactor. The Interactor must exist before the presenter can  own it. The Presenter must exist before the ViewController can own it.

 The VIPER stack is assembled by a 3rd party class that knows about all of the classes in the stack and how they are connected together. I call this part a Connector.

A Connector is created and executed by the ViewController by overriding `awakeFromNib()`, which occurs after all outlets are created.

The connector is also useful to set the values of the Presenter into any classes which need to know about them. This usually includes the UITableViewDataSource, UIPicker-, UICollectionView- or other DataSources.

## Summary

I find that the easiest way to determine whether you are implementing VIPER correctly is to use the rules and classes correctly and consistently. 

VIPER is easy to implement if you keep it simple.  

The benefit of VIPER is the organizational lever it provides for the project. Everything has a place. Each team member knows the rules and purposes of the classes in the VIPER stack. This makes everyone happy! 

I think that VIPER is the perfect architecture for large codebases with frequently changing requirements. It is an effective antidote to the Massive ViewController problem.

In my next blog I will demonstrate an implementation of VIPER using the Banking Report from the last [post]({{site.url}}/blog/2017/05/13/Solving-a-Complex-UITableView-Part-2.html).



