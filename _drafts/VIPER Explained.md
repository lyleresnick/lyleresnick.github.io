---
layout: post
title: "VIPER Explained"
date: 2017-06-09
---

## Introduction

I've been exploring and using VIPER now for about 2 years. I think it is a really sensible solution for organizing and reducing the size of a view controller. 

Reducing the size of a viewController is a notable goal, but how should it be done? 

One common way to architect an app is to layer the app into an interface layer and a service layer. 

The service layer is responsible for transferring data to and from the internet, local databases, audio and video for the use by the interface layer.  This layer may also perform other non-functional functions such as  caching, syncing, etc. 

The interface layer does something with all this data that is ultimately the purpose of the app.

This two layer architecture is too simple. It does not account for the placement of all of the responsibilities of the so called *interface layer*. A lot of processing happens in this layer. All of this processing ends up in a UIViewController.

In commercial applications, UIViewControllers get large. I've seen 3000 lines in a UIViewController.

VIPER is a micro-architecture - a predefined set of classes that work together to structure a solution. VIPER is an implementation of [Bob Martin's Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html). 

In the next article, I'm going to demonstrate that VIPER can be very simple to implement and its benefits can be realized very quickly.  I'll use the requirement and solution to the Complex UITableView from the last [post]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView-Part-2.html) as the basis of this example. A complete app which demonstrates the refactoring to Clean Architecture can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo). I will be explaining this app in the next post.

## VIPER Explained

The main purpose of the VIPER architecture is to reduce the amount of code in a ViewController class. VIPER does this by allocating almost all of the responsibilities of a typical ViewController into other classes that have predefined responsibilities. You may recall that this echoes the Single Responsibility Principle. 

Another purpose of the VIPER architecture is to decouple dependencies by passing only values between the layers and by demanding that dependencies only go in one direction.

All of this makes it so that it is easier to change the code which is normally contained in a UIViewController. 

To understand VIPER you need to understand a bit about the the clean architecture. 

