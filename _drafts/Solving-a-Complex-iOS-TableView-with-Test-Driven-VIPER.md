---
layout: post
title: "Solving a Complex iOS TableView with Test Driven VIPER"
date: 2017-07-05
---

## Introduction

In [part 3]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView-with-Test-Driven-VIPER.html) of this article, I showed how the solution of [part 2]({{site.url}}/blog/2017/06/29/Solving-a-Complex-iOS-TableView-Part-2.html) could very easily be refactored into a VIPER framework. In this article, I want to show how the solution would be constructed via Test Driven Development (TDD).

The complete app which demonstrates this refactoring can be found at [**CleanTDDReportTableDemo**](https://github.com/lyleresnick/CleanTDDReportTableDemo). The app which I will be refactoring can be found at [**CleanReportTableDemo**](https://github.com/lyleresnick/CleanReportTableDemo).

Some of the benefits of TDD are 

- a focus on classes which conform to the SRP make it easier to change the code in the future
- bugs are uncovered very early in the process so the code just works
- refactoring is safe because passing tests ensure that refactoring is done correctly 
- code is complete because there is no bias towards testing only the golden path
- for code driven by events from sensors, you do not have to rely on actual data from the sensors

I want to show you how VIPER helps you apply TDD. 

TDD employs unit testing to get the job done. In general, the hardest part of TDD is determining the size of a unit. With respect to iOS, the hardest part of unit testing is determining how to break a ViewController into testable units.  

Unit testing employs the idea of a System Under Test (SUT). You could also refer to it as a Class Under Test. A unit is a public method of a SUT. 

Breaking a ViewController into many coordinated classes is a practice which yields many *seam*s. A seam is a place in the code where one class sends a message to another class.

As you saw in part 3, by using the VIPER architecture, the structure of each View is already broken up in to many classes: the ViewController, the Presenter, the UseCase, the EntityGateway, the Router and the additional Transformer. Each one is an class with a very specific role. These classes comprise most of the SUTs we need to get the job done. It also presents a plethora of predetermined seams - just what we need.

The one thing that you need to know about TDD is that even though you write the tests first, you need to have an overall plan - VIPER starts you off with a macro-plan in which you can fit your own plan. Its kind of  like TDD and VIPER were made for one another. TDD drives your plan, it does not do the coding for you. 

## So Lets Get Started

The usual question is where do I start.  I find it interesting that once you get used to the TDD process you can start pretty much wherever you like - just find a seam. 

**TODO: add output images here** 

I want to remind you of what the major seams are that VIPER provides

**TODO: add interacton diagram here ** 

As the diagram shows VIPER provides seams between: 
- the ViewController and the Presenter
- the Presenter and the UseCase 
- the UseCase and the Transformer
- the Transformer and the EntityGateway 
- the Transformer and the Presenter 

That's alot of seams that have magically made themselves obvious - but there is one more that I want to mention. In situations where the ViewController contains a table, I can get one more seam when I further decompose the ViewController to introduce the Adapter. The new seams are found between: 
- the ViewController and the Adapter
- the Adapter and the Presenter 

For this demonstration I am going to work from the output because that is what defines the requirement in this case. 

I generally suggest that you start with the simplest tests you can do.



## TransactionListConnectorTests

In order to get the test rolling I'm going to create the major VIPER Classes and then make sure that I can connect them together.

**TODO: this should go into the non test version**

Whenever possible, I prefer to inject dependencies via the constructor as opposed to via a property, so that I am assured that the dependencies are set.  This is how I designed the Presenter and the UseCase. I could not design the ViewController and the Adapter this way because they are constructed by IB. I could have created the Adapter in code, but all other alternatives still require parameter injection of the presenter, due to timing of construction vs attachment to the table.

**TODO: ——-**



My first SUT is the `TransactionListConnector`. I try to create one in the test setup, but of course it will not compile because it does not exist. Since the purpose of the connector is to connect the ViewController, Adapter, Presenter and UseCase, I have to let the connector know about them and I choose to do this by  injection.

```swift
class TransactionListConnectorTests: XCTestCase {
    
    private var sut: TransactionListConnector!
    private var adapter: TransactionListAdapter!
    private var controller: TransactionListViewController!
    private var useCase: TransactionListUseCase!
    private var presenter: TransactionListPresenter!
    
    override func setUp() {
        super.setUp()
        
        controller = TransactionListViewController()
        adapter = TransactionListAdapter()
        useCase = TransactionListUseCase(entityGateway: FakeNilEntityGateway())
        presenter = TransactionListPresenter(useCase: useCase)
        
        sut = TransactionListConnector(viewController: controller, adapter: adapter, useCase: useCase, presenter: presenter)
    }
}
```

Knowing that I want to set the Connector's viewController to a ViewController, I  write the test the following test, which of course fails because there is no code. 

```swift
func test_Init_SetsSUTsViewController() {
      XCTAssertTrue(sut.viewController === controller)
}
```

I add the code to create a bare bones ViewController and pass it as a parameter to the SUT. I also add code to set the viewController property. I run the test and it passes. 

```swift
class TransactionListViewController: UIViewController {}
```
I then do the same thing with the Adapter, UseCase and Presenter.
```swift
    func test_Init_SetsAdapter() {
        XCTAssertTrue(sut.adapter === adapter)
    }
    
    func test_Init_SetsPresenter() {
        XCTAssertTrue(sut.presenter === presenter)
    }
    
    func test_Init_SetsUseCase() {
        XCTAssertTrue(sut.useCase === useCase)
    }
```

```swift
class TransactionListPresenter {
    private let useCase: TransactionListUseCase
    
    init(useCase: TransactionListUseCase) {
        self.useCase = useCase
    }
}
```

```swift
class TransactionListAdapter: NSObject {}
```

```swift
class TransactionListUseCase {
    private let entityGateway: EntityGateway
    
    init(entityGateway: EntityGateway) {
        self.entityGateway = entityGateway
    }
}
```
Since the EntityGateway is injected into the UseCase, I have to create a fake EntityGateway with fake data managers. This is will facilitate testing without having to rely on real data sources.

```swift
class FakeNilEntityGateway: EntityGateway {
    var twoSourceManager: TwoSourceManager = NilTwoSourceManagerImpl()
}

class NilTwoSourceManagerImpl: TwoSourceManager {
    
    func fetchAuthorizedTransactions() -> [TransactionEntity]? { return nil }
    func fetchPostedTransactions() -> [TransactionEntity]? { return nil }
}
```

I now have completed the init for the Connector and created all of the VIPER classes that I will be using.

```swift
class TransactionListConnector {
    
    let viewController: TransactionListViewController
    let adapter: TransactionListAdapter
    let presenter: TransactionListPresenter
    let useCase: TransactionListUseCase
    
    init(viewController: TransactionListViewController, adapter: TransactionListAdapter, useCase: TransactionListUseCase, presenter: TransactionListPresenter) {
        
        self.viewController = viewController
        self.adapter = adapter
        self.presenter = presenter
        self.useCase = useCase
    }
}
```

Note that the properties are not marked `private`. This is due to the fact that swift properties are not key-value coding compliant unless they are inherited from `NSObject`. Tests win over encapsulation.

Knowing that I want to set the ViewController's `presenter` to a Presenter, I write the following test, which of course will not compile because there is no code.  

```swift
    func test_Configure_SetsControllersPresenter() {
        XCTAssertTrue(controller.presenter === presenter)
    }
```

In order to make the test pass, I create a method on the SUT called `configure`, whose job will be to set all of the VIPER connections that cannot be connected via each class's `init`.  

```swift
    func configure() {
        viewController.presenter = presenter
    }
```

I call this method at the end of the `setUp` method.

```swift
        sut.configure()
```

I also have to add the property to ViewController property.

```swift
class TransactionListViewController: UIViewController {

    var presenter: TransactionListPresenter! 
}
```

The test passes.

I create 3 more tests, all of which cannot compile.

```swift
    func test_Configure_SetsAdaptersPresenter() {
        XCTAssertTrue(adapter.presenter === presenter)
    }
    
    func test_Configure_SetsUseCasesOutput() {
        XCTAssertTrue(useCase.output === presenter)
    }
    
    func test_Configure_SetsPresentersOutput() {
        XCTAssertTrue(presenter.output === controller)
    }
```

One by one, in tandem with the tests, I add the required properties to the classes and the tests all pass.


```swift
class TransactionListPresenter {
    
    weak var output: TransactionListPresenterOutput!
    private let useCase: TransactionListUseCase
    
    init(useCase: TransactionListUseCase) {
        self.useCase = useCase
    }
}

class TransactionListAdapter: NSObject {
    
    var presenter: TransactionListPresenter!
}

class TransactionListUseCase {

    weak var output: TransactionListUseCaseOutput!
    private let entityGateway: EntityGateway
    
    init(entityGateway: EntityGateway) {
        self.entityGateway = entityGateway
    }
}
```

Here is the competed configuration method:

```swift
// in Connector
  func configure() {
        viewController.presenter = presenter
        adapter.presenter = presenter
        presenter.output = viewController
        useCase.output = presenter
    }
```

At this point I want to mention that one usually only writes tests on the SUT, but in this case the SUT is configuring other classes and it is this very behaviour that we want to test.

I also want to mention that I understand how tedious this seems, since you would have to do it for every VIPER stack that you want to create. I think a better idea is to generate the stack from a template! 

Now that we have a place to put all of the code that we are going to write, lets move on to the output of the ViewController.

## Construction of The ViewController

Since the requirement is mostly about the output I start by drawing the output in IB: 

![IBLayout]({{ site.url }}/assets/IBLayout.png)

I covered the technique to produce this report in  [part 1]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView.html). There, you can also see the final [output]({{site.url}}/blog/2017/05/13/Solving-a-Complex-iOS-TableView.html#a-complex-requirement).

Here I want to demonstrate how to build out the app using tests.

### TransactionListViewControllerIBInjectionTests

I want to create a tableView, so the first test I write is:

```swift
 func test_IB_InjectsAllSutOutlets() {
      tableView = sut.value(forKey: "tableView") as! UITableView
      XCTAssertNotNil(tableView)
 }
```

 Of course this test cannot compile, so i add the code in setup to create the SUT.

```swift
    override func setUp() {
        super.setUp()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        sut = storyboard.instantiateViewController(withIdentifier: 
        	String(describing: TransactionListViewController.self) ) 
        		as! TransactionListViewController
        
        _ = sut.view
    }
```

This pulls the viewController (the SUT) out of the storyboard. Accessing the view causes the viewControllers `viewDidLoad()` to be called. Although the test  will compile, it crashes because there is no such storyboard. I create the storyboard, add a viewController of type `TransactionListViewController`,  add a tableView to it and create an outlet in the viewController.

```swift
    @IBOutlet fileprivate weak var tableView: UITableView!
```

I run the test and it passes. 

Notice I used key-value coding to access the outlet. This technique allows me to access the property value while still declaring the property private.

I want IB to allocate the adapter so I add a failing assertion to the existing test.

```swift
        XCTAssertNotNil(sut.value(forKey: "adapter"))
```

I add an object of type `TransactionListAdapter` to the tableView and  I create another outlet.

```swift
    @IBOutlet fileprivate weak var adapter: TransactionListAdapter!
```

I run the test and it passes. 

I want IB to attach the adapter to the table so I add two failing assertions to the existing test.

```swift
        XCTAssertNotNil(tableView.value(forKey: "dataSource"))
        XCTAssertNotNil(tableView.value(forKey: "delegate"))
```

I attach the two outlets of the tableView to the Adapter. The test fails because the Adapter does not yet implement the `UITableViewDataSource` and `UITableViewDelegate`. I implement as follows, returning dummy values where neccessary.

```swift
extension TransactionListAdapter: UITableViewDataSource  {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}

extension TransactionListAdapter: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
```

I run the test and it passes. The final test method looks like this:

```swift
func test_IB_InjectsAllSutOutlets() {

    tableView = sut.value(forKey: "tableView") as! UITableView
    XCTAssertNotNil(tableView)
    XCTAssertNotNil(sut.value(forKey: "adapter"))
    XCTAssertNotNil(tableView.value(forKey: "dataSource"))
    XCTAssertNotNil(tableView.value(forKey: "delegate"))
}
```

The ViewController now looks like this:

```swift
class TransactionListViewController: UIViewController {

    var presenter: TransactionListPresenter! 
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var adapter: TransactionListAdapter!
}
```

Next, I refactor the assignment to  `tableView`  up to `setUp()` and I create a failing test to dequeue the cells.

```swift
func test_tableView_CanDequeueAllCellIds() {
        
    for cellId in ["header", "subheader", "detail", "subfooter", "footer", "grandfooter", "message"] {

        let cell = tableView.dequeueReusableCell(withIdentifier: cellId)
        XCTAssertNotNil(cell, "Can't dequeue cellId: \(cellId)" )
    }
}
```

For each of the 7 required cells, I create a cell class for each row, draw each cell in IB and set its class and row identifier. Here is an example for the header cell:

```swift
class TransactionListHeaderCell: UITableViewCell {}
```

 I run the test and it passes. Next, I create a failing test to check the injection of the outlets of each cell class. Here is an example for the header cell:

```swift
    func test_IB_InjectsOutletsOfHeaderCell() {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "header") as! TransactionListHeaderCell
        let titleLabel = cell.value(forKey: "titleLabel")
        XCTAssertNotNil(titleLabel)
    }

```

Next I layout the required views into each cell and create and connect the respective outlets.

```
class TransactionListHeaderCell: UITableViewCell {
    
    @IBOutlet private var titleLabel: UILabel!
}
```

 I run the tests and they pass. 

### TransactionListCellTests

The next thing on the list of things to do is populate the cells with data. Even though each cell class can be considered an SUT, I decided put all of the cell tests into one file with a null setup.

I already know from my experience with VIPER that each cell will need a method to bind the data from a row to a cell. I'm going to call this method `show(row:)`. So … I write failing test.

```swift
func test_HeaderCell_show_SetsCorrectly() {

    let cell = TransactionListHeaderCell()
    cell.setValue(UILabel(), forKey: "titleLabel")

    cell.show(row: .header(title: testString))

    let titleLabel = cell.value(forKey: "titleLabel") as! UILabel
    XCTAssertTrue(titleLabel.text == testString)
}
```

This test will not compile because the cell does not have a method named `show` and neither is there an enum called  `.header`. 

First I introduce a protocol: 

```swift
protocol TransactionListCell {
    func show( row: TransactionListViewModel )
}
```

and a ViewModel: 

```swift
enum TransactionListViewModel {
    case header(title: String)
}
```

I then complete the cell implementation

```swift
class TransactionListHeaderCell: UITableViewCell, TransactionListCell {
    
    @IBOutlet private var titleLabel: UILabel!
    
    func show(row: TransactionListViewModel) {
        
        guard case let .header(title) = row else { fatalError("Expected: header") }
        titleLabel.text = title
    }
}
```

I run the test and it passes.  Now I write the next failing test, add the enum to the ViewModel, and complete the cell implementation. Remember that Each assert must pass before code is written to pass the next assert.

```swift
 func test_SubheaderCell_show_SetsCorrectly() {
        
        let cell = TransactionListSubheaderCell()
        cell.setValue(UILabel(), forKey: "titleLabel")
        
        cell.show(row: .subheader(title: testString, odd: true))
        
        let titleLabel = cell.value(forKey: "titleLabel") as! UILabel
        XCTAssertTrue(titleLabel.text == testString)
        XCTAssertTrue(cell.backgroundColor == 
        	UIColor(rgb: TransactionListSubheaderCell.oddBackgroundRGB))
    }
```

```swift
enum TransactionListViewModel {
    case header(title: String)
    case subheader(title: String, odd: Bool)
}
```

```swift
class TransactionListSubheaderCell: UITableViewCell, TransactionListCell {
    
    @IBOutlet private var titleLabel: UILabel!
    
    func show(row: TransactionListViewModel) {
        
        guard case let .subheader( title, odd ) = row else { fatalError("Expected: subheader") }
        titleLabel.text = title
        setBackgroundColour(odd: odd)
    }
}
```

The background colour setting will be used by almost all of the cells, so i added the method to the protocol: 

```swift
extension TransactionListCell where Self: UITableViewCell {
    
    static var oddBackgroundRGB: Int { return 0xF7F8FC }
    static var evenBackgroundRGB: Int { return 0xDDDDDD }

    func setBackgroundColour(odd: Bool ) {
        
        let backgroundRgb = odd ? Self.oddBackgroundRGB : Self.evenBackgroundRGB
        backgroundColor = UIColor( rgb: backgroundRgb )
    }
} 
```

I continued in the same manner for the rest of the 7 cells. You can view their implementations [here](https://github.com/lyleresnick/CleanTDDReportTableDemo/tree/master/CleanTDDReportTableDemo/Scenes/AccountDetailsTransactionList/View/Cells). Here is the final version of the ViewModel:

```swift
enum TransactionListViewModel {
    case header(title: String)
    case subheader(title: String, odd: Bool)
    case detail(description: String, amount: String, odd: Bool)
    case subfooter(odd : Bool)
    case footer(total: String, odd: Bool)
    case grandfooter(total: String)
    case message(message: String)
}
```

Here is the final set of cell tests:

```swift
class TransactionListCellTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    let testString = "TestString"
    let testString2 = "TestString2"
    
    func test_HeaderCell_show_SetsCorrectly() {
        
        let cell = TransactionListHeaderCell()
        cell.setValue(UILabel(), forKey: "titleLabel")
        
        cell.show(row: .header(title: testString))
        
        let titleLabel = cell.value(forKey: "titleLabel") as! UILabel
        XCTAssertTrue(titleLabel.text == testString)
    }
    
    func test_SubheaderCell_show_SetsCorrectly() {
        
        let cell = TransactionListSubheaderCell()
        cell.setValue(UILabel(), forKey: "titleLabel")
        
        cell.show(row: .subheader(title: testString, odd: true))
        
        let titleLabel = cell.value(forKey: "titleLabel") as! UILabel
        XCTAssertTrue(titleLabel.text == testString)
        XCTAssertTrue(cell.backgroundColor == 
        	UIColor(rgb: TransactionListSubheaderCell.oddBackgroundRGB))
    }
    
    func test_DetailCell_show_SetsCorrectly() {
        
        let cell = TransactionListDetailCell()
        cell.setValue(UILabel(), forKey: "descriptionLabel")
        cell.setValue(UILabel(), forKey: "amountLabel")
        
        cell.show(row: .detail(description: testString, amount: testString2, odd: true))
        
        let descriptionLabel = cell.value(forKey: "descriptionLabel") as! UILabel
        XCTAssertTrue(descriptionLabel.text == testString)
        
        let amountLabel = cell.value(forKey: "amountLabel") as! UILabel
        XCTAssertTrue(amountLabel.text == testString2)
        
        XCTAssertTrue(cell.backgroundColor == 
        	UIColor(rgb: TransactionListDetailCell.oddBackgroundRGB))
    }
    
    func test_FooterCell_show_SetsCorrectly() {
        
        let cell = TransactionListFooterCell()
        cell.setValue(UILabel(), forKey: "totalLabel")
        
        cell.show(row: .footer(total: testString, odd: false))
        
        let totalLabel = cell.value(forKey: "totalLabel") as! UILabel
        XCTAssertTrue(totalLabel.text == testString)
        XCTAssertTrue(cell.backgroundColor == 
        	UIColor(rgb: TransactionListFooterCell.evenBackgroundRGB))
    }
    
    func test_GrandFooterCell_show_SetsCorrectly() {
        
        let cell = TransactionListGrandFooterCell()
        cell.setValue(UILabel(), forKey: "totalLabel")
        
        cell.show(row: .grandfooter(total: testString))
        
        let totalLabel = cell.value(forKey: "totalLabel") as! UILabel
        XCTAssertTrue(totalLabel.text == testString)
    }
    
    func test_MessageCell_show_SetsCorrectly() {
        
        let cell = TransactionListMessageCell()
        cell.setValue(UILabel(), forKey: "messageLabel")
        
        cell.show(row: .message(message: testString))
        
        let totalLabel = cell.value(forKey: "messageLabel") as! UILabel
        XCTAssertTrue(totalLabel.text == testString)
    }
}
```











**TODO: figure out when to introduce the convenience init**