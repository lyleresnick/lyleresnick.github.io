---
layout: BlogPost
date: 2025-10-15 12:00
tags: SwiftUI
---

# Building Reusable Navigation in SwiftUI with Coordinators

Managing navigation in SwiftUI is easy for simple flows but quickly becomes messy as apps grow. Routing decisions end up in the screen view files, view models leak navigation logic, and flows become hard to follow.

To solve this, we can use a coordinator pattern: a centralized system that orchestrates navigation for a flow while keeping screens and view models clean, reusable, and testable.

The Coordinator pattern presented here is sometimes known as the Router pattern. 

---

##  Requirements of a Coordinator
Let make the requirements more concrete.

We would like a Coordinator to 

* manage the instantiation and presentation of screens of a multi-screen flow, and
* to sequence the presentation of screens according to business rules. 

The Coordinator should also have these qualities:

* logic implementing business rules should be confined to the coordinator,
* optionally, the first presented screen should be determined dynamically.,
* a screen managed within a flow must be reusable in another flow without change and

- a coordinator must be easy to create and use by the developer. 

## Meeting the requirements
### 1. Move Navigation and Flow Logic from The View to the Coordinator

In most SwiftUI codebases (as well as Flutter & Android for that matter) navigation code is located in  the View. 

This architecture implicitly couples the screen View code to both the implementation of the navigation system and to the flow in which the screen is presented. The flow is manifested in various places in the code of the screens. In some codebases, the viewModels are responsible for navigation, but this architecture still couples the Screen Module (the View and the ViewModel) to the navigation system and flow.

The way to decouple the navigation system and the flow from the screens is to give all of this responsibility to a third party object. Many people call this object a coordinator to imply that this object has responsibility for the coordination of the presentation of a group of screens. Some people, myself included, like to call it a Router, because it does the work of routing screens also referred to as Routes (routes also include parameters).

The View, and in turn the ViewModel, is given a reference to the Coordinator, as opposed to a being given a reference to a navigator or its implementation. The result is that the Coordinator is opaque to the Screen Module. The module does not even know the there is a navigator controlling the presentation.

### 2. Centralize Instantiation and Presentation

The coordinator's main responsibility is to instantiate and present the screens of a multi-screen flow. Think of the coordinator as the parent of the screens. The screens are children of the coordinator.

Only the coordinator knows about child screens. Knowledge of screen's siblings is not known directly by the screen, only the coordinator. This is the opposite of approaches where a View directly manipulates a reference to a navigator, imperatively telling the navigator what to do - as is commonly seen in UIKit, SwiftUI, Flutter or Android

Once a child screen has been instantiated, the coordinator waits for requests from the child and interprets them according to the business rules.

### 3. Encapsulate all Navigation Logic

In addition to centralizing instantiation and presentation, all navigation decisions are centralized. These decisions include the usual pushing and popping, and also decisions based on the state of the flow.

Instead of scattering logic across all of the Views or ViewModels of all of the Screen, the logic of the flow is contained within the scope of the coordinator, or more specifically, the CoordinatorViewModel.

This small scope makes it as easy as possible to understand and modify the flow in the future.

### 4. Separate Responsibilities within the Coordinator

A Coordinator should consist of two familiar parts: a View and a ViewModel. The View is called a CoordinatorView and the  ViewModel is called a CoordinatorViewModel. 

These type names are alway prefixed with the Flow Name.

The View contains only SwiftUI Navigation code and the ViewModel contains only business logic which controls the what View should present.

The View knows <u>how</u> and <u>what</u> to push and pop; whereas the ViewModel knows <u>when</u> and <u>why</u> to push and pop as directed by requests from the coordinator's children.

### 5. Separate Responsibilities within the Child Screen Modules
A View displays UI and responds to user interactions. The ViewModels handle business logic. Coordinators handle navigation and flow transitions.

The View does not decide which screen comes next and neither does the ViewModel — the ViewModel  makes requests to the Coordinator via a protocol specific to each Child Screen. The viewModel makes requests to the Coordinator in terms of what has happened and the Coordinator makes the routing decisions. The ViewModel does not tell the coordinator what to do.

### 6. Consistency Across a Flow
Special-case behavior, like resetting flow state after a transaction, moving back to a specific screen, or presentation of user state driven screens (like onboarding) happens centrally in the coordinator.
This ensures uniform behavior and eliminates duplicated or contradictory logic across screens.
In the simple case of navigation it’s just a push, pop or replace; but when some business rule must be followed, that logic is performed by the CoordinatorViewModel - not the child's view model.

