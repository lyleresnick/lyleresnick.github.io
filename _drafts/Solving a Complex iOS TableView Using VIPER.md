---
layout: post
title: "Solving a Complex iOS TableView Using VIPER"
date: 2017-06-09
---

## Introduction

VIPER is a micro-architecture - a set of classes that work together to structure a solution.  

VIPER is an implementation of [Bob Martin's Clean Architecture](). I'm going to demonstrate that viper can be very simple to implement and its benefits can be realized very quickly.   

I'm going to use the requirement and solution to the Complex TableView from the last [post]() as the basis of this example.

## VIPER Explained

The purpose of the VIPER pattern is to reduce the amount of code in the ViewController(**V**) class by distributing it into other classes that have specific responsibilities.

**TODO: DIAGRAM:** of the clean architecture

The diagram shows that

- the user is outside the system
- the User Interface layer is the outermost layer of the  system 
- the entities are pure data structures at the centre of the system
- business logic layer surrounds the entities
- the data store which provides the entities is outside the system
- the presentation conversion layer is placed in the middle between the user interface and business logic  layers

In VIPER, 

- the ViewController(**V**) represents the user interface. 


- the Presenter(**P**) represents the presentation conversion layer
- the Interactor(**I**), a.k.a the UseCase, represents the business logic layer
- the Router(**R**), which has not been explained and 
- the EntityGateway(**E**) provides access to Entities and managers to operate on them

Here is the relationship of the VIPER classes in a diagram

**TODO: DIAGRAM:** of VIPER classes.

The ViewController owns a Presenter, which in turn owns an Interactor.  The ViewController sends messages to the Presenter, which in turn sends messages to the Interactor. 

The Interactor uses the EntityGateway to obtain access to EntityManagers.  EntityManagers are responsible for providing access to the Entities.

**TODO: FIXME:** The Clean Architecture mandates that dependencies can only be explicit in one direction - towards the centre. All other dependencies going away from the centre must be implemented as a dependency inversion, which means a protocol must be used.

Since VIPER is an implementation of the Clean Architecture, there a few rules to follow: 

1. dependencies can only be explicit in one direction - towards the centre. This means that messages flowing out of the centre must be sent to an interface (a.k.a. a Swift protocol)
2. data must be copied from layer to layer. This means that we can't pass a Swift class from one layer to the next



**TODO: FIXME:** Entities are at the centre. In order to access the entities, the EntityGateway is be injected into the Interactor. In order to remove the explicit dependency of the Interactor on the EntityGateway, the gateway is implemented as a protocol.

In order to transmit the results of the Interactor to the ViewController, they must be first sent to the Presenter, which in turn sends its results to the ViewController. Since these messages are moving away from the centre, the target classes are implemented as protocols. 

The output of the Interactor is a protocol called the InteractorOutput and the output of the Presenter is a protocol called the PresenterOutput. The ViewController implements the PresenterOutput protocol and the Presenter implements the InteractorOutput protocol.

### The ViewController

The ViewController normally receives events from the UIControls, processes the data representing the system state and then send the results of the processing to the  UIControls and UIViews.

In VIPER, the ViewController sends <u>every</u> event that originates from a UIControl, or UIView directly to the Presenter.  The ViewController does not process the event in anyway whatsoever. 

The ViewController displays the data received via the PresenterOutput protocol.

**TODO:**  Note that this set up makes it very easy to reskin a ui

### The Presenter

When the Presenter receives an event it routes the event, either, to the Interactor or to the Router.

The Presenter's second responsibility is to process the data received via InteractorOutput or RouterOutput protocols. In the case of the InteractorOutput, it is converted to a format that is most convenient for display by the ViewController or is passed unconverted to the Router. In the case of the RouterOutput, it is converted and passed to the ViewController or passed directly to the Interactor. 

Data passed as output is called a ViewModel. In the case of repeating data the Presenter hold the viewModel structures and delivers them via an index method call.

### The Interactor

The Interactor is sometimes called a UseCase because it has one responsibility: run the use case defined for the event. Most events received by the Interactor cause it to access data via the EntityGateway. The Interactor can perform calculations and update the state of the system via the EntityGateway.

Data passed as output is called a PresentationModel. In the case of repeating data the Presenter convert the data and hold it as viewModel structures.

### The EntityGateway

As I mentioned, the EntityGateway is a protocol. 

The implementation of the EntityGateway yields access to the EntityManagers.  EntityManagers are responsible for providing access to the Entities.

The EntiryManagers are outside the scope of VIPER, but they are a very important aspect of the architecture as a whole. They access and transform the state of the system. They can deliver Entities originating in CoreData, over the network, or from local resources

In the end, the Interactor does not care where the data comes from or where it is going to. 

The EntityManagers should deliver Entities whose data are in the most useful, validated form for use by the Interactor, not just simple Strings. For example date Strings should be converted to Dates, URL Strings should be converted to URLs, and number Strings should be converted to their specific number type.  

### The Connector

You may be wondering how this stack of classes is created.

A ViewController is normally defined via IB, so we cannot use its init. Usually the ViewController allocates everything it needs, but: 

We do not want the ViewController to know anything about the Interactor. The Interactor must exist before the presenter can  own it. The Presenter must exist before the ViewController can own it.

 The VIPER stack is assembled by a 3rd party class that knows about all of the parts in the stack and how they are connected together. I have called this part the connector.

The Connector is created and executed by the ViewController by overriding `awakeFromNib()`, which occurs after all outlets are created.



## The App



