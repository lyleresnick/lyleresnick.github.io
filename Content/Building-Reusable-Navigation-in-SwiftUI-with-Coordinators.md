---
layout: BlogPost
date: 2025-10-15 12:00
tags: SwiftUI
---

# Building Reusable Navigation in SwiftUI with Coordinators
Managing navigation in SwiftUI is easy for simple flows but quickly becomes messy as apps grow. Routing decisions end up in the screen view files, view models leak navigation logic, and flows become hard to follow.

To solve this, we can use a coordinator pattern: a centralized system that orchestrates navigation for a flow while keeping screens and view models clean, reusable, and testable.

The Coordinator pattern presented here is sometimes known as the Router pattern.

 See [CoordinatorDemo](https://github.com/lyleresnick/CoordinatorDemo) for an accompanying demonstration app with examples of both root and navigating Coordinators.

------

***TL;DR**: Coordinator pattern for SwiftUI: centralize navigation, keep screens reusable, make flows testable.  [Skip to concrete example →](#concrete-example-login-flow) | [Skip to reusable abstraction →](#the-reusable-foundation)* 

---

## The Problem We're Solving

In most SwiftUI codebases, navigation code lives in the View, creating tight coupling between screens and their flows:

```swift
// ❌ The Problem: Navigation scattered across views
struct LoginView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // View code mixed with navigation decisions
            Button("Create Account") {
                navigationPath.append(CreateAccountRoute())
            }
        }
    }
}
```

This approach has serious problems:

- **Tight coupling**: Views know about other views and navigation implementation
- **Hard to reuse**: Can't use LoginView in a different flow without modification
- **Scattered logic**: Business rules for navigation spread across multiple files
- **Difficult to test**: Navigation decisions buried in view code
- **Hard to maintain**: Adding or reordering screens requires changes everywhere

---

## What is a Coordinator?

A **Coordinator** is an object that takes responsibility for orchestrating a multi-screen flow. Think of it as the parent of a group of related screens.

```
Coordinator (Parent)
    ├── Screen A (Child)
    ├── Screen B (Child)
    └── Screen C (Child)
```

**Key insight**: Only the coordinator knows about its children. Children only know about their coordinator through a lightweight protocol, not about their siblings or the navigation system itself.

The coordinator consists of two parts:
- **CoordinatorView**: Contains SwiftUI navigation code (the *how* and *what*)
- **CoordinatorViewModel**: Contains business logic (the *when* and *why*)

---

## Core Concepts

### 1. Navigation Logic moves from View to Coordinator

Instead of views manipulating a navigator directly, navigation responsibility belongs to an external coordinator object. The screen's View and ViewModel receive a reference to the coordinator, but the coordinator is opaque to them—they don't even know a navigator exists.

### 2. Instantiation and Presentation is Centralized

The coordinator instantiates and presents all screens in its flow. Only the coordinator knows about child screens. Once a child is instantiated, the coordinator waits for requests from the child and interprets them according to business rules.

### 3. Navigation Logic is Encapsulated

All navigation decisions—pushing, popping, and conditional logic based on flow state—are centralized in the coordinator. Instead of scattering logic across Views or ViewModels, flow logic is contained within the CoordinatorViewModel's scope.

### 4. Separate Responsibilities within the Coordinator

- **CoordinatorView**: Knows *how* and *what* to push and pop (SwiftUI navigation code only)
- **CoordinatorViewModel**: Knows *when* and *why* to push and pop (business logic only)

These types are always prefixed with the Flow Name (e.g., `LoginFlowCoordinatorView`, `LoginFlowCoordinatorViewModel`).

### 5. Separate Responsibilities within Child Screens

- **View**: Displays UI and responds to user interactions
- **ViewModel**: Handles business logic and makes requests to the coordinator
- **Coordinator**: Handles navigation and flow transitions

The ViewModel makes requests in terms of *what happened*, not *what to do*. The coordinator makes the routing decisions.

### 6. Protocol-Driven Screen Reuse

Each child screen communicates with its parent coordinator via a protocol:

- Each screen gets a lightweight protocol exposing only the methods it needs
- The child's ViewModel retains a reference to the coordinator
- The coordinator implements the protocol
- This decouples the screen from the flow, making it reusable in multiple flows without modification

### 7. Consistency Across a Flow

Special-case behavior (resetting flow state, moving back to a specific screen, user-state-driven screens like onboarding) happens centrally in the coordinator. This ensures uniform behavior and eliminates duplicated or contradictory logic across screens.

### 8. View Model-Driven Navigation

All navigation decisions originate from view models. Views react to commands like `.push`, `.pop`, or `.replace`, but never push or pop themselves. This keeps the flow predictable and makes testing simple—you can verify navigation decisions without presenting any UI.

### 9. Maintainability and Scalability

Centralized navigation makes adding, removing, or reordering screens safe and straightforward. As the app grows, changes to the flow only require updates in one place.

---

<a name="concrete-example-login-flow"></a>

## Concrete Example: Login Flow

Here's a real-world login flow demonstrating the pattern. The flow consists of five screens: Login → Create Account → Email Verification → Get Password → Welcome.

```
User Journey:
Login → CreateAccount → EmailVerification → GetPassword → Welcome
  ↓          ↓                 ↓                  ↓            ↓
            LoginFlowCoordinator (implements all protocols)
```

### The Routes

First, we define the routes (screens) in our flow:

```swift
enum Route: Hashable {
    case login
    case signUp
    case emailVerification(email: String)
    case capturePassword(email: String)
    case welcome(email: String, password: String)
}
```

### Coordinator View Model

**What this does:**
- Drives navigation via commands
- Implements screen-specific protocols (`LoginCoordinator`, `CreateAccountCoordinator`, etc.)
- Centralizes all flow logic
- Determines which screen appears first via `initialRoute`

**Code:**

```swift
class LoginFlowCoordinatorViewModel: 
    NavigatingCoordinatorViewModel&lt;LoginFlowCoordinatorViewModel.Route>,
    LoginCoordinator,
    SignUpCoordinator,
    EMailVerificationCoordinator,
    PasswordCaptureCoordinator,
    WelcomeCoordinator {
    
    enum Route: Hashable {
        case login
        case signUp
        case emailVerification(email: String)
        case capturePassword(email: String)
        case welcome(email: String, password: String)
    }

    private weak var coordinator: LoginFlowCoordinatorCoordinator?

    init(coordinator: LoginFlowCoordinatorCoordinator?) {
        super.init(initialRoute: .login)
        self.coordinator = coordinator
    }
      
    // Login
      
    func signUpRequested() {
      command = .push(.signUp)
    }
      
    func loginCompleted() {
        coordinator?.loginCompleted()
    }

    // SignUp
  
    func emailCaptured(email: String)
    {
        command = .push(.emailVerification(email: email))
    }
    
    func signUpCancelled()
    {
        backRequested()
    }
      
    // EmailVerification
  
    func emailVerified(email: String) {
      command = .replace(.capturePassword(email: email))
    }
    
    func verificationCancelled() {
        backRequested()
    }
      
    // PasswordCapture
  
    func passwordCaptured(email: String, password: String) {
        command = .replace(.welcome(email: email, password: password))
    }
      
    // Welcome
  
    func signUpCompleted() {
        coordinator?.loginCompleted()
    }
  }
```

**Notice:**
- The initial screen is selected by the `initialRoute` parameter, making it easy to start the flow at different points if needed
- The view model drives navigation by publishing commands based on requests from child ViewModels
- `LoginFlowCoordinatorCoordinator` is the parent coordinator of the LoginFlowCoordinator (every child screen has a coordinator unless it is the root coordinator)
- All navigation is driven by the view model, not the views—views remain reusable and testable

### Coordinator View

**What this does:**
- Uses the generic `NavigatingCoordinatorView` to handle navigation
- Provides a ViewBuilder that instantiates each screen for its route
- Passes the coordinator protocol reference to each screen

**Code:**

```swift
struct LoginFlowCoordinator: View {
    @StateObject private var viewModel: LoginFlowCoordinatorViewModel
    
    init(coordinator: LoginFlowCoordinatorCoordinator? = nil) {
        _viewModel = StateObject(wrappedValue: .init(coordinator: coordinator))
    }

    var body: some View {
        NavigatingCoordinatorView(viewModel: viewModel) { route, coordinator in
            switch route {
            case .login:
                LoginScreen(coordinator: coordinator)
            case .signUp:
                SignUpScreen(coordinator: coordinator)
            case let .emailVerification(email):
                EmailVerificationScreen(email: email, coordinator: coordinator)
            case let .capturePassword(email):
                PasswordCaptureScreen(email: email, coordinator: coordinator)
                    .navigationBarBackButtonHidden(true)
            case let .welcome(email, password):
                WelcomeScreen(
                  email: email, password: password, coordinator: coordinator)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}
```

**Notice:**
- `NavigatingCoordinatorView` takes a ViewBuilder that builds screens for each route
- Each screen receives a protocol-based coordinator, allowing them to be reused in other flows without modification
- None of the screens has knowledge of any other screen

### Why This Works

1. **All navigation decisions are view model-driven** — views simply react
2. **Screens are reusable across flows** because they only depend on a protocol (e.g., `WelcomeCoordinator`) rather than a concrete flow
3. **The Route enum ensures type-safe navigation**, reducing runtime errors
4. **Navigation logic is centralized and predictable**, making debugging, testing, and maintenance straightforward

---

<a name="the-reusable-foundation"></a>

## The Reusable Foundation 

The pattern relies on two generic components that can be reused across all coordinators in your app.

### NavigatingCoordinatorViewModel

**What this does:**
- Defines the command system for navigation (push, pop, replace)
- Publishes commands that the view observes
- Provides base functionality for all coordinator view models
- Allows subclasses to configure the first screen via `initialRoute`

**Code:**

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

**Notice:**
- The `initialRoute` parameter allows subclasses to select which screen appears first, making it flexible for different entry points
- The ViewModel exposes commands to the Coordinator view, ensuring all navigation decisions come from a centralized, predictable source rather than the views themselves

### NavigatingCoordinatorView

**What this does:**
- Interprets commands from the ViewModel
- Manages the `NavigationPath` (kept private, never exposed to children)
- Translates view model commands into SwiftUI navigation actions
- Handles animation and transaction control

**Code:**

```swift
struct NavigatingCoordinatorView&lt;Route: Hashable, 
    CoordinatorViewModel: NavigatingCoordinatorViewModel&lt;Route>, Content: View>: View {
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

**Notice:**
- The `navigationPath` is private to the view and is not exposed to the navigator's children (it is view state)
- This pattern is **intended to be used by the view models of child screens** that the coordinator instantiates
- Views themselves cannot hold references to objects (except via @StateObject) in a way that guarantees controlled lifecycle management

### Why This Design Works

**View Model-Driven:**
Using the view model ensures that navigation is driven correctly and prevents misuse where a view might accidentally instantiate or control the coordinator directly.

**Encapsulated Navigation Path:**
In many projects, the `navigationPath` is exposed to and manipulated directly by child screens. This paradigm makes it the responsibility of children to know the details of navigation and creates a hard dependency between child screens and the navigator, making it extremely hard to reuse a screen in another flow or to add screens to an existing flow.

---

## Common Pitfalls to Avoid

### ❌ Don't: Expose NavigationPath to Child Screens
```swift
// BAD: Child manipulating navigation directly
struct LoginView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        Button("Next") {
            navigationPath.append(CreateAccountRoute()) // Tight coupling!
        }
    }
}
```

**Why it's bad:** Creates hard dependency between screens and navigator, makes screens impossible to reuse.

### ❌ Don't: Let Views Make Navigation Decisions
```swift
// BAD: View deciding what comes next
struct LoginView: View {
    var body: some View {
        Button("Login") {
            if userNeedsOnboarding {
                // Navigation logic in view!
            }
        }
    }
}
```

**Why it's bad:** Business logic in views is untestable and hard to maintain.

### ❌ Don't: Tell the Coordinator What to Do
```swift
// BAD: ViewModel commanding navigation
protocol LoginCoordinator {
    func pushCreateAccount()  // Too prescriptive!
}
```

**Why it's bad:** Couples screen to specific navigation actions.

### ✅ Do: Keep Protocols Lightweight and Intent-Based
```swift
// GOOD: ViewModel reporting what happened
protocol LoginCoordinator {
    func createAccountRequested()  // Intent, not command!
}
```

**Why it's good:** Coordinator decides how to handle the intent, screen stays reusable.

### ✅ Do: Keep Screens Independent
Each screen should:
- Depend only on its protocol, not concrete coordinators
- Not know about other screens in the flow
- Report user actions, not dictate navigation

---

## Conclusion

We've built a coordinator system that solves three core problems:

### 1. Reusability
**Problem**: Screens tied to specific flows can't be reused.

**Solution**: Protocol-based communication means `WelcomeScreen` works in login flow, onboarding flow, or any other flow—just implement `WelcomeCoordinator`.

### 2. Testability
**Problem**: Navigation logic spread across views is hard to test.

**Solution**: All navigation logic lives in the coordinator view model. Test navigation without touching UI:
```swift
func testLoginSuccess() {
    coordinator.loginCompleted()
    XCTAssertEqual(coordinator.command, .replace(.welcome))
}
```

### 3. Maintainability
**Problem**: Changes to flows require hunting through multiple files.

**Solution**: Want to add a password strength screen? Change one file:
```swift
// In LoginFlowCoordinatorViewModel
func passwordRequested() {
    command = .push(.passwordStrength)  // One line added
}
```

### Getting Started

To adopt this pattern in your app:

1. **Create the reusable foundation** (`NavigatingCoordinatorViewModel` and `NavigatingCoordinatorView`)
2. **Identify a flow** in your app (login, onboarding, checkout, etc.)
3. **Define your routes** as an enum in your coordinator view model
4. **Create protocols** for each screen (one protocol per screen type)
5. **Implement the coordinator view model** by handling each protocol method
6. **Build the coordinator view** by mapping routes to screens
7. **Update your screens** to accept the protocol instead of handling navigation directly

### Next Steps

Once you're comfortable with basic coordinator flows, explore:

- **Deep linking with coordinators**: Handle URLs by setting the initial route
- **Coordinating between flows**: Pass parent coordinators for flow completion
- **Testing coordinator logic**: Unit test navigation decisions without UI
- **Handling modals and sheets**: Extend the command system for presentation styles

This approach scales beautifully as SwiftUI apps grow and ensures flows remain maintainable, even across multiple complex user journeys.