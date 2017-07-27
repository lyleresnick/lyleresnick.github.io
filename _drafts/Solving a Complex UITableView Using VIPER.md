---
layout: post
title: "Solving a Complex UITableView Using VIPER"
date: 2017-06-09
 
---

## Introduction

VIPER is a micro-architecture - a set of classes that work together to structure a solution.  

VIPER is an implementation of [Bob Martin's Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html). I'm going to demonstrate that VIPER can be very simple to implement and its benefits can be realized very quickly.   

I'll use the requirement and solution to the Complex UITableView from the last [post]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView-Part-2.html) as the basis of this example.

The complete app which demonstrates this refactoring can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo).

## VIPER Explained

The purpose of the VIPER architecture is to reduce the amount of code in a ViewController class. VIPER does this by distributing the most of code of the ViewController into other classes that have specific responsibilities. You may recall that this echoes the Single Responsibility Principle. 

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

As you can see in the diagram, the Presenter has another role, again which, I will cover later.

### The UseCase

The UseCase, known in VIPER as the Interactor, has one responsibility: execute the application use case defined for the event. Upon receiving an event, the UseCase may use the EntityGateway to access the system state in the form of Entities, process the Entities with the incoming parameters, and may update the system state via the EntityGateway.

The results of executing the UseCase are passed as output to the UseCaseOutput protocol. 

Even when the Entities do not require processing to create the required output, they are never passed directly to the UseCaseOutput. The results are passed in a form known as the PresentationModel. The Presentation Model contains only the data that will be required for the output display. The data is not converted for output. 

A presentation model can be passed as a struct or as simple scalars - whatever is most convenient.

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

**TODO: Fix me:** The Presenter's second responsibility is to process the data received via UseCaseOutput. The Presentor decides whether to send the data on to the PresentorOutput or to the RouterOutput. 

When sending data on to the PresenterOutput, it is converted to a format that is most convenient for display by the ViewController. When sending data on to the RouterOut, it is passed unconverted.  

Data that is passed to PresentorOutput is called a ViewModel. In the case of repeating data the Presenter hold the viewModel structures and delivers them via an index method call.



I find that it is a good practice to create one output protocol for each event. As the number of use cases that a scene supports grows large, the number of methods  on a single output protocol becomes unwieldy, as it is really hard to tell which methods are used by what events. This works out really nicely when you place the implementation of each output protocol in it's own extension.

### 

### The ViewController as Presenter Output

The ViewController has one other VIPER responsibility: set data, which is obtained from the Presenter, into the views.  The Presenter sends data to the ViewController via the PresenterOutput protocol. The ViewController implements the protocol by  displaying the data received from the Presenter via the methods of protocol.

You can see that a VIPER ViewController has only one responsibiliy: configure Views and set data into them.

Note that this set up makes it very easy to reskin a ui.

### 



### The Connector

You may be wondering how this stack of classes is created.

A ViewController is normally defined via IB, so we cannot use its init. Usually the ViewController allocates everything it needs, but: 

We do not want the ViewController to know anything about the Interactor. The Interactor must exist before the presenter can  own it. The Presenter must exist before the ViewController can own it.

 The VIPER stack is assembled by a 3rd party class that knows about all of the parts in the stack and how they are connected together. I have called this part the connector.

The Connector is created and executed by the ViewController by overriding `awakeFromNib()`, which occurs after all outlets are created.

### 



## The App

You will see that to implement the solution as a VIPER module one must simply refactor what we have done so far.

### The ViewController

As you can see the amount of code in the ViewController is very small. There is one call to the presenter. This call represents the event that the view is ready to receive output. It does not intimate what the presenter is supposed to do, only that the event occurred. This is an example of forwarding, or a.k.a. *delegation* or *passing the buck*.
```swift
class TransactionListViewController: UIViewController {

    var presenter: TransactionListPresenter!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet private weak var adapter: TransactionListAdapter!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        TransactionListConnector(viewController: self, adapter: adapter).configure()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.eventViewReady()
    }
}

extension TransactionListViewController: TransactionListPresenterOutput {
    
    func showReport() {
        tableView.reloadData()
    }
}
```
I have made three additions. 
- I overrode `awakeFromNib()` , 
- i added a property called `presenter`, and
- i added a method called `showReport`, which I will discuss later.

