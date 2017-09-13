---
layout: post
title: "Solving a Complex UITableView Using the VIPER Architecture"
date: 2017-09-03
---

## Introduction

VIPER is a micro-architecture - a set of classes that work together to structure a solution.  

VIPER is an implementation of [Bob Martin's Clean Architecture](https://8thlight.com/blog/uncle-bob/2012/08/13/the-clean-architecture.html). I'm going to demonstrate that VIPER can be very simple to implement and its benefits can be realized very quickly.  

I'll use the requirement and solution to the Complex UITableView from [part 1]({{site.url}}/blog/2017/05/13/Solving-a-Complex-UITableView.html) of this series as the basis of this example. I will refactor the solution of [part 2]({{site.url}}/blog/2017/06/29/Solving-a-Complex-UITableView-Part-2.html) in to a solution as it would be rendered in VIPER. The complete App which demonstrates this refactoring can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo).

I discussed how I think VIPER should be structured in [A Crash Course on the VIPER Architecture]({{site.url}}/blog/2017/08/29/A-Crash-Course-on-the-VIPER-Architecture.html).

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
```
I have made three additions. 
- I overrode `awakeFromNib()` , 
- I added a property called `presenter`, and
- I added a method called `showReport`, which I will discuss later.

I made one more very significant change: the ViewController is no longer responsible for knowing where the data comes from. 

Storyboards are a very important part of my workflow because of their visual layout and resulting documentation. Even though I'm implementing VIPER, I definitely want to continue using Storyboards to define ViewController layouts.

`awakeFromNib()` is called immediately after the ViewController is constructed and the outlets are set. This is the perfect place to call the Connector to configure the remainder of the VIPER stack. 

As I mentioned previously, the VIPER stack must be configured, or more specifically, connected. I have allocated the configuration responsibility to a class I call the Connector.

You might have noticed that the `presenter` property has not been set. This is because it will be set by the Connector.

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

With a view toward testability, I decided to inject the UseCase into the Presenter, as well. Because the adapter is part of the view, it also needs a reference to the presenter.  

### The Presenter

In the previous version, the adapter had two responsibilities: convert the data into a format suitable for display by the view and to react to the tableView's requests by delivering cells containing the formatted data. The former responsibility has been moved to the Presenter.

I changed the name of the rows by calling them `TransactionListViewModel`s, because this is the what they are known as in VIPER.  

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
        useCase.eventViewReady()
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

### The UseCase 

As mentioned before, VIPER's UseCase actually implements the business logic - well normally. Subject to the SRP, I have further delegated the work to a transformer.

```swift
class TransactionListUseCase {

    weak var output: TransactionListUseCaseOutput!
    private let entityGateway: EntityGateway
    
    init(entityGateway: EntityGateway) {
        self.entityGateway = entityGateway
    }
    
    func eventViewReady() {
        
        let transformer = TransactionListViewReadyTwoSourceUseCaseTransformer(transactionManager: entityGateway.twoSourceManager)
        transformer.transform(output: output)
    }
}
```

The use case's two methods are exactly the same as the two methods found in the ViewController of the previous version. As you already know from the previous post, they do almost exactly the same thing - we are using the `eventViewReady` method, now. I will discuss the `eventViewReadyOneSource` method another day.

You can see that the injected EntityGateway provides some opaque indirection w.r.t. the access of the transactions, whereas in the previous version, the transactions where accessed from a known location. Here, only the EntityGateway knows where they are located. 

### The Transformer 

Except for some cosmetic naming changes, the Transformer called by the UseCase is identical to the previous version. 

The naming of the output protocol have been changed to align it with the VIPER structure. The `TransactionListTransformerOutput` protocol is now called the `TransactionListViewReadyUseCaseOutput` protocol and the `append` methods have been renamed to `present` methods.

You will notice that I added two methods to the protocol: `presentInit()` and `presentReport()`. In real world situations, you might generate the report a number of times to, say, keep it up to date. In the previous version, it was assumed that it would not be regenerated.

```swift
protocol TransactionListViewReadyUseCaseOutput: class {
    
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
class TransactionListViewReadyTwoSourceUseCaseTransformer {
    
    private let transactionManager: TwoSourceManager

    init(transactionManager: TwoSourceManager) {
        self.transactionManager = transactionManager
    }
    
    func transform(output: TransactionListViewReadyUseCaseOutput) {
        
        output.presentInit()

        var grandTotal = 0.0
        grandTotal += transform(transactions: transactionManager.fetchAuthorizedTransactions(), group: .authorized, output: output)
        grandTotal += transform(transactions: transactionManager.fetchPostedTransactions(), group: .posted, output: output)
        output.presentGrandFooter(grandTotal: grandTotal)

        output.presentReport()
    }

    private func transform(transactions: [TransactionEntity]?, group: TransactionGroup, output: TransactionListViewReadyUseCaseOutput) -> Double {
        
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
                        output.presentDetail(description: localTransaction.description, 
                                             amount: localTransaction.amount)
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

Except for the names and use of entity managers to access the data, the code here is identical to the previous version.

### The UseCaseOutput 

The UseCaseOutput is composed of all of the *Event*UseCaseOutputs.

As I mentioned earlier, the data formatting responsibility has been moved from the Adapter to the Presenter.  

All conversion to text is handled by the UseCaseOutput. If we were required to perform localization, it would be done here as well. In the previous version there is still data conversion being performed in the header cell.

`presentInit()` makes sure everything is reset and `presentReport()` tells its output to show the report.

```swift
extension TransactionListUseCaseOutput: TransactionListViewReadyUseCaseOutput {}

extension TransactionListPresenter: TransactionListViewReadyUseCaseOutput {
    
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

The TransactionListViewModel extension has been moved from the Adapter to the Presenter and has been made private, since that is the only class that needs to know about it.

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

The PresenterOutput is composed of all of the *EventPresenter*Outputs

The `TransactionListViewReadyPresenterOutput` is simple. 

```swift
protocol TransactionListPresenterOutput: TransactionListViewReadyPresenterOutput {}

protocol TransactionListViewReadyPresenterOutput: class {
    func showReport()
}
```

It simply tells the table to reload.

```swift
extension TransactionListViewController: TransactionListPresenterOutput {}

extension TransactionListViewController: TransactionListViewReadyPresenterOutput {
    
    func showReport() {
        tableView.reloadData()
    }
}
```

The reload makes the adapter start pulling data from the presenter.

### The Adapter

The size of the Adapter is now as small as possible. It's only responsibility is to react to the tableView by delegating to the presenter. It is now truly an *adapter*. The responsibility of output formatting was moved to the Presenter.  

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

The cells are exactly the same as the previous version, except the header cell is no longer performing calculations. 

The thing that is important about the cells is that they do no calculations whatsoever. They simply assign data to their views. 

## Summary 

As you may have noticed, the function of the app is identical to the previous version, but there are two major differences: 

- the place where each kind of processing occurs has been formalized and
- the names of each method have been formalized.

This formality makes it easier for those with the same background to understand the code and therefore makes it easier to change.

There are more classes: each one has very specific responsibilities.

The biggest change is that the responsibility for creation and storage of the ViewModels has been moved from the table Adapter to the UseCaseOutput, A.K.A. the Presenter. The Adapter is now solely responsible for attaching the TableView to the Presenter

Another major change is that the ViewController has no idea where its data is coming from. Only the UseCase knows that it comes from the EntityGateway.

The Transformer has remained identical to the previous version except for changes involving:

- use of formalized names and 
- formalizing access to data via entity managers.

As we will see in the next article, this deconstruction of the ViewController makes it very easy to practice Test Driven Development.