![Bob Martin's Clean Architecture](https://8thlight.com/blog/assets/posts/2012-08-13-the-clean-architecture/CleanArchitecture-5c6d7ec787d447a81b708b73abba1680.jpg)

As Uncle Bob's diagram shows, a clean system is separated into layers:

- the User Interface is in the outermost layer of the  system 
- the Entities are at the centre of the system and are the results of applying Enterprise Business Rules. 
- the Application Business Rules reside in the layer which surrounds the Entities
- the Data Store and Network, which provide the entities, are in the outer layer
- the Interface Adapters, and in particular the Presenters and Gateways are placed in a layer between the User Interface and Application Business logic layers

In the Clean Architecture, dependencies can only be explicit in one direction - towards the centre. This is shown in the diagram by the dependency arrow pointing inward. A class in a layer closer to the center cannot know the name of a class in a layer closer to the outside. All dependencies going in a direction away from the centre must be implemented as a dependency inversion, which means a protocol must be used. 

The diagram on the right shows the implementation of a dependency inversion where the Presenter implements the Use Case Output, which is produced by the Use Case.

Another requirement of the Clean Architecture is that data must be copied from layer to layer. This means that we can't pass the same data or data structure from one layer to the next: we can only pass copies. In Swift we can simply pass values or structs of values and they will be copied automatically. This prevents changes of implementation in one layer accidentally affecting other layers. When data is copied between the UseCases and the Presenters, it is converted between internal and external formats

In VIPER, 

- the ViewController(**V**) implements the User Interface. 
- the Presenter(**P**) implements 2 parts of the interface adapter layer: data conversion and selection of Use Case or Router  
- the Interactor(**I**), a.k.a the Use Case, implements the application business rules
- the Entities(**E**) are provided by an EntityGateway via Gateway Methods
- the Router(**R**) changes ViewControllers 

This diagram shows the relationships of the VIPER classes.

![Diagram of VIPER classes]({{ site.url }}/assets/VIPER Class Diagram.png)

The ViewController owns a Presenter, which in turn owns an Interactor.  The presenter has a one-way relationship with the Router. The Router owns and has a one-way relationship with child ViewControllers that it creates and manages

The ViewController sends messages to the Presenter, which in turn sends messages to the Interactor or the Router. 

The Interactor uses the EntityGateway to obtain access to EntityManagers.  EntityManagers are responsible for providing access to the Entities.

Since VIPER is an implementation of the Clean Architecture, there a few rules to follow: 

1. Dependencies can only be explicit in one direction.
2. Data must be copied from layer to layer via values or structs of values



Entities are at the centre. In order to access the entities, the EntityGateway must be injected into the Use Case. In order to remove the explicit dependency of the Interactor on the EntityGateway, the gateway is implemented as a protocol.

In order to transmit the results of the Interactor to the ViewController, they must be first sent to the Presenter. The Presenter sends its converted results to the ViewController. Since these messages are moving away from the centre, the target classes are specified as protocols. 

The output of the Interactor is a protocol called the InteractorOutput and the output of the Presenter is a protocol called the PresenterOutput. The ViewController implements the PresenterOutput protocol and the Presenter implements the InteractorOutput protocol.

If you are wondering why I have not mentioned the Use Case Input, shown in the diagram, its because it is not really neccessary, and its annoying, when trying to determine a call path. Even for testing, which would be its most useful use case, the concrete class' methods can be  overridden. Hey, you can certainly use Input protocols if you prefer.



## The Pipeline

You can think of VIPER as a pipeline. Each stage of the pipeline has a well defined job to do. 

Here is a diagram showing the event and information flow between the View Controller and the Entity Gateway

![Diagram of VIPER classes]({{ site.url }}/assets/VIPER UseCase Sequence.png)

The diagram shows that a user or device initiates a sequence by sending an event to a UIViewController. An event can be the result of a user touching a button or a device delivering a location or some other sensor data.

The event is passed to the ViewController as usual.

### The ViewController 

In VIPER, the UIViewController sends <u>every</u> event coming from a UIControl or lifecycle method directly to the Presenter. The ViewController does not process the event in any way, whatsoever. Super simple! 

As you can see in the diagram, the ViewController has another role, which I will cover this later.

### The Presenter

When the Presenter receives an event, it routes the event to either the UseCase or the Router. It converts its input (the ViewControllers output) to a form that can be used directly by the UseCase.   

Examples of input conversion might be from String to Int, formatted String date to Date, an Int from a UIPickerView to an enum - the list goes on. 

TODO: When the event is sent to a Router, it is sent via a RouterRequest. RouterRequests have asynchronous callbacks, unless they are completion callbacks.

As you can see in the diagram, the Presenter has another role, again, I will cover that shortly.

### The UseCase

The UseCase, known in VIPER as the Interactor, has one responsibility: execute the application use case defined for the event. Upon receiving an event, the UseCase may use the EntityGateway to access the system state in the form of Entities, process the Entities with the incoming parameters, and may update the system state via the EntityGateway.

The results of executing the UseCase are passed as output to the UseCaseOutput protocol. 

Even when the Entities do not require processing to create the required output, they are never passed directly to the UseCaseOutput. The results are passed in a form known as the PresentationModel. The Presentation Model contains only the data that will be required for the output display for this UseCase. The data is not converted for output. 

A presentation model can be passed as a struct or as simple scalars - whatever is most convenient. When a struct is used, a good practice is to initialize the struct with the Entity.

The separation of the Entity from the Presentation Model helps ensure that the UseCase is decoupled from the Presenter. This way the Entity can chage without affecting the outer layers of the system.

Note that the UseCase never has to convert data, as that is the job of the Presenter and the EntityGateway.

 The UseCase has no direct dependencies - both the EntityGateway and the PresenterOutput are Protocols and are injected (by the Connector).

### The EntityGateway and EntityManagers

The UseCase uses the EntityGateway to obtain access to EntityManagers. EntityManagers are responsible for providing access to the Entities and for updating them. Entity Managers are also known as Service Layer or Data Access Objects in other layered architectures.

The EntiryManagers are outside the scope of VIPER, but they are a very important aspect of the architecture as a whole. They provide access to and transform the state of the system. They can deliver Entities originating from either local data stores (CoreData or a local file system) and from the Internet. 

The UseCase does not care where the data is coming from or where it is going to - that is the job of the EntityManager.

The Entities delivered by the EntityManagers contain data that has been converted from its external form to a form that can be used directly by the UseCase, not just simple Strings or JSON dictionaries. For example date Strings should be converted to Dates, URL Strings should be converted to URLs, and number Strings should be converted to their specific number type. 

Likewise, data provided to the EntityManagers should not require conversion. it is the job of the EntityManager to convert data from its internal form to its external form.

By providing the data conversion, the EntityManagers effectively decouple the UseCase from the physicallity of the outside storage and location. This makes the UseCase conversion and data validation free. The only code left in the UseCase is code to process the application business rules. 

As I mentioned, the EntityGateway is a protocol. It is defined as a protocol so that the UseCase is decoupled from the source of the data. EntityManagers should also be defined in terms of protocols. This makes it very easy to unit test the UseCase. You can inject substitute implementations of EntiryManagers to control the data .

### The Transformer

The Transformer is not formally part of VIPER, but because of the number of events that a UseCase ends up having to process, I have found it useful to create one Transformer for each event that changes the state of the system.  

Most of the time a Transformer would simply be a method of the UseCase. I convert the method to a method-object. The Transformer usually consists of just a constructor and a method called `transform` . In the UseCase, I initialize the constructor with the required EntityManagers obtained from the EntityGateway and any data required from previously run UseCases. 

I pass the event parameters from UseCase to the `transform` method along with the reference to the Presenter (for output).

You will see that this setup makes is very easy to test the Transformer. It separates the UseCase's responsibilities from one another, making it very easy to understand the code.

There are occasions when a Transformer has more than one method. An example of this is when the use case supports data collection from multiple fields. The events would deliver individual data items to the UseCase, for validation and temporary storage. A final event would then save the changes. 

### The Presenter as UseCaseOutput

When acting as the UseCaseOutput, the Presenter's second responsibility is to convert the data received as PresentationModels to a format called a ViewModel. The data in the ViewModel is formatted so it can be used directly by the ViewController. This usually means Strings, but depending on the requirements of the output controls, it may be a state or a boolean.

If data must be localized, made accessible, or otherwise converted in any way, the process of conversion is done here in the presenter.

 A ViewModel can be implemented as an immutable struct or as a set of scalars, whichever is easier. When implemented as scalars, the values are passed directly as parameters to the PresentationOutput methods. 

If the number of parameters is large, it is better to put the values in a struct and them pass them as a parameter. In this case the conversion can take place in the init of the struct.

In the case of repeating data, the Presenter holds the relating ViewModel structures in an array and delivers them via an indexed method call.

When the number of use cases that a scene supports becomes large, the number of methods on a single output protocol becomes even larger. It becomes really hard to tell at a glance which UseCaseOutput methods are used by what events. For this reason, it is a good practice to create one UseCaseOutput protocol for each event. Your code will be really organized when you place the implementation of each output protocol in its own extension.

### The ViewController as PresenterOutput

Acting as PresenterOutput, the ViewController has one other VIPER responsibility: set the data, which is obtained from the Presenter, into the Views.

The ViewController obtains from the Presenter's data in one of two ways, depending on whether the data is repeating or non-repeating. 

In the case of non-repeating data, the ViewController obtains the ViewModel data directly from the Presenter via a PresenterOutput method, either as individual parameter values or as an immutable struct parameter.

In the case of repeating data, the data is aquired from the Presenter via an indexed accessor method. The methods are used by a UITableView-, UIPicker-, UICollectionView- or other DataSource. The accessor method returns a ViewModel containing the data to be displayed

For the same reasons that I mentioned regarding the UseCaseOutput, it is a good practice to create one PresenterOutput protocol for each event. 

### The Connector

You may be wondering how this stack of classes is created.

A ViewController is normally defined via IB, so we cannot use its init. Usually the ViewController allocates everything it needs, but: 

We do not want the ViewController to know anything about the Interactor. The Interactor must exist before the presenter can  own it. The Presenter must exist before the ViewController can own it.

 The VIPER stack is assembled by a 3rd party class that knows about all of the parts in the stack and how they are connected together. I have called this part the Connector.

The Connector is created and executed by the ViewController by overriding `awakeFromNib()`, which occurs after all outlets are created.

The connector is also useful to set the values of the Presenter into any classes which need to know about them. This usually includes the UITableView-, UIPicker-, UICollectionView- or other DataSources

