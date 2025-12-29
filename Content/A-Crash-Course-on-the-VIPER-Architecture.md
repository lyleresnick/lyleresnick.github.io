---
layout: BlogPost
date: 2017-08-29 12:00
tags: VIPER
---

# A Crash Course on the VIPER Architecture

## Introduction

I've been exploring and using the VIPER architecture now for about 2 years. I think it is a really sensible solution for organizing and reducing the size of a Massive ViewController. 

Reducing the size of a ViewController is a notable goal, but how should it be done? 

One common way to architect an app is to layer the app into an User Interface layer and a Service layer. 

The Service layer is responsible for transferring data between the User Interface layer and either the internet, a local database, or the filesystem.  This layer may also perform other non-functional duties such as caching, syncing, etc. 

The User Interface layer does something useful with this data - which is ultimately the purpose of the app.

This two layer architecture is too simple. It does not account for the placement of all of the responsibilities of the so called *User Interface layer*. A lot of processing happens in this layer. Many times, all of this processing ends up inside a UIViewController.

In commercial applications, UIViewControllers get large. I've seen 2000 lines in a UIViewController.

VIPER is a micro-architecture - a predefined set of classes that work together to structure a solution. VIPER is an implementation of [Bob Martin's Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html). 

In this post we will look at the various components and responsibilities of the VIPER architecture. 

In the next post, I’ll demonstrate that the VIPER architecture can be very simple to implement and show how its benefits can be quickly realized.  We will use the requirement and solution to [Solving a Complex UITableView Even More Swiftly](/Solving-a-Complex-UITableView-Even-More-Swiftly) as the basis of this example. The app which demonstrates the refactoring to Clean Architecture can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo). I will be explaining this app in the next post.

## An Explanation of the VIPER Architecture 

The main purpose of the VIPER architecture is to reduce the amount of code contained in a ViewController. VIPER does this by allocating almost all of the responsibilities of a typical ViewController into other classes that have predefined responsibilities. You may recall that this echoes the Single Responsibility Principle. 

Another purpose of the VIPER architecture is to reduce dependencies. It does this by honouring layer boundaries, passing only values between the layers and demanding that explicit object dependencies point only in one direction.

All of this makes it easier to change the code which is normally contained in a UIViewController - which is usually everything.

To understand VIPER you need to understand a bit about the the Clean Architecture. 

### Uncle Bob's Diagram

