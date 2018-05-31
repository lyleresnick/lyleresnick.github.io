---
layout: post
title: "Routing in VIPER Architure"
date: 2018-05-02
---

## Introduction

The primary function of a Router is to manage the display of a set of scenes using a pattern such as stacking, direct access or serial access. 

In the VIPER architecture, the responsibility for scene management is given to the parent ViewController. A ViewController which manages one or more scenes is known as a Router.

A VIPER Router makes it possible to create a child ViewController that is not dependent on a parent or sibling ViewController. For example, a ViewController that is part of a sequence managed by a NavigationController can be reused in a modal situation or in another sequence. A navigation sequence can easily be implemented to have multiple starting positions.

A secondary function of a Router is to maintain system state for child modules.

## Routers in VIPER

In VIPER, initiation of a scene change is the responsibility of the parent (just like in Android). 

In iOS, a ViewController is given access to its parent via one of the navigation-, tabBar- or splitView-Controller properties. This allows the child to know about and to control the behaviour of parent. In the case of navigation or splitView, the control is used to push a new controller on top. This leads to dependency issues, since this added responsibility ties the child to a predetermined environment defined by presentation-style or system state. 

iOS tries to overcome this problem for navigation and splitView by introducing the `show(:sender:)` and `showDetail(:sender:)` methods. These two methods remove from the child having to know which of the two types of containers it is in. 

In a VIPER architecture child ViewControllers make no assumptions about their environment and as such are available for use in any role, whether defined by presentation-style or system state.

In iOS, router functions are provided by specialized ViewControllers, such as Navigation-, TabBar- and PageView-Controllers. Each of these manage the life cycle and display of a set of child ViewControllers. A custom Router, known as a container ViewController in iOS, can be created to implement non-standard usage patterns such as menus, custom tab paging, or some other domain-defined sequence.

The main difference between a VIPER Router and a UIKit router is that routing code is located in the Router - not in a child ViewController. This is not unlike the situation in the Android architecture.

Each VIPER Router has a ViewController and a Presenter, and occasionally it will have a UseCase. The main difference between a routing module and a regular module is that its ViewController class displays child ViewControllers instead of just views, although some might display both.

