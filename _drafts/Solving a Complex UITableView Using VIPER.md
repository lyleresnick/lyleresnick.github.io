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

The purpose of the VIPER pattern is to reduce the amount of code in the ViewController(**V**) class by distributing it into other classes that have specific responsibilities. To understand VIPER you need to understand a bit about the the clean architecture.

![Bob Martin's Clean Architecture](https://8thlight.com/blog/assets/posts/2012-08-13-the-clean-architecture/CleanArchitecture-5c6d7ec787d447a81b708b73abba1680.jpg)

The diagram shows that

- the User Interface is in the outermost layer of the  system 
- the Entities are at the centre of the system
- the Business Rules exist in the layer which surrounds the entities
- the data store which provides the entities is outside the system
- the presentation conversion layer is placed in the middle between the user interface and business logic  layers

In VIPER, 

- the ViewController(**V**) represents the user interface. 


- the Presenter(**P**) represents the presentation conversion layer
- the Interactor(**I**), a.k.a the UseCase, represents the business rulelayer
- the Router(**R**), which has not been explained and 
- the EntityGateway(**E**) provides access to Entities and managers to operate on them

Here is a diagran showing the relationship of the VIPER classes.

![Diagram of VIPER classes]({{ site.url }}/assets/VIPER Class Diagram.png)

The ViewController owns a Presenter, which in turn owns an Interactor.  The ViewController sends messages to the Presenter, which in turn sends messages to the Interactor. 

The Interactor uses the EntityGateway to obtain access to EntityManagers.  EntityManagers are responsible for providing access to the Entities.

**TODO: FIXME:** The Clean Architecture mandates that dependencies can only be explicit in one direction - towards the centre. All other dependencies going away from the centre must be implemented as a dependency inversion, which means a protocol must be used.

Since VIPER is an implementation of the Clean Architecture, there a few rules to follow: 

1. dependencies can only be explicit in one direction - towards the centre. This means that messages flowing out of the centre must be sent to an interface (a.k.a. a Swift protocol). Classes in layers closer to the center cannot know the names of classes in Layers closer to the outside.
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

### The Transformer

The Transformer is not formally part of VIPER. I have found it useful to create one transformer for each event forwarded to the UseCase . As we will see, this makes is very easy to test the Transformer and separates out the UseCase's responsibilities.



### The Complete picture

**TODO: FIXME**: Another way to look at the processing stages is that the events with their arguments are combined with the state of the system, the system may be updated by the uses case and the results of the event are then given to the presenter, which localizes and formats the results for display by the viewController 



Here is a diagarm showing the event and information flow between the View Controller and the Entity Gateway

![Diagram of VIPER classes]({{ site.url }}/assets/VIPER UseCase Sequence.png)

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