![Bob Martin's Clean Architecture](https://blog.cleancoder.com/uncle-bob/images/2012-08-13-the-clean-architecture/CleanArchitecture.jpg)

As Uncle Bob's diagram shows, a Clean System is separated into layers:

- the User Interface is in the outermost layer of the system 
- the Entities are at the centre of the system and are the results of applying Enterprise Business Rules. 
- the Application Business Rules reside in the layer which surrounds the Entities
- the Data Store and Network, which provide the entities, are in the outermost layer
- the Interface Adapters, and in particular, the Presenters and Gateways are placed in a layer between the User Interface and Application Business logic layers

### Object Dependencies should point Towards the Centre 

In the Clean Architecture, object dependencies can only be explicit in one direction - towards the centre. This is shown in the diagram by the dependency arrow pointing inward. A class in a layer closer to the centre is not allowed know the name of a class in a layer closer to the outside. 

All dependencies going in a direction away from the centre must be implemented as a dependency inversion. The inversion is implemented as a protocol and the dependent object must to be injected into the layer. You will find this is an advantage when writing tests. 

The *Flow of control* diagram, on the right, shows the implementation of a dependency inversion where the Presenter implements the UseCaseOutput, which is produced by the UseCase. This implementation allows the UseCase to remain naive as to where it is actually sending its output. The relationship between the UI and the PresenterOutput is analogous.

### Copy Data Values

Another requirement of the Clean Architecture is that data must be copied from layer to layer. This means that we cannot pass the same data or data structure from one layer to the next: we can only pass copies. 

In Swift we can pass singular values, `struct`s of values or `enum`s with values as parameters and they will be copied automatically. 

Copying data between layers by passing values, instead of objects prevents implementation changes in one layer accidentally affecting other layers. It also helps reduce  concurrent access errors.

### Honour The Layer Boundaries

Clean Architecture also requires that objects in one layer can only communicate to adjacent layers. Objects in non-adjacent layers cannot communicate with one another. 

Objects in a layer must not expose their implementation to any other layer. The implementation must be encapsulated. For example an array or dictionary in a layer must not be exposed by name to another layer. 

### The VIPER Classes

In the VIPER architecture, 

- the ViewController(**V**) implements the User Interface. 
- the Presenter(**P**) implements 2 parts of the interface adapter layer: data conversion and selection of whether to Route to another scene or perform a UseCase 
- the Interactor(**I**), a.k.a the UseCase, implements the application business rules
- the Entities(**E**) are provided by an EntityGateway via Gateway Methods
- the Router(**R**) changes ViewControllers 

This diagram shows the relationships between the VIPER classes.

![Diagram of VIPER classes](/images/VIPERClassDiagram.png)

The ViewController owns a Presenter, which in turn owns an Interactor.  The presenter has a one-way relationship with the Router. The Router owns and has a one-way relationship with child ViewControllers that it creates and manages.

The ViewController sends messages to the Presenter, which in turn sends messages to the UseCase or the Router. 

Each ViewController, Presenter and UseCase is called a VIP stack. In a VIPER architected system, one VIP stack is created whenever a new UIViewControler is created.

The UseCase uses an EntityGateway to obtain access to EntityManagers. EntityManagers are responsible for providing access to the Entities. The EntityGateway is used by all UseCases to access all available EntityManagers.

The Router is a VIP stack that knows about child ViewControllers. This is a very important notion.

### Communication Between the Classes

Since VIPER is an implementation of the Clean Architecture, there are a few rules to follow: 

1. Dependencies can only be explicit in one direction: towards the centre.
2. Data must be copied from layer to layer as values or structs of values

Entities are at the centre of the diagram. In order to access the Entities, the EntityGateway must be injected into the Use Case. In order to remove the explicit dependency of the UseCase on the EntityGateway, the gateway is implemented as a protocol.

In order to transmit the results of the UseCase to the ViewController, they must be first sent to the Presenter. The Presenter sends its converted results to the ViewController. Since these messages are moving away from the centre, the target classes are specified as protocols. 

The output of the UseCase is a protocol called the UseCaseOutput and the output of the Presenter is a protocol called the PresenterOutput. The ViewController implements the PresenterOutput protocol and the Presenter implements the UseCaseOutput protocol.

Although outside the scope of this blog, I want to mention that the EntityManagers, which the EntityGateway provides, should also be implemented as protocols.

## The VIPER Pipeline

You can think of the VIPER architecture as a pipeline. Each stage of the pipeline has a well defined job to do. 

Here is a diagram showing the event flow between the View Controller and the Entity Gateway

![Diagram of VIPER classes](/images/VIPERUseCaseSequence.png)

The diagram shows that a user or device initiates a sequence by sending an event to a UIViewController. An event can be the result of a user touching a button or a device delivering a location or some other sensor data.

The event is passed to the ViewController as usual. 

In the case of repeating touchable areas displayed by UITable and UICollectionViews, a touch event should be sent to the UITable- or UICollectionViewCell, respectively.

It is useful think of the arrows as if they all pointed to the right as if in a waterfall. This promotes the idea that data flows in one direction only.

### The ViewController 

The ViewController's main role in VIPER is to the configure the View hierarchy. Most of this configuration should performed by Interface Builder.

In VIPER, the UIViewController sends <u>every</u> event coming from a UIControl or lifecycle method directly to the Presenter. The ViewController does not process the event in any way, whatsoever. It simply retrieves associated data, either input as text or selected by index, and sends it with the event to the Presenter. In the case of repeating UIControls contained in a UITableView or UICollectionView, the Cell receives the event and sends it to the Presenter.  Super simple!

You can see in the interaction diagram that the ViewController has another role: show the output for the event. We will discuss this role, below.

#### ViewController Examples

Here are some examples of UIViewControllers, or their delegate proxies, capturing events and then immediately delegating them to a Presenter.

##### Initialization

In this UIViewController `viewDidLoad` method, all views have been configured in Interface Builder. There is nothing to do other than pass the message to the Presenter. 

The height of the main view is passed to the Presenter so it can set the height of a UITableViewCell to the full screen height when showing  errors or other unusual states.

```swift
class ContactListViewController: UIViewController {
  
    var presenter: ContactListPresenter!
  
    override func viewDidLoad() {
       super.viewDidLoad()
       presenter.eventViewReady(maxHeight: view.bounds.height)
    }
}
```

##### UITextFieldDelegate

In this UITextDelegate `textFieldShouldReturn` method, the text is captured as a quantity. If the Presenter finds that the text is valid, it returns true.

```swift
class OrderEntryQuantityDelegate: UITextFieldDelegate {
  
    var presenter: OrderEntryPresenter!

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return presenter.eventCapture(quantity: textField.text)
    }
}
```

##### @IBAction

When a button is touched, a UIViewController `@IBAction` method delegates to the Presenter. 

`@IBAction` methods located in a UITableViewCell should also delegate directly to the presenter, but must also pass the index of the cell in which the button was located.

```swift
class OrderEntryViewController: UIViewController {
  
    var presenter: OrderEntryPresenter!

    @IBAction func saveButtonTouched(_ sender: UIButton) {
        presenter.eventSave()
    }
}
```

##### UITableViewDelegate

When a UITableView row is selected, the event is delegated to the Presenter in the UITableViewDelegate `didSelectRowAt` method.

```swift
class ContactListAdapter: NSObject {
    var presenter: ContactListPresenter!
}
extension ContactListAdapter: UITableViewDelegate {
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.eventContactSelected(at: indexPath.row)
    }
}
```

When an event is generated in a cell by a control, the index should be injected into the cell so it can be sent with the event.

### The Presenter

The Presenter's role is to receive an event from the ViewController and pass it to either the UseCase or the Router. It converts the event's parameters from external format to an internal format that can be used directly by the UseCase or the Router.   

Examples of input conversion might be from String to Int, formatted String date to Date, an Int from a UIPickerView to an enum - the list goes on. 

As you may have noticed in the diagram, the Presenter has another role: present the result of the event. We will discuss this role, below.

#### Presenter Examples

Here are some examples of the Presenter receiving events from the UIViewController and then sending them on to the UseCase.

##### Initialization

Here the Presenter's `eventViewReady()` method retains the `maxHeight` for later use and then passes the message to the UseCase.

```swift
class ContactListPresenter {
  
    let useCase: ContactListUseCase
    var output: ContactListPresenterOutput!
    // init ...
  
    func eventViewReady(maxHeight: Int) {
        self.maxHeight = maxHeight
        useCase.eventViewReady()
    }
}
```
Capturing a value, like `maxHeight`, for later use by the Presenter is fine, but only in `viewReady`, and only if it remains constant. When the value is specific to an event, you should pass it through to the UseCase.

##### Data Capture

In this example, the Presenter's `eventCapture(quantity:)` tries to convert the quantity parameter into an `Int`. On success it sends the event to the UseCase with the converted data. It is up to the UseCase to determine whether the quantity is valid. On failure to convert the quantity, the error output is sent back to the ViewController. 

```swift
class OrderEntryPresenter {
  
    let useCase: OrderEntryUseCase
    var output: OrderEntryPresenterOutput!
    // init ...

    func eventCapture(quantity: String) -> Bool {
        if let quantity = Int(quantity) {
            useCase.eventCapture(quantity: quantity)
            return true
        }
        else {
            output.showFormatError(NSLocalizeString("Format of Quantity must be digits only", nil)
            return false
        }
    }
}
```

Note that validation could be performed by a "smart" textField, whose configuration would include its format and error message. In this case, the configuration would be specified to the ViewController by the PresenterOutput resulting from a  `viewReady` message (more about this later).  

Either way, the format of the data and the text of the error message is the domain of the Presenter, since it is responsible for implementing localization and accessibility. When a smart textfield is used, say, to implement format-as-you-type phone numbers, the format would be supplied by the Presenter.

##### Simple Delegation

Sometimes the Presenter just delegates to the UseCase, as in this example.  

```swift
class OrderEntryPresenter {
    // ...

    func eventSave() {
        useCase.eventSave()
    }
}
```

##### Indexing

In response to a UITableView selection, this Presenter receives a  `eventContactSelected(at row: Int)` message. It gets the contactId from the ViewModel  (which we will talk about later) and then delegates the event to the router to display the selected contact. 

Yes, you should put data in the ViewModel to support the processing of potential future events. 

```swift
class ContactPresenter {
  
    let useCase: ContactUseCase
    var router: ContactRouter!
    var output: ContactPresenterOutput!
  
    var contactViewModels = [ContactViewModel]()

    // init ...
  
    func eventContactSelected(at row: Int) {
        let contactId = contactViewModels[row].id
        router.eventContactSelected(id: contactId)
    }
}
```

If the Presenter required a callback, it would send itself as a delegate to be passed on to the Presenter of the VIP Stack that the router would instantiate.

### The Router

The Router is responsible for managing scene transition. A Router can be a UINavigationController,  a UITabController or a custom container ViewController.  From my point of view, a router is simply a Container ViewController which itself is a VIP stack.

The router implementation is discussed in a future post. 

### The UseCase

The UseCase has one responsibility: execute the application business requirement. The only code that belongs in a UseCase is the code which implements the application business rules. The UseCase should not contain data conversion or external format validation - these are both the domain of the Presenter or the EntityManagers.

The UseCase uses the EntityGateway to access the EntityManagers. The UseCase then uses the  EntityManagers to access the system state in the form of Entities. It processes the Entities using the incoming parameters, and updates the system state via the EntityGateway. It may do this over the course of responding to more than one event. One event may cause the UseCase to access the Entities and output them in some order and the next event may select one of the entities and have the UseCase update it in some way.

The results of executing the UseCase are passed as parameters to the UseCaseOutput protocol in a form known as the PresentationModel. 

Entities are never passed directly to the UseCaseOutput. PresentationModels are created from Entities, even when the Entity does not require much processing. The PresentationModel contains only the data which is required to create the output. The UseCase does not convert data for output - it does not know anything about the output format, localization or target views. Creating output via PresentationModels is kind of like logging without any descriptive text.

A PresentationModel can be passed to the UseCaseOutput as a `struct`, as an `enum` or as simple scalars - whatever is most convenient. When a `struct` is used, a good practice is to initialize it by passing it the Entity.

Data Conversion is performed by the Presenter and the EntityManagers. This allows the code in the UseCase to be free of the responsibilities of conversion and data validation. 

The separation of the Entities in the UseCase from the PresentationModels used by the Presenter makes sure that the UseCase is decoupled from the Presenter, thus promoting a reduction of shared mutable state. This allows the form of Entity to be changed without affecting the outer layers of the system.

 The UseCase has no direct dependencies - both the EntityGateway and the UseCaseOutput are protocols and are injected (by the Connector).

When the number of events that a scene supports becomes large, the number of methods on a single output protocol becomes even larger. It becomes really hard to tell at a glance which UseCaseOutput methods are used by what events. For this reason, it is a good practice to create one UseCaseOutput protocol for each event. The general UseCaseOutput protocol will extend all event specific UseCaseOutput protocols. Your code will be well organized when you place the implementation of each output protocol in its own extension. You can place reusable implementations in the general UseCaseOutput extension.

#### UseCase Examples

Here are some examples of events which come from a Presenter and are processed by a UseCase. The UseCase sends its output to a UseCaseOutput protocol.

##### Initialization Processing of a Singular View

Here the UseCase's `eventViewReady(contactId:)` method accesses a contact from the same  `ContactManager` as previous. It processes the Contact Entity by converting it to a ContactPresentationModel and then sending it to the UseCaseOutput. 

```swift
class ContactUseCase {
  
    let entityGateway: EntityGateWay
    var output: ContactUseCaseOutput!
    // init ...

    func eventViewReady(contactId: String) {

        entityGateway.contactManager.fetch(contactId: contactId) { result in

            switch result {
            case let .success(contact):
                 output.present(contact: ContactPresentationModel(contact: contact))
            case let .failure(error):
                output.present(error:error.reason)
            }
        }
    }
}
```

##### Initialization Processing of a Repetitive View

Here the UseCase's `eventViewReady()` method accesses contacts from a `ContactManager`, which is provided by the `EntityGateway` . It processes each Contact entity by converting it to a ContactListPresentationModel and then sending it to the UseCaseOutput. Note that this PresentationModel is not the same as the previous one in that it contains fewer properties.

The array of ContactEntities is not copied directly to the Presenter. Each Entity is sent one at a time.

Before the contacts are sent to the Presenter as UseCaseOutput, a Start message is sent. The Start message tells the UseCaseOutput to prepare for the new incoming list. You can pass titles or other non-repeating data which describes the whole list, as parameters to the method. 

After the contacts are sent to the Presenter, an End message is sent. The End message tells the Presenter all contacts have been sent. You can pass totals or other calculated data as parameters to the method. 

Two other results of processing shown here: the error case and the zero case.

Note that you can opt to pass the Contact properties as individual parameters to the UseCaseOutput methods, instead of using a PresentationModel struct.

```swift
class ContactListUseCase {
  
    let entityGateway: EntityGateway
    var output: ContactListUseCaseOutput!
    // init ...

    func eventViewReady() {

        let currentUser = entityGateway.userManager.currentUser
        entityGateway.contactManager.fetchAll(user: currentUser) { result in

            output.presentContactListStart()
            switch result {
            case let .success(contacts):
                if contacts.count > 0 {
                    for contact in contacts {
                        output.present(contact: ContactListPresentationModel(contact: contact))
                    }
                }
                else {
                    output.presentNoContactsFound()
                }

            case let .failure(error):
                output.present(error: error.reason)
            }
            output.presentContactListEnd()
        }
    }
}
```

##### Data Capture

In this example of data capture, the UseCase's `eventCapture(quantity:)`  and `eventCapture(productId:)` methods set the values to non-nil. 

The `eventSave()` method verifies that all mandatory fields have been entered and then uses an `orderManager` to create an order. It sends the newly created order to the UseCaseOutput. 

```swift
class OrderEntryUseCase {
  
    let entityGateway: EntityGateway
    var output: OrderEntryUseCaseOutput!
    // init ...

    var quantity: Int?
    var productId: String?

    func eventCapture(quantity: Int) {
        self.quantity = quantity
    }

    func eventCapture(productId: String) {
        self.productId = productId
    }

    func eventSave() {

        if let quantity = quantity, let productId = productId {

            entityGateway.orderManager.create(userId: userId, productId: productId, quantity: quantity) { result in 

                switch(result) {                                                                                         
                case let .success(order):
                    output.present(order: OrderEntryPresentationModel(order))
                case let .failure(error):
                    output.present(error:error.reason)
                }                                                                                          
            }
          }
        else {
            output.presentMissingMandatoryFields(productId: productId == nil, quantity: quantity == nil)
       }
    }
}
```

### The EntityGateway and EntityManagers

The UseCase uses an injected EntityGateway to obtain access to EntityManagers. EntityManagers are responsible for providing access to the Entities and for updating them. Entity Managers are also known as the Service Layer or Data Access Objects in other layered architectures.

The EntiryManagers are outside the scope of VIPER, but they are a very important aspect of the architecture as a whole. They provide access to and transform the state of the system. They deliver Entities originating from either local data stores (CoreData or a local file system) and from the Internet. 

It is a good practice to create an EntityManager for each type of Entity that has its own lifecycle. 

The UseCase does not know where the data is coming from or where it is going to - that is the job of the EntityManager.

An EntityManager receives data originating as JSON, XML, or some other external format from an external store and converts it to structs. 

The EntityManager creates the Entity by converting data from an external form to a form that can be used directly by the UseCase. Entities should not contain Strings that are actually numbers and enums, or unconverted JSON dictionaries. For example: date Strings should be converted to Dates, URL Strings should be converted to URLs, number Strings should be converted to their specific number type and exclusive values should be converted to enums. 

After processing, the UseCase sends an Entity with parameters to the EntityManager, where it combines them and sends the changes in an external format to an external store.

Data sent to an EntityManager should not require conversion by the UseCase. It is the job of the EntityManager to convert data from its internal form to its external form.

By providing the data conversion, the EntityManagers effectively decouple the UseCase from the physical form and location of external storage. 

As discussed, the EntityGateway is a protocol. It is defined as a protocol so that the UseCase is decoupled from the source of the data. EntityManagers should also be defined in terms of protocols. This makes it very easy to unit test the UseCase. You can inject an alternate implementation of an EntityManager to control the data for a test.

### The Transformer

The Transformer is not formally part of VIPER, but due of the number of events that a typical UseCase has  to process, it is useful to create one Transformer class for each event that changes the state of the system.  

Normally the functionality of a Transformer would be rendered as a method of a UseCase. Convert the method to a *method-object* and then call it from the UseCase event method. The Transformer usually consists of a constructor and a method called `transform` . In the UseCase method, initialize the constructor with the required EntityManagers obtained from the EntityGateway and any data required from previously run UseCases. 

Pass the event parameters from UseCase to the `transform` method along with the reference to the Presenter (for output).

Here is an example:

```swift
class OrderEntrySaveUseCaseTransformer {
    
    let orderManager: OrderManager
    let userManager: UserManager
    
    init(orderManager: OrderManager, userManager: UserManager) {
        self.orderManager = orderManager
        self.userManager = userManager
    }
    
    func transform(quantity: Int?, productId: String?, output: OrderEntrySaveUseCaseOutput) {
        
        if let quantity = quantity, let productId = productId {
            
            orderManager.create(userId: userManager.currentUserId, productId: productId, quantity: quantity) { result in
                
                switch(result) {
                case .success(order):
                    output.present(order: OrderPresentationModel(order))
                case .failure(error):
                    output.present(error:error.reason)
                }
            }
        }
        else {
            output.presentMissingMandatoryFields(productId: productId == nil, quantity: quantity == nil)
        }
    }
}
```

Implement `eventSave` as follows: 

```swift
class OrderEntryUseCase {
  
    let entityGateway: EntityGateway
    var output: OrderEntryUseCaseOutput!
    // init ...

    func eventSave() {

        let transformer = OrderEntrySaveUseCaseTransformer(orderManager: entityGateway.orderManager, userManager: entityGateway.userManager)
        transformer.transform(quantity: quantity, productId: productId, output: output)
    }
}
```

Implement the UseCase's `Capture` methods in the UseCase.

You will see that this setup makes it very easy to test the Transformer. It separates the UseCase's responsibilities from one another, making it very easy to understand the code. When you need to decompose a large amount of processing by implementing private methods, it is easy to ascertain the scope of the methods.

### The Presenter in the role of UseCaseOutput

The Presenter's second responsibility is to convert the data received a PresentationModel into a format called a ViewModel. The Presenter implements the UseCaseOutput protocol. 

The role of the Presenter as UseCaseOutput is to format the data received in the PresentationModel into a format that can be used directly by the ViewController. The formatted output is called a ViewModel. This usually means Strings, but depending on the requirements of the output controls, it may be an `enum` or a `Bool`.

If data must be localized, made accessible, or otherwise converted in any way, the process of conversion is done by the Presenter acting in the role of UseCaseOutput.

 A ViewModel can be implemented as an immutable struct or as a set of scalars, whichever is easier. When implemented as scalars, the values are passed directly as parameters to the methods of the PresentationOutput protocol. 

If an output method has a large number of parameters, it is better to put the values into a struct and then pass that as a parameter. In this case the conversion can take place in the `init` of the struct, instead of in the method itself.

When the input to the Presenter is repetitive, the Presenter holds the ViewModel structures in an array and delivers them via an indexed accessor method.

When the input to the Presenter is repetitive and heterogeneous, it is a good practice to use *associated-value* `enum`s to hold the data.  

A better practice is to extract a single value from the enum. This value is a name for a tuple. You can then use the field names defined by the enum to access the individual values stored in the enum. 

#### UseCaseOutput Examples

Here are some examples of output produced by the UseCase. The output is processed by the Presenter in the role of UseCaseOutput.

##### Initial Presentation of a Singular View

In the case of displaying a single Contact detail in a scene, the `present(contact:)` method calls the ViewController to show the contact's details.  If an error occurs, the presenter tells the ViewController to show an error message.

```swift
extension ContactPresenter: ContactViewReadyUseCaseOutput {
    
    func present(contact: ContactPresentationModel) {
        viewController.show(contact: ContactViewModel(contact: contact))
    }
  
    func present(error: ErrorReason) {
        viewController.show(error: NSLocalizedString(error.rawValue, nil))
    }
}
```

##### Initial Presentation of a Repetitive View

Here the output methods are used to construct a contact list for eventual display by the ViewController. When a ContactListPresentationModel is presented, it is converted to a ContactListViewModel and appended to the list. When no Contacts are found or an error occurs, a message is appended. When `presentContactListEnd()` is finally called, the ViewController is called to show the list.

```swift
extension ContactListPresenter: ContactListViewReadyUseCaseOutput {
    
    func presentContactListStart() {
        contactList = []
    }
    
    func present(contact: ContactListPresentationModel) {
        contactList.append(.contact(model:ContactListDetailViewModel(contact)))
    }

    func presentNoContactsFound() {
        contactList.append(.noContactsFound(message: NSLocalizedString("NoContactsFound", nil)))
    }
    
    func present(error: ErrorReason) {
        contactList.append(.error(message: NSLocalizedString(error.rawValue, nil)))
    }

    func presentContactListEnd() {
        output.showContactList()
    }
}
```

##### Data Capture

When presenting an Order, the Presenter just sends the data to the ViewController. The OrderEntryViewModel's `init` converts any data which must be localized or converted to text. 

If the user has missed entering one or more mandatory fields, the Presenter prepares the text describing the issue and then sends it to the ViewController.

```swift
extension OrderEntryPresenter: OrderEntrySaveUseCaseOutput {

    func present(order: OrderEntryPresentationModel) {
        viewController.show(order: OrderEntryViewModel(order: order))
    }
  
     func present(error: ErrorReason) {
        viewController.show(error: NSLocalizedString(error.rawValue, nil)))
    }

    func presentMissingMandatoryFields(productId: Bool, quantity: Bool) {

        var productIdMessage: String?
        var quantityMessage: String?

        if productId {
            productIdMessage = NSLocalizedString("Product must be Entered", nil)
        }
        if quantity {
            quantityMessage = NSLocalizedString("Quantity must be Entered", nil)
        }
        viewController.showManditoryFieldsMissing(productIdMessage: productIdMessage, quantityMessage: quantityMessage)
    }
}
```

### The ViewController in the role of PresenterOutput

The ViewController's second responsibility is to assign the data, obtained from the Presenter, into the Views.  The ViewController implements the PresenterOutput protocol.

The ViewController obtains from the Presenter's data in one of two ways, depending on whether the data is repeating or non-repeating. 

In the case of non-repeating data, the ViewController obtains the ViewModel data directly from the Presenter via a PresenterOutput method, either as individual parameter values or as an immutable struct parameter.

In the case of repeating data, the data is acquired from the Presenter via an indexed accessor method. The methods are used by a UITableView-, UIPicker-, UICollectionView- or other DataSource. The accessor method returns a ViewModel containing the data to be displayed

It is a good practice to create one PresenterOutput protocol for each event, for the same reason mentioned regarding the UseCaseOutput.

#### PresenterOutput Examples

Here are some examples of output coming from the Presenter and being processed by the ViewController in the role of PresenterOutput.

##### Initial Display of a Singular View

In the case of displaying a single Contact detail in a scene, the ViewController's `show(contact:)` method sets the contact details into their respective UIControls. Errors are presented by hiding the contactView and showing the errorView.

```swift
extension ContactViewController: ContactViewReadyPresenterOutput {
    
    func show(contact: ContactViewModel) {
      
        showView(error: false)
        contactNameLabel.text = model.contactName
        phoneLabel.text = model.phone
        addressLabel.text = model.address
        // ...
    }
  
    func show(error: String) {
      
        showView(error: true)
        errorLabel.text = error
    }
  
    private func showView(error: Bool) {
        contactView.isHidden = error
        errorView.isHidden = !error
    }
}


```

##### Initial Display of a Repetitive View

For the contact List example, there is only one ContactListPresenterOutput method to implement.

```swift
extension ContactListViewController: ContactListPresenterOutput  {

    func showContactList() {
        tableView.reloadData()
    }
}

```
But, this is not the whole story. The tableView requires a dataSource and, optionally, a delegate. Below, the ContactListAdapter implements a UITableViewDataSource and  UITableViewDelegate.

```swift
class ContactListAdapter: NSObject {
    var presenter: ContactListPresenter!
}

extension ContactListAdapter: UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: presenter.cellId(at: indexPath.row), for: indexPath)
        (cell as! ContactListCell).show(row: presenter.row(at: indexPath.row))
        return cell
    }
}

extension TransactionListAdapter: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return presenter.cellHeight(at: indexPath.row)
    }
}
```
We also have to implement methods in the Presenter to access the ViewModels required to create the cells.
```swift
// in ContactListPresenter
var rowCount: Int { return contactList.count }

func row(at index: Int) -> ContactListViewModel { 
    return contactList[ index ] 
}

func cellId(at index: Int) -> String {
    return contactList[ index ].cellId
}

func cellHeight(at index: Int) -> CGFloat {
    return contactList[ index ].height
}
    
```
And of course we have to implement the cells.

```swift
protocol ContactListCell {
    func show(model: ContactListViewModel)
}

class ContactListDetailCell: UITableViewCell, ContactListCell {
    
    @IBOutlet var contactNameLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!

    func show(model: ContactListViewModel) {
        guard case let .contact(model) = row else { fatalError("Expected: contact") }
        
        contactNameLabel.text = model.contactName
        phoneLabel.text = model.phone
    }
}

class ContactListErrorCell: UITableViewCell, ContactListCell {
    
    @IBOutlet var errorLabel: UILabel!

    func show(model: ContactListViewModel) {
        guard case let .error(message) = row else { fatalError("Expected: error") }
        errorLabel.text = message
    }
}
```

##### Data Capture

Besides showing the successfull result, the data capture PresenterOutput shows error messages for mississing mandatory fields. Note that this different than showing an error due to network failure.

```swift
extension OrderEntryViewController: OrderEntrySavePresenterOutput {

    func show(order: OrderEntryViewModel) {
        
        showView(error: false)
      	hideErrorMessages()
        // ...
        itemTotalLabel.text = order.itemTotal
        taxLabel.text = order.tax
        orderTotalLabel.text = order.orderTotal
	    // ...
    }
  
    func showMissingMandatoryFields(productIdMessage: String?, quantityMessage: String?) {

        showView(error: true)

        if let productIdMessage = productIdMessage {
            productIdMessageLabel.isHidden = false
            productIdMessageLabel.text = productIdMessage
        }
        if let quantityMessage = quantityMessage {
            quantityMessageLabel.isHidden = false
            quantityMessageLabel.text = quantityMessage
        }
    }
}
```

### The Connector

You may be wondering how each VIPER stack is created.

A ViewController is normally defined via Interface Builder, so we cannot use its `init`. Usually the ViewController allocates everything it needs, but: 

We do not want the ViewController to know anything about the Interactor. The Interactor must exist before the presenter can own it. The Presenter must exist before the ViewController can own it.

 The VIPER stack is assembled by a 3rd party class that knows about all of the classes in the stack and how they are connected together. This class is called a Connector.

A Connector is created and executed by the ViewController by overriding `awakeFromNib()`, which is called after all outlets are created.

The connector should also set the value of the Presenter into any classes which act as proxy to the ViewController.  This includes the UITableViewDataSource, UIPicker-, UICollectionView- or other DataSources.

Here is an example: 

```swift
class TransactionListConnector {
    
    private let viewController: TransactionListViewController
    private let adapter: TransactionListAdapter
    private let presenter: TransactionListPresenter
    private let useCase: TransactionListUseCase
    
    init(viewController: TransactionListViewController, adapter: TransactionListAdapter, useCase: TransactionListUseCase, presenter: TransactionListPresenter) {
        
        self.viewController = viewController
        self.adapter = adapter
        self.useCase = useCase
        self.presenter = presenter
    }
    
    convenience init(viewController: TransactionListViewController, adapter: TransactionListAdapter, entityGateway: EntityGateway = EntityGatewayImpl()) {
        
        let useCase = TransactionListUseCase(entityGateway: entityGateway)
        let presenter = TransactionListPresenter(useCase: useCase)
        
        self.init(viewController: viewController, adapter: adapter, useCase: useCase, presenter: presenter)
    }
    
    func configure() {
        viewController.presenter = presenter
        adapter.presenter = presenter

        useCase.output = presenter
        presenter.output = viewController
    }
}
```

## Summary

The easiest way to determine that you are implementing the VIPER architecture correctly is to use the rules and classes correctly and consistently. 

VIPER is easy to implement if you keep it simple.  

The benefit of VIPER is the organizational lever it provides for a project. Everything has a place. Each team member knows the rules and purposes of the classes in the VIPER stack. This makes everyone happy! 

I think that VIPER is the perfect architecture for large codebases with frequently changing requirements. It is definately an effective tool for alleviating the Massive ViewController problem.

In my next blog I will demonstrate an implementation of VIPER using the Banking Report from the last [post](/Solving-a-Complex-UITableView-using-Swift).