As I mentioned previously, the VIPER stack must be configured, or more specifically, connected. I have allocated the configuration responsibility to a class I call the Connector.

Storyboards are a very important part of my workflow because of their visual layout capabilities and documentative qualities. Even though I'm implementing VIPER, I definitely want to continue using storyboards to define ViewController layouts.

`awakeFromNib()` is called immediately after the ViewController is constructed and the outlets are set. This is the perfect place to call the Connector to configure the remainder of the VIPER stack. 

You might have noticed that the presenter property has not been set. This is because it will be set by the Connector.

### The Connector

You might be wondering why the VIPER stack has to be configured by a third party. It will become obvious when you look at the code. Remember that part of the requirement of the clean architecture is that it must be testable. 

Certainly, you could arrange for the ViewController to directly allocate the Presenter and then have the ViewController set the presenter's viewController as a delegate. This is pretty normal stuff. In the same way the Presenter could directly allocate the UseCase and then have the Presenter set the UseCase's presenter as a delegate. 

But what about the EntityGateway? Should we directly allocate this as well? Having the UseCase directly allocatie the EntityGateway violates the rule that states: names of classes in the outer layer should not be known by classes of the inner layers. The only way to make this happen is to inject the EntityGateway into the UseCase. 

The next question is: who should perform the injection? If the presenter does it, the rule is still violated. In fact none of the classes in the stack can perform the injection without violating the rule.

This is why the Connector has to do the injection of the EntityGateway into the UseCase.

```swift
class TransactionListConnector {
    
    private let viewController: TransactionListViewController
    private let adapter: TransactionListAdapter
    private let presenter: TransactionListPresenter
    private var useCase: TransactionListUseCase
    
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

With a eye toward testability, I decided to inject the UseCase into the Presenter, as well. Because the adapter is part of the view, it also needs a reference to the presenter.  

### The Presenter

In the previous version, the adapter had two responsibilities: format the data into a format suitable for display by the view and to react to the tableView's requests by delivering cells containing the formatted data. The former responsibility has been moved to the Presenter.

I changed the name of the rows by calling them `TransactionListViewModel`s, because this is the what they are.  In general, any form of data that passed between the Presenter and the ViewController, is a ViewModel. It does not matter whether the data is grouped into a struct, an enum, a bunch of parameters, or a struct embedded in an enum, they are all just ViewModels in VIPER parlance. 

My preference is that, other than at init, ViewModels have no behaviour. In many cases, it is prudent to use init to translate a PresentationModel into a ViewModel.

The same thinking applies to PresentationModels, which I will discuss later.

```swift
class TransactionListPresenter {
    
    weak var output: TransactionListPresenterOutput!
    
    fileprivate static let outboundDateFormatter = DateFormatter.dateFormatter( format: "MMM' 'dd', 'yyyy" )

    fileprivate var rows = [TransactionListViewModel]()
    fileprivate var odd = false
    
    private let useCase: TransactionListUseCase
    
    init(useCase: TransactionListUseCase) {
        self.useCase = useCase
    }

    func eventViewReady() {
        useCase.begin()
    }
    
    func cellId(at index: Int) -> String {
        return rows[ index ].cellId
    }
    
    func cellHeight(at index: Int) -> CGFloat {
        return rows[ index ].height
    }
    
    var rowCount: Int { return rows.count }
    
    func row(at index: Int) -> TransactionListViewModel { return rows[ index ] }
}
```

The presenter takes the ViewReady event and passes it on to the UseCase. This is an extremely trivial Presenter in terms of events. Most Presenters respond to many more user generated events after `eventViewReady` which are also passed to the UseCase. 

In some circumstances, the Presenter will pass an event to a Router to access other ViewControllers.

All messages moving towards the UseCase (towards the centre of the architecture model) begin with the word `event`.   

The other methods provide to access the viewModel. They have been extracted from the original adapter. They do not begin with the word `event`, as they are called by the ViewController to pull data from the Presenter. I talk more about this below. 

**TODO:** It does seem like there should be a protocol for row access 

### The UseCase 

As mentioned before, VIPER's UseCase actually implements the business logic - well normally. Subject to the SRP, I have further delegated the work to a transformer.

```swift
class TransactionListUseCase {

