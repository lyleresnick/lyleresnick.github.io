---
layout: post
title: "Solving a Complex iOS TableView Part 2"
date: 2017-05-13
---

## Introduction

In part 1, I introduced a solution to solve A Complex tableView.

In part 2, I want to improve the Complex iOS TableView solution to simplify the code in three ways:

- remove more responsibilities from the ViewController,
- take advantage of a few key Swift features, and
- redistribute the conversion of both the input and output data.



## Responsibilities of the ViewController 

The main responsibility of a viewController is to configure the layout and content of its associated views  and respond  to user interaction with those views. Pretty straightforward.

In reality, most view controllers end up being a repository of all of the code that the view controller is dependent on, including aspects such as:

- data access, local or remote

- data conversion, from source or to display

- data transformation, such as grouping, summarizing or other more complex tasks

## Introducing the Transformer Class

In part 1, the viewController has a function named`transformFromTwoSources`. I have moved the implementation of this function to a class, `TransactionListTwoSourceTransformer`.

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
        
        let transformer = TransactionListTwoSourceTransformer(authorizedData: TransactionModel.authorizedData,
                                                              postedData: TransactionModel.postedData)
        transformer.transform( output: adapter )
    }
}
```

You may have noticed that the viewController just got really small! It is only responsible for its views.

Before we take a look at the `TransactionListTwoSourceTransformer`, lets look at the `TransactionModel` and TransactionGroup classes.

## The Models

The `TransactionGroup` enum demonstrates an idiom for representing data whose values are part of a set. An `enum` can be based on an integer or string type. Every enum based on a raw type automatically generates an `init?(rawValue:)` initializer to convert a raw value to an internal value. 

Using the enum rawValue initializer is great a way to check the validity of externally stored data which actually represents an enumerated type such as a set of state names, a set of configuration values, or as in in our case, and encoding for a sign. The initializer is fail-able, so invalid data can be dealt with at conversion, instead of at a later stage of processing. In particular, the swift compiler will check that  `switch` statements that switch on enumerated types are exhaustive, so if a new external type is added in the future, the code will not compile if the new case is not added to the `switch`.  

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

In the original `TransactionModel` , each data value was stored as a string. Unless a value is supposed to be a string, you have to be convert a string to its primitive type to do a calculation. 

In the new `TransactionModel`, the data is stored as its primitive type. The Data is not converted in the transformer, before it is used in calculations.  The `TransactionModel` class now has the responsibility to perform any necessary conversions which are required to convert the external representation to the new internal representation. Previously, this was the responsibility of the transformation function. 

You can see that the `TransactionModel.init` converts:

- a group string into a group value
- a date string into a date value
- a debit indicator and an amount string into double value

Here a conversion error results in fatal error, but alternatively, you might make the init fail-able or you get more specific by throwing an error.

It is easy to see that another `convenience init` for this class could take json as an argument and pass the parsed elements to this `init`. 


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

Now lets look at the `TransactionListTwoSourceTransformer` class:

## The Transformer

```swift
import UIKit

class TransactionListTwoSourceTransformer {

    private let authorizedData: [TransactionModel]?
    private let postedData: [TransactionModel]?

    init( authorizedData: [TransactionModel]?, postedData: [TransactionModel]?) {
        self.authorizedData = authorizedData
        self.postedData = postedData
    }

    func transform(output: TransactionListTransformerOutput) {

        var grandTotal = 0.0
        grandTotal += transform( transactions: authorizedData, group: .Authorized, output: output)
        grandTotal += transform( transactions: postedData, group: .Posted, output: output )
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
                    
                    while let localTransaction = transaction, localTransaction.date == currentDate {
                        
                        let amount = localTransaction.amount
                        total += amount
                        output.appendDetail(description: localTransaction.description, amount: amount)
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

Previously, the data transformation was implemented as a viewController method. It has now been implemented as a *method object*. 

Besides encapsulating the code responsible for the transformation, `TransactionListTwoSourcesTransformer` has a few other significant changes:

- the data is passed into the class at initialization. This was done to make it easier to setup tests for the transformer .
- the group types have been encapsulated by the Group class. 
- the responsibility for conversion of input data has been moved to the `TransactionModel` class. 
- the responsibility for conversion of output data has been moved to the implementor of the `TransactionListTransformerOutput` class. 
- the iterator on the array of transactions has been formalized, by using an `IndexingIterator`.


These changes leave the `TransactionListTwoSourceTransformer` with one responsibility: convert the primitive data input to the primitive output that is necessary to fulfill the requirement of the transformation

. 