### 7.  Maintainability and Scalability
Centralized navigation makes adding, removing, or reordering screens safe and straightforward.
As the app grows, changes to the flow only require updates in one place.

### 8. View Model-Driven Navigation
Once a child screen has been acted on by the user, its final state must be communicated back the coordinator that instantiated it.

All navigation decisions must originate from the view model.
Views react to commands like .push, .pop, or .replace, but never push or pop themselves.
This keeps the flow predictable and makes testing simple: you can verify navigation decisions without presenting any UI.

### 9. Protocol-Driven Screen Reuse
Screens communicate via protocols rather than knowing about the coordinator directly.
* Each screen gets a lightweight protocol exposing only the methods it needs.
* The child's ViewModel retains a reference to the coordinator and the coordinator implements the protocol. 
* This decouples the screen from the flow, making it reusable and easier to maintain.
* The same screen can be reused in multiple flows without modification.
### 10. Reusability



TODO: place this: This small scope combined with the use of the reusable NavigationViewModel makes it as easy as possible to understand and modify the flow in the future.



---
## Concrete Example: Login Flow
Here is an example of a real-world login flow. It makes use of a reusable coordinator for its implementation which we will discuss later.
### Coordinator View
```swift
struct LoginFlowCoordinator: View {
    @StateObject private var viewModel: LoginFlowCoordinatorViewModel

    init(coordinator: LoginFlowCoordinatorCoordinator? = nil) {
        viewModel = StateObject(wrappedValue: .init(coordinator: coordinator))
    }

    var body: some View {
        NavigatingCoordinatorView(viewModel: viewModel) { route, coordinator in
            switch route {
            case .login: LoginScreen(coordinator: coordinator)
            case .createAccount: 
                CreateAccountScreen(coordinator: coordinator)
            case let .emailVerification(email, requestId): 
                EmailVerificationScreen(email: email, requestId: requestId, coordinator: coordinator)
            case .getPassword: GetPasswordScreen(coordinator: coordinator)
            case .welcome: WelcomeSplashScreen(coordinator: coordinator)
            }
        }
    }
}
```
#### Key points

* The LoginFlowCoordinatorViewModel is a subclass of the CoordinatorViewModel as seen below.
* The LoginFlowCoordinatorCoordinator is the parent coordinator of the LoginFlowCoordinator - every child screen has a coordinator unless it is the root coordinator
* NavigatingCoordinatorView takes one parameter: a @ViewBuilder that can build the screens for each of the Routes in the LoginFlowCoordinatorViewModel
* Each screen receives a protocol-based coordinator, allowing them to be reused in other flows without modification.
* None of the Screens has knowledge of any other Screen

### Coordinator View Model

