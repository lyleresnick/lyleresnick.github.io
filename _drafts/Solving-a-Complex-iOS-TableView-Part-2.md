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

In reality, the view controller normally ends up being a repository of all of the code that the view controller is dependent on, including aspects such as:

- data access, local or remote

- data conversion, from source or to display

- data transformation, such as grouping, summarizing or other more complex tasks

## Introducing the Transformer Class

In part 1, the viewController has a function named`transformFromTwoSources`. I have moved the implementation of the function to a class, `TransactionListTwoSourceTransformer`,  in its own file.

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

 Lets look at the `TransactionListTwoSourcesTransformer`:

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

Besides encapsulating the code responsible for the transformation, `TransactionListTwoSourcesTransformer` has a few other significant changes:

- the data is passed into the class at initialization. This is done so that it is easier to setup tests for the transformer.
- the type of the group has been encapsulated by the Group class 