---
layout: post
title: "Solving a Complex iOS TableView Part 2"
date: 2017-06-01
---

## Introduction

In [part 1]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView.html), I introduced a solution for solving a complex tableView. In this article, I want to improve the solution by refactoring the code in three ways:

- remove even more responsibilities from the ViewController and distribute them into new or existing classes
- take advantage of a few key Swift features, namely failable enum initializers, enums with associated values, and extensions and
- redistribute the code which converts the input and output data.

The complete app which demonstrates this refactoring can be found at [**ReportTableDemo**](https://github.com/lyleresnick/ReportTableDemo).


## Responsibilities of the ViewController 

The main responsibility of a viewController is to configure the layout of its associated views and respond  to user interaction with those views. Pretty straightforward.

In reality, most view controllers end up being a monolithic repository of every bit of code that the view controller depends on, including aspects such as:

- data access, local or remote
- data conversion, from source or to display
- data transformation, such as grouping, summarizing or other more complex tasks

As you may have heard before, this is not known as the Massive ViewController problem.

## Introducing the Transformer Class

In part 1, the [`TransactionListViewController`](https://github.com/lyleresnick/ReportTableDemo/blob/master/ReportTableDemo/Scene/TransactionListViewController.swift) implemented a function named `transformFromTwoSources`. I have moved the implementation of this function to a class, `TransactionListTwoSourceTransformer`.

The viewController now looks like this: 

```swift
import UIKit

class TransactionListViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var adapter: TransactionListAdapter!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        transformFromTwoSources()
    }
    
    func transformFromTwoSources() {
        
        let transformer = TransactionListTwoSourceTransformer(
            authorizedTransactions: TransactionModel.authorizedTransactions,
            postedTransactions: TransactionModel.postedTransactions)
        transformer.transform( output: adapter )
    }
}
```

You may have noticed that the ViewController just got really small! It is now only responsible for its views and those are set up by Interface Builder. Actually, that is not completely correct - it knows where the data for the Transformer is coming from - that is actually a responsibility.

We will look at the `TransactionListTwoSourceTransformer`, but first, lets take a look at the `TransactionModel` and `TransactionGroup` classes.

## The Models

The `TransactionGroup` enum demonstrates an idiom for representing data whose values are part of a set. An `enum` can be based on an integer or string type. Every enum based on a raw type automatically generates an `init?(rawValue:)` initializer to convert a raw value to an internal value. 

The enum rawValue initializer is great a way to check for the validity of externally stored data that actually represents an exclusive set of values such as a set of application states, a set of configuration values, or, as in our case, an encoding for a sign. 

The initializer is *failable*, so invalid data can be detected early simply by converting it using the initializer. This removes the need to convert data at a later stage of processing, where one would prefer not to be dealing  with possible exceptions. 

As a bonus, when `switch` cases are an enumerated type, the swift compiler will check that the cases are exhaustive. When a new case is added in the future, the code will not compile if the new case is not added to the `switch`.  

```swift
enum TransactionGroup: String {
    
    case authorized = "A"
    case posted = "P"

    func toString() -> String {
        switch self {
        case .authorized:
            return "Authorized"
        case .posted:
            return "Posted"
        }
    }
}
```

In the original [`TransactionModel`](https://github.com/lyleresnick/ReportTableAdapterDemo/blob/master/ReportTableAdapterDemo/TransactionModel.swift), each data value was stored as a string. Generally, unless a value can be processed as a string, you will have to be convert it to its primitive type. By primitive, I mean in a form that I can be naturally processed, like a date, a decimal, or a URL.

In the new `TransactionModel`, the data is stored in its primitive form. Unlike in the  previous transformation function, the data is not converted in the transformer.  The `TransactionModel` class has been given the responsibility to perform any necessary conversions that are required to change the external representation to the new internal representation. 

The `TransactionModel.init` process all of the input strings to primitive types. It converts:

- a group string to a group value
- a date string to a date value
- a debit indicator and an amount string to double values

Here a conversion error results in fatal error, but alternatively, you might make the init failable or you can get more specific by throwing an error.

It is not hard to imagine that a  `convenience init` for this class could be created to take a JSON dictionary as an argument and pass the parsed elements to this `init`. 


```swift
struct TransactionModel {
    
    var group: TransactionGroup
    var date: Date
    var description: String
    var amount: Double
    
    private static let inboundDateFormatter = DateFormatter.dateFormatter( format:"yyyy'-'MM'-'dd")
    
    init( group: String, date: String, description: String, amount: String, debit: String ) {
        
        guard let group = TransactionGroup(rawValue: group) else {
            fatalError("Format of Group is incorrect")
        }
        self.group = group
        
        guard let date = TransactionModel.inboundDateFormatter.date( from: date )
            else {
                fatalError("Format of Transaction Date is incorrect")
        }
        self.date = date
        
        self.description = description
        
        var sign: String!
        switch debit
        {
        case "D":
            sign = ""
        case "C":
            sign = "-"
        default:
            fatalError("Format of Transaction Sign is incorrect")
        }
        
        guard let amount = Double(sign + amount)
            else {
                fatalError("Format of Transaction Amount is incorrect")
        }
        self.amount = amount
    }
}
```

## The Transformer

Previously, the data transformation was implemented as a viewController method. Here it is implemented as a *method object*. 

Besides encapsulating the code responsible for the transformation, `TransactionListTwoSourcesTransformer` has a few other significant changes:

- the data is passed into the class at initialization, instead of being accessed directly. This was done to make it easier to set up tests for the transformer.
- the group types have been encapsulated by the `TransactionGroup` class. 
- the responsibility for conversion of input data has been moved to the `TransactionModel` class. 
- the responsibility for conversion of output data has been moved to the `TransactionListAdapter`. 
- the iterator on the array of transactions has been replaced with an `IndexingIterator`.​

These changes leave the `TransactionListTwoSourceTransformer` with one responsibility: convert the primitive data input to primitive output by recognizing the date groupings and exceptions, as well as calculating a total and grand total. This is pretty simple. Actually, not quite: in a future post I let you in on how the code structure was designed!

```swift
class TransactionListTwoSourceTransformer {

    private let authorizedTransactions: [TransactionModel]?
    private let postedTransactions: [TransactionModel]?

    init( authorizedTransactions: [TransactionModel]?, postedTransactions: [TransactionModel]?) {
        self.authorizedTransactions = authorizedTransactions
        self.postedTransactions = postedTransactions
    }

    func transform(output: TransactionListTransformerOutput) {

        var grandTotal = 0.0
        grandTotal += transform( transactions: authorizedTransactions, group: .authorized, output: output)
        grandTotal += transform( transactions: postedTransactions, group: .posted, output: output )
        output.appendGrandFooter(grandTotal: grandTotal)
    }

    private func transform(transactions: [TransactionModel]?, group: TransactionGroup, output: TransactionListTransformerOutput ) -> Double {
        
        var total = 0.0
        output.appendHeader(group: group)
        
        if let transactions = transactions {
            
            if transactions.count == 0 {
                output.appendNoTransactionsMessage( group: group)
            }
            else {
                var transactionStream = transactions.makeIterator()
                var transaction = transactionStream.next()

                while let localTransaction = transaction {
                    
                    let currentDate = localTransaction.date
                    output.appendSubheader(date: currentDate)
                    
                    while let localTransaction = transaction,
                        localTransaction.date == currentDate {
                        
                        total += localTransaction.amount
                        output.appendDetail(description: localTransaction.description, amount: localTransaction.amount)
                        transaction = transactionStream.next()
                    }
                    output.appendSubfooter()
                }
                output.appendFooter(total: total)
            }
        }
        else {
            output.appendNotFoundMessage(group: group)
        }
        return total
    }
}
```



## The Adapter

The Adapter implements a significant change from the previous version. Previously, the Adapter Rows were implemented using structs - it now uses enums instead.

```swift
enum TransactionListRow {

    case header( title: String )
    case subheader( title: String, odd: Bool )
    case detail( description: String, amount: String, odd: Bool )
    case subfooter( odd : Bool )
    case footer( total: String, odd: Bool )
    case grandfooter(total: String )
    case message( message: String )
}
```

I find the enum notation more compact than structs. They preserve the comparable property that I previously wanted from the structs. I really like the that the enum *namespaces* the cases. When you use this kind of complex  solution to drive tableViews, there can be a lot of structs around with really long names. You need to have long names just to keep them unique and make it obvious to which ViewController stack they belong to.

You may be wondering where the `cellId` and `height` information has gone. Since each is a constant related to a given case, they have been implemented as a read only variables of the `TransactionListRow`.  Normally you would see them implemented within the enum. Here they have been moved to a private extension in the Adapter file, because the adapter is the only class that needs the information. The move also allows the `CellId` cases to continue to be private.

Notice that, here, `cellId` returns a `String`. In the previous version, it returned a `CellId`. The implementation of `cellId` is now completely private. It returns a closure which selects a `CellId` which is then converted to a string.

```swift
// in file TransactionListAdapter:

private extension TransactionListRow {

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

Except for the conversion to enums, the changes to the adapter are fairly insignificant. 

- The `append` methods still do the final conversion of the data to a form which is convenient to display. 
- The Adapter is no longer responsible for converting input data, such as the inboundDate, to primitive types, since that responsibility has been moved to the TransactionModel initializer. 
- The method extension on `Double` formalizes the conversion to string. It could have been implemented as a private method, but I prefer this syntactic sugar - it make it easier read at its usage. 
- the `UITableViewDataSource` implementation has hardly changed at all, save the `cellId` conversion

```swift
class TransactionListAdapter: NSObject {
    
    fileprivate var rowList = [TransactionListRow]()
    fileprivate var odd = false
}

// MARK: - TransactionTransformerOutput

extension TransactionListAdapter: TransactionListTransformerOutput {

    private static let outboundDateFormatter = DateFormatter.dateFormatter( format: "MMM' 'dd', 'yyyy" )

    func appendHeader(group: TransactionGroup ) {
        
        rowList.append(.header(title: group.toString()))
    }
    
    func appendSubheader( date: Date ) {
    
        odd = !odd;
        let dateString = TransactionListAdapter.outboundDateFormatter.string(from: date)
        rowList.append(.subheader(title: dateString, odd: odd))
    }
    
    func appendDetail( description: String, amount: Double) {
    
        rowList.append( .detail(description: description, amount: amount.asString, odd: odd));
    }
    
    func appendSubfooter() {
    
        rowList.append(.subfooter( odd: odd ));
    }
    
    func appendFooter( total: Double) {
    
        odd = !odd;
        rowList.append(.footer(total: total.asString, odd: odd));
    }
    
    func appendGrandFooter(grandTotal: Double) {
        
        rowList.append(.grandfooter(total: grandTotal.asString))
    }
    
    func appendNotFoundMessage(group: TransactionGroup) {
    
        rowList.append(.message(message: "\(group.toString()) Transactions are not currently available." ));

    }
    
    func appendNoTransactionsMessage(group: TransactionGroup) {
        
        rowList.append(.message(message: "There are no \(group.toString()) Transactions in this period" ));
    }
    
    func appendNotFoundMessage() {
        
        rowList.append(.header(title: "All"))
        rowList.append(.message(message: "Transactions are not currently available." ));
    }
}

// MARK: -

extension Double {
    var asString: String {
        return String(format: "%0.2f", self)
    }
}

// MARK: - UITableViewDataSource

extension TransactionListAdapter: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rowList.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = rowList[ indexPath.row ]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.cellId, for: indexPath)
        (cell as! TransactionListCell).bind(row: row)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TransactionListAdapter: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowList[ indexPath.row ].height
    }
}
```



## Summary

In this demo, the size of the ViewController was reduced to its bare minimum. It  contains only the code needed to call the transformer. The transformer is easy to test because the data is passed as a parameter at instantiation.

The input data was converted from `Strings` to its most useful primitive type and validated at instantiation of the TransactionModel. This was done so that it can be conveniently used in calculations. When the calculations are finished, the data is then converted into the form which is easiest to display in a view. The viewable data is finally placed in ViewModels implemented as enums, which can be directly displayed by the Adapter. 

The adapter has changed little from the previous version, even though the implementation of the rows has been changed from `struct` to `enum`.