    weak var output: TransactionListUseCaseOutput!
    private let entityGateway: EntityGateway
    
    init(entityGateway: EntityGateway) {
        self.entityGateway = entityGateway
    }
    
    func begin() {
        
        let authorizedTransactions = entityGateway.fetchAuthorizedTransactions()
        let postedTransactions = entityGateway.fetchPostedTransactions()
        let transformer = TransactionListBeginTwoSourceUseCaseTransformer(
            authorizedTransactions: authorizedTransactions,
            postedTransactions: postedTransactions)
        transformer.transform(output: output)
    }
}
```

The use case's two methods are exactly the same as the two methods found in the ViewController of the previous version. As you already know from the previous post, they do almost exactly the same thing - we are using the `begin` method, now. I will discuss the `beginOneSource` method another day.

You can see that the injected EntityGateway provides some opaque indirection w.r.t. the access of the transactions, whereas in the previous version, the transactions where accessed from a known location. Here, only the EntityGateway knows where they are located. 

### The Transformer 

Except for some cosmetic naming changes, the Transformer called by the UseCase is identical to the previous version. 

The naming of the output protocol have been changed to align it with the VIPER structure. The `TransactionListTransformerOutput` protocol is now called the `TransactionListUseCaseOutput` protocol and the `append` methods have been renamed to `present` methods.

You will notice that I added two methods to the protocol: `presentInit()` and `presentReport()`. In real world situations, you might generate the report a number of times to, say, keep it up to date. In the previous version, it was assumed that it would not be regenerated.

```swift
protocol TransactionListUseCaseOutput: class {
    
    func presentInit()
    func presentHeader(group: TransactionGroup)
    func presentSubheader(date: Date)
    func presentDetail(description: String, amount: Double)
    func presentSubfooter()
    func presentFooter(total: Double)
    func presentGrandFooter(grandTotal: Double)
    func presentNotFoundMessage(group: TransactionGroup)
    func presentNoTransactionsMessage(group: TransactionGroup)
    func presentNotFoundMessage()
    func presentReport()
}
```

Remember that the `output` is connected to the Presenter, whereas previously it was connected to the adapter.  

```swift
class TransactionListUseCaseBeginTwoSourceTransformer {
    
    private let authorizedTransactions: [TransactionEntity]?
    private let postedTransactions: [TransactionEntity]?

    init(authorizedTransactions: [TransactionEntity]?, postedTransactions: [TransactionEntity]?) {
        self.authorizedTransactions = authorizedTransactions
        self.postedTransactions = postedTransactions
    }
    
    func transform(output: TransactionListUseCaseOutput) {
        
        output.presentInit()

        var grandTotal = 0.0
        grandTotal += transform(transactions: authorizedTransactions, group: .authorized, output: output)
        grandTotal += transform(transactions: postedTransactions, group: .posted, output: output)
        output.presentGrandFooter(grandTotal: grandTotal)

        output.presentReport()
    }

    private func transform(transactions: [TransactionEntity]?, group: TransactionGroup, output: TransactionListUseCaseOutput) -> Double {
        
        var total = 0.0

        output.presentHeader(group: group)
        
        if let transactions = transactions {

            if transactions.count == 0 {
                output.presentNoTransactionsMessage(group: group)
            }
            else {
                var transactionStream = transactions.makeIterator()
                var transaction = transactionStream.next()
                
                while let localTransaction = transaction {
                    
                    let currentDate = localTransaction.date
                    output.presentSubheader(date: currentDate)
                    
                    while let localTransaction = transaction,
                          localTransaction.date == currentDate {
                        
                        total += localTransaction.amount
                        output.presentDetail(description: localTransaction.description, amount: localTransaction.amount)
                        transaction = transactionStream.next()
                    }
                    output.presentSubfooter()
                }
                output.presentFooter(total: total)
            }
        }
        else {
            output.presentNotFoundMessage(group: group)
        }

        return total
    }
}
```

### The UseCaseOutput 

As I mentioned earlier, the data formatting responsibility has been moved from the Adapter to the Presenter.  

Since all data conversion is to be done in the Presenter as a response to the UseCaseOutput, all text is handled here. If we were required to perform localization, it would be done here as well. In the previous version there is still data conversion being performed in the header cell.

`presentInit()` makes sure everything is reset and `presentReport()` tells its output to show the report.

```swift
extension TransactionListPresenter: TransactionListUseCaseOutput {
    