```swift
class LoginFlowCoordinatorViewModel: NavigatingCoordinatorViewModel&lt;LoginFlowCoordinatorViewModel.Route>,
    LoginCoordinator,
    CreateAccountCoordinator,
    EmailVerificationCoordinator,
    GetPasswordCoordinator,
    WelcomeCoordinator {
    enum Route: Hashable {
        case login
        case createAccount
        case emailVerification(email: String, requestId: String)
        case getPassword
        case welcome
    }

    private weak var coordinator: LoginFlowCoordinatorCoordinator?

    init(coordinator: LoginFlowCoordinatorCoordinator?) {
        super.init(initialRoute: .login)
        self.coordinator = coordinator
    }
      
    // Login
      
    func createAccountRequested() { 
      command = .push(.createAccount) 
    }
      
    func loginCompleted() {
        command = .replace(.welcome)
    }

    // CreateAccount
  
    func emailVerificationRequested(email: String, requestId: String) 
    { 
        command = .push(.emailVerification(email: email, requestId: requestId)) 
    }
      
    // EmailVerification 
  
    func emailVerified() { 
      command = .push(.confirmPassword) 
    }
      
    // GetPassword
  
    func passwordCompleted() {
      coordinator?.accountCreated() 
    }
      
    // Welcome
  
    func welcomeCompleted() { 
      coordinator?.loginCompleted() 
    }
  }
```
#### Key points
* The initial screen is selected by the initialRoute enum in the view model, making it easy to start the flow at different points if needed.
* The view model sub-class drives navigation by publishing commands operating on routes. The commands are dependent on the requests from the child ViewModels.
* As mentioned, the LoginFlowCoordinatorCoordinator is the parent coordinator of the LoginFlowCoordinator
* All navigation is driven by the view model, not the views. Views remain reusable and testable.
### Why This Works
1. All navigation decisions are view model-driven — views simply react.
2. Screens are reusable across flows because they only depend on a protocol (e.g., WelcomeCoordinator) rather than a concrete flow.
3. The Route enum ensures type-safe navigation, reducing runtime errors.
4. Navigation logic is centralized and predictable, making debugging, testing, and maintenance straightforward.
## Reusable Coordinator Abstraction
### Coordinator View
```swift
struct NavigatingCoordinatorView&lt;Route: Hashable, CoordinatorViewModel: NavigatingCoordinatorViewModel&lt;Route>, Content: View>: View {
    @ObservedObject var viewModel: CoordinatorViewModel
    let destinationView: (Route, CoordinatorViewModel?) -> Content

    init(@ObservedObject viewModel: CoordinatorViewModel,
         @ViewBuilder destinationView: @escaping (Route, CoordinatorViewModel?) -> Content
    ) {
        self.viewModel = viewModel
        self.destinationView = destinationView
    }

    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            destinationView(viewModel.initialRoute, viewModel)
                .navigationDestination(for: Route.self) { route in
                    destinationView(route, viewModel)
                }
        }
        .onReceive(viewModel.$command) { command in
            switch command {
            case let .push(screen, animated):
                applyTransaction(animated: animated) { 
                    navigationPath.append(screen) 
                }
            case let .replace(screen):
                navigationPath.removeLast()
                navigationPath.append(screen)
            case let .pop(count, animated):
                applyTransaction(animated: animated) { 
                    navigationPath.removeLast(count) 
                }
            case .popToHome:
                navigationPath.removeLast(navigationPath.count)
            case .none:
                break
            }
        }
    }

    private func applyTransaction(animated: Bool, _ changes: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = !animated
        withTransaction(transaction) { changes() }
    }
}
```

#### Key Points

- The NavigatingCoordinatorView interprets the commands received from the ViewModel.
- The navigationPath is private to the view and is not exposed to the navigator’s children

#### View Model-Driven Setup

* This pattern is **intended to be used by the view models of the child screens** that the coordinator instantiates.
* Views themselves cannot hold references to objects (except via @StateObject) in a way that guarantees controlled lifecycle management.
* Using the view model ensures that navigation is driven correctly and prevents misuse where a view might accidentally instantiate or control the coordinator directly.
#### Other notes
Notice the navigationPath is private to the view and is not exposed to the navigator’s children. This is because the navigationPath is view State. 

In many projects, I have seen the navigationPath exposed to and manipulated directly by the child screens. This paradigm makes it the responsibility of the children to know the details of navigation and create a hard dependency between the child screens and the navigator; making it extremely hard to reuse a screen in another flow or to add screens to an existing flow.

### Coordinator View Model
```swift
class NavigatingCoordinatorViewModel&lt;Route: Hashable>: ObservableObject {
    enum Command: Equatable {
        case push(Route, animated: Bool = true)
        case pop(Int = 1, animated: Bool = true)
        case popToHome
        case replace(Route)
    }

    @Published private(set) var initialRoute: Route
    @Published var command: Command?

    init(initialRoute: Route) {
        self.initialRoute = initialRoute
    }

    func popToHome() { command = .popToHome }
    func backRequested() { command = .pop() }
}
```
#### Key points

- This generic view model drives navigation by publishing commands.
- Views listen for these commands and update the NavigationStack accordingly — keeping the UI reactive and declarative.

####Other notes
* The initializer initialRoute parameter enum allows subclasses to configure the first screen in the flow. This allows subclasses to select which screen appears first in the flow, making it flexible for different use cases or entry points. The initializer of the coordinator view model takes a Route enum defined in the ViewModel's subclass as the initialRoute.
* The ViewModel exposes commands to the Coordinator view, ensuring all navigation decisions come from a centralized, predictable source rather than the views themselves.

---
## Conclusion
By combining a generic coordinator view, a view model-driven command system, and protocol-based screen communication, we can build:
* Fully reusable screens
* Predictable, testable flows
* Clean separation of UI, business logic, and navigation
This approach scales beautifully as SwiftUI apps grow and ensures our flows remain maintainable, even across multiple complex user journeys.
