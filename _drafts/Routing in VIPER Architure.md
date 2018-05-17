---
layout: post
title: "Routing in VIPER Architure"
date: 2018-05-02
---

## Introduction

In the VIPER architecture, the responsibility of scene management is placed where it belongs: in the parent ViewController. A ViewController which manages one or more scenes is known as a Router.

A VIPER Router makes it possible to render a child ViewController without making it statically dependent on a parent or sibling ViewController. For example, a ViewController that is part of a sequence managed by a NavigationController can be reused in a modal situation or in any other sequence. A navigation sequence can easily be implemented with multiple starting positions.

### The Function of a Router

The primary function of a Router is to manage the display of a set of scenes using a pattern such as stacking, direct access or serial access. 

Router functionality is provided in iOS by specialized ViewControllers, such as Navigation-, TabBar- and PageView-Controllers. Each of these manages the display life cycle of a set of child ViewControllers. Custom Routers, also known as container ViewControllers, can be created to implement other useage patterns such as menu, custom tab access, or a domain-defined sequence.

Another function of a Router is to maintain system state for child modules.

The main difference between a VIPER Router and a UIKit router is that the routing code is located where it is supposed to be: in the Router - not the child view controllers

## Routers in VIPER

A VIPER Router is a [VIP module](http://lyleresnick.com/blog/2017/08/29/A-Crash-Course-on-the-VIPER-Architecture) that knows how to display child scenes using a pattern. All Routers will be implemented with a ViewController and a Presenter, but it will occasionally implement a UseCase. The biggest difference between a routing module and a regular module is that the module's ViewController class displays child ViewControllers instead of just views - some may do both.

A Router's ViewController can be inherited from a NavigationController, a TabBarController, or a  PageViewController. A custom Router inherits from a plain ViewController to create what is known as *container*  ViewController.

### The Presenter Communicates with the Router

The guiding rule of VIPER is that any event received by a ViewController must be forwarded directly to its Presenter. The Presenter, then, forwards the event to either its Use Case or its Router.

Here is an example of a Presenter interpreting a Cancel event and then forwarding it to its Router:

```Swift
class ItemEditPresenter {
	...
	func eventCancel() {
        switch editMode  {
        case .create:
            router.routeCreateItemCancelled()
        case .update:
            router.routeDisplayView()
        }
    }
}
```

When the Presenter receives output from the Use Case, it might send it on to the Router instead of the ViewController. An example of this is when a scene exits:

```Swift
extension ItemEditPresenter: ItemEditUseCaseOutput {
    ...
    func presentDisplayView() {
        router.routeDisplayView()
    }
}
```

The result is that a ViewController never communicates with a Router, only the presenter does.

### The Router's VIP Stack

A router has its own VIP stack: A ViewController, a Presenter and a UseCase. All of their roles are the usual ones.

#### The ViewController 

The role of a Router's ViewController is the same as it would be without VIPER: to do the work of changing scenes. 

When the Router's ViewController is a subclass of a NavigationController or TabBarController, the events from the UI are already consumed by the controller itself, so their delegates must be used to monitor events. 

One important use of the subclassed router's delegate is to inject the router's Presenter into each child ViewController before the child is displayed.

```Swift
extension TodoRootRouterNavController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
       
        switch viewController {
        case let viewController as TodoItemRouterViewController:
            viewController.router = presenter
        case let viewController as TodoListViewController:
            viewController.router = presenter
        default:
            fatalError("Unknown viewController encountered")
        }
    }
}
```

TODO: move this to where it makes sense: When using storyboard segues with a Navigation- or SplitView-Controller, the child's `perform(segue:)` methods are called from the parents implementation and the `prepareFor(segue:)` override is implemented as an extension within the NavigationController's file. This override is just a dance because the Navigation Controller actually implements the Segue.

In the case of a custom Routing ViewController, child ViewControllers are instantiated by the custom ViewController as normal, and the perform(segue:) and prepareFor(segue:) are implemented by the custom ViewController

In VIPER, a custom Router will send all UI events, including lifecycle events, to the Presenter.

#### The Presenter

The role of the Router's Presenter is the same as any other presenter: to consume events sent by the ViewController. When implementing a custom Router, such as one driven by menus, tabs, or custom sequence, the messages from the UI are passed directly to the presenter as usual. 

The majority of the messages that the Presenter will respond to are routing messages that come from the Router's child modules. These messages originate from events occurring in the Router's child modules.

The Presenter may simply translate the message's contents and send it to its output or it can pass the message to the Router's UseCase. 

The Presenter might instantiate state data models that will be injected into all child UseCases.

#### The UseCase

The Router's UseCase initializes data that will be shared by all child UseCases. Usually this occurs when the viewLoaded event is received.  Most of the time, the Router does not need to implement a UseCase.

#### Why are Router Messages implemented by the Router's Presenter?

The ViewController in VIPER only forwards inbound events and Displays the results of those events.

Router messages start as events in a child ViewController. All events received by a ViewController are forwarded to it's Presenter, so all Router messages are sent to the Presenter anyway.

In some cases the Router must refer to its UseCase to make a decision based on system state - a message would have to be sent through two layers just to get to the UseCase. 

In practice, implementing the routing messages in the Presenter is the right choice. 

## Changing Scenes 

### Who's Responsibility

In VIPER, initiation of a scene change is the responsibility of the parent (just like in Android). iOS has an opinion about how scene change should be initiated. 

In iOS, a ViewController is given access to its parent via one of the navigation-, tabBar- or splitView-Controller properties. This allows the child to know about and to control the behaviour of parent. In the case of navigation or splitView, the control is used to push a new controller on top. This leads to dependency issues, since this added responsibility ties the child to a predetermined environment defined by presentation-style or system state. 

iOS tries to overcome this problem for navigation and splitView by introducing the `show(:sender:)` and `showDetail(:sender:)` methods. These two methods remove from the child having to know which of the two types of containers it is in. 

In a VIPER architecture child ViewControllers make no assumptions about their environment and as such are available for use in any role, whether defined by presentation-style or system state.

### Storyboards

Storyboards provide a number of advantages other than simply reducing the need to hand-code view layouts. Storyboards document the layout and flow of the app. When a Segue instantiates a ViewController, it calls `awakeFromNib()`, which is used to configure the VIP stack and can perform post-IB injections. 

In most cases, using Storyboards is not counter to the architecture of a VIPER Router. The only unusual situation is when using NavigationControllers. 

#### NavigationControllers

In a Storyboard, the "relationship" Segue from a parent points to its first-displayed child. In the case of Navigation- or SplitView-Controllers, the next Segue points to the next-displayed sibling scene. 

Using a Segue and in turn the `show*(:sender:)` methods, a child ViewController of a Navigation- or SplitView-Controller by-passes the parent when initiating a sibling scene - or so it seems. The Segue actually calls the parent controller's `pushViewController(_:animated:)` method.

The problem for a VIPER Router implementation is that a Segue's source ViewController is the previous sibling, not the parent, so the parent's `prepareFor(segue:)` is not called - but the previous sibling's is called.

The solution to this is to create a extension in the parent ViewController's file and override `prepareFor(segue:)` there. Here the NavController's `showItem(id: String)` initates a Segue on the topmost child with an `id` parameter. The `prepare(for segue: UIStoryboardSegue, sender: Any?)`  of the child is used to inject the `id` into the child's sibling.

```Swift
extension SomeRouterNavController: SomeRouterPresenterOutput {
        
    func showItem(id: String) {

        let identifier = SomeRouterSegue.showSome.rawValue
        viewControllers.first?.performSegue(withIdentifier: identifier, sender: id)
    }
}
```

```Swift
extension SomeListViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let viewController = segue.destination as! SomeItemViewController
        let id = sender as! String
        viewController.id = id
    }
}
```




### Passing Data between Scenes
The router is responsible for passing local data between scenes. 

There are 3 kinds of local data that can passed between scenes: 

1. data originating in a View
2. data shared among collaborating UseCases (representing all or part of the system state).
3. data originating in a younger sibling scene's UseCase   

#### Passing Data Originating in a View

Data originates in a View when a user initiates an action. Normally, when a ViewController instantiates another ViewController, data is passed to the new ViewController by injection. It is no different in VIPER, except that the injector is always a Router. In VIPER, data must be passed to the Router before it can be passed to the new ViewController.

Not all data should be passed in this way. Recall that in VIPER, entities are never passed as output to the ViewController, only PresentationModels and in turn, ViewModels. Data sent to a Router can be translated by the Presenter, if necessary.  This often occurs when a selection is made in a table and the index is translated to an `id` supplied by a ViewModel as is shown in this snippet of a Presenter:

```Swift
func eventItemSelected(index: Int) {
    
    router.routeDisplayItem(id: viewModelList[index].id)
}
```

#### Passing Data Among Collaborating UseCases

It is not uncommon for multiple scenes to collaborate in order to complete real world *Use Case*. 

Shared Entities that a UseCase manipulates should not be retrieved from the UseCase by the Presenter and then passed on to the Router only to be passed to the next ViewController, Presenter and UseCase. This would be quite tedious and is against the ruls tha the ViewController should not be concerned with Entities.

There are two ways to pass data among multiple scenes, both of which involve injection. 

##### Injecting a Global State Model 

The first way is the simplest. A state Model, which represents the state all of the shared data, can be attached to the Entity Gateway. Since the gateway is already injected into all UseCases, this is the easiest way to share data and make it available to all UseCases. The downside to this is that all UseCases in the whole app will have access to this state model and it becomes hard to know which use cases are updating the model and what the models life cycle actually is. There are also cases where a recursive model is required and a global state cannot support this. 

##### Injecting a Local State Model 

Another method, which limits the scope of the state model to a small number of scenes and allows for recursion is one where the Router's Presenter instantiates the state model for use by its own and child UseCases. The model is accessed by the child Presenters when the router is injected and then is itself injected into the child's UseCase. In this manner the models scope is limited to just those scenes which actually need access to it. 

Here is an example of a UseCase state model for a multi-scene use case for sending money:

```swift
class SendMoneyUseCaseState {
    var fromAccount: Account
	var amount: Money
	var recipient: Recipient
}
```

Below the scene Router's Presenter instantiates the model and injects it into its own UseCase so it can be initialized:

```Swift
class SendMoneyRouterPresenter {

    var state = SendMoneyUseCaseState()

    init(useCase: SendMoneyRouterUseCase) {
        self.useCase = useCase
        useCase.state = state
    }
    // ...
}
```

Here a child scene's Presenter injects the Router's state into the UseCase:

```swift
class SendMoneyStepOnePresenter {
    weak var router: SendMoneyStepOneRouter! {
        didSet {
            useCase.state = router.state
        }
    }
    // ...
}
```

If the state does not need to be initialized by the Router's UseCase, there is probably no reason for the Router to have a UseCase.



FIXME: <u>put this somewhere</u>: Each child's Router is defined by a protocol. It is implemented by the parent.


TODO: passing view controller parameters
TODO: passing callbacks instead of self

#### Connecting the Presenter to the Router



### Going against the grain

#### Allocating class responsibilities appropriately

#### Responses from other Scenes (Alternative to the view controller delegate pattern)

There are also cases where a presentation model must be prepared for an older sibling that the presenter must convert to view models (see TodoListPresenter.eventItemSelected())

## 

#### Additional behaviour for the Nav controller subclass 



## App Overview

Here is a screen shot of the top of the display:

![ReportListDemoTop](/Assets/ReportListDemoTop.png)

Here is the middle :

![ReportListDemoMiddle](/Assets/ReportListDemoMiddle.png)









 I decided the best way to proceed was to generate the output into a separate structure to drive the display. 



```
public class TransactionModel {
	String group;
	String date;
	String description;
	String amount;
	String debit;
}
```