A VIPER Router is implemented just like a regular [VIP module ](http://lyleresnick.com/blog/2017/08/29/A-Crash-Course-on-the-VIPER-Architecture). The ViewController can be inherited from a NavigationController, a TabBarController, or a  PageViewController, as usual. A custom Router is inherited from a plain ViewController.

## The Presenter Communicates with the Router

A primary rule of VIPER is that any event received by a ViewController must be forwarded directly to its Presenter, without further processing. The Presenter has the responsibility to forward the event to either its UseCase or its Router.

Here is an example of a Presenter interpreting a "Cancel" event and then forwarding it to its Router:

```swift
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

A Presenter can also send an event on to it's Router when it receives output from it's Use Case.  An example of this is when a scene exits due to a "Save" event:

```swift
extension ItemEditPresenter: ItemEditSaveUseCaseOutput {
    ...
    func presentDisplayView() {
        router.routeDisplayView()
    }
}
```

The result is that a ViewController never communicates with a Router, only the Presenter does.

## The Router's VIP Stack

A router has its own VIP stack: A ViewController, a Presenter and a UseCase. Each of their roles are the usual ones. In order to understand how to implement a Router it is helpful to understand the implementation of a custom Router.

The following interaction diagram details the interaction that occurs between a parent VIP Router and its initial child.  

![RouterInstantiationOfFirstChildSequence](/Assets/RouterInstantiationOfFirstChildSequence.png)

This diagram may look overwhelming at first, but it simply reallocates work which is normally performed in the child, to the parent.

### The ViewController 

The role of a Router's ViewController is the same as it would be without VIPER: to do the work of changing scenes. 

A custom Router (a UIKit container ViewController) sends all UI events, including lifecycle events, to the Presenter. The viewDidLoad is implemented as it would be in any other VIP module: 

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    presenter.eventViewReady()
}
```

### The Presenter

In that the Presenter consumes events sent by the ViewController, the role of the Router's Presenter is similar to any other Presenter. 

If the processing for an event only involves changing of a scene,  the event will be sent right back to the ViewController.

```swift
func eventViewReady() {
    output.showOnboardingFirstScene()
}
```

When the Router has to initialize data for use by its children, or the scene to display must be determined from global state, the event is sent on to the Router's UseCase. The Presenter might instantiate state data models that are injected into its child UseCases: 

```swift
var state = ItemUseCaseState()

init(useCase: ItemRouterUseCase) {
    self.useCase = useCase
    useCase.state = state
}

func eventViewReady() {
    useCase.eventViewReady(startMode: startMode)
}
```



Most of the responsibilities of the Presenter are about responding to it's child VIP modules. See Below.

### The UseCase

Most of the time, the Router does not need to implement a UseCase.

There are two major reasons for a Router to implement a UseCase:

1. to initialize data that will be shared by the UseCases of its children. 
2. to determine which scene should be displayed, based on  global state. 


In both of these cases, this would be implemented when the `viewReady` event is received.  

In a custom Router, the ViewController is responsible for initiating the display of the child ViewController. This is performed by calling `performSegue(withIdentifier:sender:)`as usual.

### The Presenter as UseCaseOutput

Just as with the UseCase, most of the time, the Router does not need to implement UseCaseOutput.

In most cases the Presenter as UseCaseOutput is pretty straight forward. It will usually only be responsible for forwarding messages to the ViewController, but there are times where it may be need to translate error messages as required by the UseCase. 

### The ViewController as PresenterOutput

The job of the ViewController as PresenterOutput is to arrange for the child scenes to be displayed. Here, the ViewController initiates a Segue to display an EditView:

```swift
private enum Segue: String {
    case showDisplayView
    case showEditView
}

func showViewReady() {

    DispatchQueue.main.async {
        self.performSegue(withIdentifier: Segue.showEditView.rawValue, sender: itemParameters)
    }
}
```

The ViewController must set the child's router to the Router's Presenter. It must also set the domain parameters, if there are any, for the scene. This is done in the `prepare(for:sender:)` override:

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any? = nil) {

    switch Segue(rawValue: segue.identifier!)! {
    case .showDisplayView:

        let viewController = segue.destination as! ItemDisplayViewController
        viewController.router = presenter
        viewController.domainParameters = sender as! ItemParameters

    case .showEditView:

        let viewController = segue.destination as! ItemEditViewController
        viewController.router = presenter
        viewController.domainParameters = sender as! ItemParameters
        
    }
}
```

It is usually easiest to pass domain parameters is via the sender parameter. If there is more than one,  a struct can be used. This technique should be used even when not using VIPER, as the parameter is not used  for anything else in a manual Segue.

The ViewController also has the option of displaying its own Views in lieu of displaying a ViewController. This might be the easiest way to display an error message when there is a failure detected in the UseCase.

### Subclasses of NavigationController

When the Router's ViewController is a subclass of a Navigation- or SplitViewController, the most interesting UI events are directly consumed by the controller. In this case, the respective -ControllerDelegate is used to monitor the events.  

The most important use of the -ControllerDelegate is to inject the Router's Presenter into each child ViewController as the Router before the child is displayed.

```swift
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

Aside from the initial scene display, a scene change request almost always occurs when the ViewController receives a request from its own Presenter, which originates in a child ViewController.

## Changing Scenes

Take the scenario where a ViewController displays a List and an Add button. The user can to add an item to the list or display an item already in the list. Tapping the Add button takes the user to another scene to enter the details of a new item. Tapping an item in the list takes the user to another scene which displays the details of the item.

It is the routers responsibility to make the transition from the initial scene to the final scene. From the initial ViewControllers point of view the router looks like this:

```swift
protocol ListRouter: class {
    
    func routeDisplayItem(id: String)
    func routeCreateItem()
}
```

The router is passed to all child ViewControllers as an abstraction which implements one specific routing protocol for each child. 

The following interaction diagram shows an initial ViewController initiating the display of an new scene:

![RouterInstantiationViaChildSequence](/Assets/RouterInstantiationViaChildSequence.png)

The message sequence is the same, regardless of whether the router is custom or off the shelf. 

### The Child ViewController

The child ViewController receives an event in the usual manner. The event is immediately passed on to the child's Presenter. Here is a typical implementation for an "Add" button:

```swift
@IBAction func addTapped(_ sender: Any) {
    presenter.eventCreateItem()
}
```

Here is a typical implementation for a TableViewCell selection: 

```swift
extension ListAdapter: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.eventItemSelected(index: indexPath.row)
    }
}
```

### The Child Presenter

The Presenter sends the events on to the router as follows:

```swift
func eventCreateItem() {
    router.routeCreateItem() 
}

func eventItemSelected(index: Int) {
    router.routeDisplayItem(id: viewModelList[index].id) 
}
```

In the case of the item selection, the `index` is translated into the `id` of the item that will be displayed.

### The Router's Presenter

The Router Presenter's job is simple: send the event on to the ViewController.

```swift
extension RootRouterPresenter: ListRouter {
    
    func routeDisplayItem(id: String) {
        output.showItem(id: id)
    }
    
    func routeCreateItem() {
        output.showCreateItem()
    }
}
```

### The Router's ViewController

The Router's ViewController initiates the Segue of the child. In the case of displaying the selected item, sends the `id` in the, otherwise unused, `sender` parameter:

```swift
private enum RootRouterSegue: String {
    case create
    case show
}

extension RootRouterNavController: RootRouterPresenterOutput {
    
    func showCreateItem() {
        
        let identifier = RootRouterSegue.create.rawValue
        viewControllers.first?.performSegue(withIdentifier: identifier, sender: nil)
    }
    
    func showItem(id: String) {
        
        let identifier = RootRouterSegue.show.rawValue
        viewControllers.first?.performSegue(withIdentifier: identifier, sender: id)
    }
}
```

Given the way that navigation Segues are implemented, the `prepare(for:sender:)`  must be overridden in the child ViewController. To keep this routing code in the router, simply create an extension in the Router ViewController's file: 

```swift
extension ListViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch RootRouterSegue(rawValue:segue.identifier!)! {
        case .create:
            break
        case .show:
            let viewController = segue.destination as! ItemDisplayViewController
        	viewController.id = sender as! String
        }
    }
}
```

If you really wanted to be pure about responsibility, you could create a custom Segue whose source would be the NavigationController - it would not look as good in the storyboard but it would make more sense from a responsibility point of view.


## Passing Data between Scenes
The router is responsible for passing local data between scenes. 

There are 3 kinds of local data that can passed between scenes: 

1. data originating in a View
2. data shared among collaborating UseCases (representing all or part of the system state).
3. data originating in a younger sibling scene's UseCase   

### Passing Data Originating in a View

Data originates in a View when a user initiates an action. Normally, when a ViewController instantiates another ViewController, data is passed to the new ViewController by injection. It is no different in VIPER, except that the injector is always a Router. In VIPER, data must be passed to the Router before it can be passed to the new ViewController.

Not all data should be passed in this way. Recall that in VIPER, entities are never passed as output to the ViewController, only PresentationModels and in turn, ViewModels. Data sent to a Router can be translated by the Presenter, if necessary.  This often occurs when a selection is made in a table and the index is translated to an `id` supplied by a ViewModel as is shown in this snippet of a Presenter:

```swift
func eventItemSelected(index: Int) {
    
    router.routeDisplayItem(id: viewModelList[index].id)
}
```

### Passing Data Among Collaborating UseCases

It is not uncommon for multiple scenes to collaborate in order to complete real world *Use Case*. 

Shared Entities that a UseCase manipulates should not be retrieved from the UseCase by the Presenter and then passed on to the Router only to be passed to the next ViewController, Presenter and UseCase. This would be quite tedious and is against the ruls tha the ViewController should not be concerned with Entities.

There are two ways to pass data among multiple scenes, both of which involve injection. 

#### Injecting a Global State Model 

The first way is the simplest. A state Model, which represents the state all of the shared data, can be attached to the Entity Gateway. Since the gateway is already injected into all UseCases, this is the easiest way to share data and make it available to all UseCases. The downside to this is that all UseCases in the whole app will have access to this state model and it becomes hard to know which use cases are updating the model and what the models life cycle actually is. There are also cases where a recursive model is required and a global state cannot support this. 

#### Injecting a Local State Model 

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

```swift
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