    func presentInit() {
        rows.removeAll()
    }

     func presentReport() {
        output.showReport()
    }

    func presentHeader(group: TransactionGroup) {
        
        rows.append(.header(title: group.toString() + " Transactions"));
    }
    
    func presentSubheader(date: Date) {
        
        odd = !odd;
        rows.append(.subheader(title: formatDate(date: date), odd: odd))
    }
    
    fileprivate func formatDate(date: Date) -> String {
        return TransactionListPresenter.outboundDateFormatter.string(from: date)
    }
    
    func presentDetail(description: String, amount: Double) {
        
        rows.append(.detail(description: description, amount: amount.asString, odd: odd));
    }
    
    func presentSubfooter() {
        
        rows.append(.subfooter(odd: odd));
    }
    
    func presentFooter(total: Double) {
        
        odd = !odd;
        rows.append(.footer(total: total.asString, odd: odd));
    }
    
    func presentGrandFooter(grandTotal: Double) {
        
        rows.append(.grandfooter(total: grandTotal.asString));
    }
    
    func presentNotFoundMessage(group: TransactionGroup) {
    
        rows.append(.message(message: "\(group.toString()) Transactions are not currently available."))
    }
    
    func presentNoTransactionsMessage(group: TransactionGroup) {
        
        rows.append(.message(message: "There are no \(group.toString()) Transactions in this period" ));
    }
    
    func presentNotFoundMessage() {
        
        rows.append(.header(title: "All"))
        rows.append(.message(message: "Transactions are not currently available."))
    }
}

extension Double {
    var asString: String {
        return String(format: "%0.2f", self)
    }
}
```

The TransactionListViewModel extension has been moved from the Adapter to the Presenter, since that is the only class that needs it.

```swift
private extension TransactionListViewModel {
    
    var cellId: String {
        return {
            () -> CellId in
            switch self {
            case .header:
                return .header
            case .subheader:
                return .subheader
            case  .detail:
                return .detail
            case .message:
                return .message
            case .footer:
                return .footer
            case .grandfooter:
                return .grandfooter
            case .subfooter:
                return .subfooter
            }
        } ().rawValue
    }

    private enum CellId: String {
        case header
        case subheader
        case detail
        case subfooter
        case footer
        case grandfooter
        case message
    }

    var height: CGFloat {
        get {
            switch self {
            case .header:
                return 60.0
            case .subheader:
                return 34.0
            case .detail:
                return 18.0
            case .subfooter:
                return 18.0
            case .footer:
                return 44.0
            case .grandfooter:
                return 60.0
            case .message:
                return 100.0
            }
        }
    }
}
```

### The PresenterOutput 

The `TransactionListPresenterOutput` is simple:

```swift
protocol TransactionListPresenterOutput: class {
    func showReport()
}
```

It simply tells the table to reload.

```swift
extension TransactionListViewController: TransactionListPresenterOutput {
    
    func showReport() {
        tableView.reloadData()
    }
}
```

The reload makes the adapter start pulling data from the presenter.

### The Adapter

The size of the Adapter is now as small as possible. It's only responsibility is to react to the tableView by delegating to the presenter. It is now truly an *adapter*. The responsibility of output formatting has been moved the Presenter.  

```swift
class TransactionListAdapter: NSObject {
    
    var presenter: TransactionListPresenter!
}

extension TransactionListAdapter: UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: presenter.cellId(at: indexPath.row), for: indexPath)
        (cell as! TransactionListCell).show(row: presenter.row(at: indexPath.row))
        return cell
    }
}

extension TransactionListAdapter: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return presenter.cellHeight(at: indexPath.row)
    }
}
```

### The Cells

The cell are exactly the same as the previous version, except the header cell is no longer calculating its contents. 

There things that is important about the cells is that thy do no calculations whatsoever. They simply assign data to their views. 



## Summary 



