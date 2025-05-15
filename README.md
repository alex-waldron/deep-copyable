# DeepCopyable

A Swift macro that automatically implements deep copying functionality for classes.

## Overview

`DeepCopyable` is a Swift macro that adds a `copy()` method to your classes, enabling deep copying of reference types. This solves the common problem where simply assigning a reference type (class) creates a new reference to the same object rather than a completely new instance with the same values.

This macro:
- Automatically generates proper deep copy functionality for classes
- Handles nested reference types that also use the `@DeepCopyable` macro
- Correctly handles value types (which are already copied by value)
- Verifies that the decorated type is a class or actor
- Ensures that proper initialization is maintained

## Requirements

- Swift 5.9 or later
- macOS 14+ / iOS 17+ / watchOS 10+ / tvOS 17+ (or equivalent platforms that support Swift macros)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/alex-waldron/deep-copyable.git", from: "0.1.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "DeepCopyable", package: "deep-copyable"),
    ]
)
```

## Usage

### Basic Usage

Apply the `@DeepCopyable` macro to your class definition:

```swift
import DeepCopyable

@DeepCopyable
class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
}

// Create an instance
let original = Person(name: "Alice", age: 30)

// Create a deep copy
let copy = original.copy()

// Verify they are different instances
print(original === copy) // Prints: false
```

### Nested Classes

`DeepCopyable` works with nested classes as long as they are also marked with the `@DeepCopyable` macro:

```swift
@DeepCopyable
class Address {
    var street: String
    var city: String
    
    init(street: String, city: String) {
        self.street = street
        self.city = city
    }
}

@DeepCopyable
class Employee {
    var name: String
    var address: Address
    
    init(name: String, address: Address) {
        self.name = name
        self.address = address
    }
}

let address = Address(street: "123 Main St", city: "Anytown")
let original = Employee(name: "Bob", address: address)
let copy = original.copy()

// Modifying the copy doesn't affect the original
copy.address.street = "456 Oak Ave"
print(original.address.street) // Prints: "123 Main St"
```

### Collections of DeepCopyable Items

The macro also properly handles collections containing `DeepCopyable` items:

```swift
@DeepCopyable
class Team {
    var name: String
    var members: [Person]
    
    init(name: String, members: [Person]) {
        self.name = name
        self.members = members
    }
}

let person1 = Person(name: "Alice", age: 30)
let person2 = Person(name: "Bob", age: 25)
let original = Team(name: "Engineering", members: [person1, person2])
let copy = original.copy()

// Verify deep copying of collection items
print(original.members[0] === copy.members[0]) // Prints: false
```

## Requirements and Constraints

For `@DeepCopyable` to work properly, your class must:

1. Be a reference type (class or actor)
2. Have an initializer that covers all stored properties
3. Each stored property must be either:
   - A value type (struct, enum, etc.)
   - Another class that conforms to `DeepCopyable` (has the `@DeepCopyable` macro applied)

## How It Works

The `@DeepCopyable` macro:

1. Analyzes your class at compile time
2. Locates a suitable initializer
3. Automatically generates a `copy()` method that:
   - Creates a new instance of your class
   - Deep copies any properties that are `DeepCopyable`
   - Preserves values of value types (which are copied by value)
4. Makes your class conform to the `DeepCopyable` protocol

## Advanced

### Manual Implementation

If you need more control over the copying process, you can manually implement the `DeepCopyable` protocol:

```swift
protocol DeepCopyable {
    func copy() -> Self
}

class CustomClass: DeepCopyable {
    // Your properties...
    
    func copy() -> Self {
        // Custom copying logic...
        return newInstance as! Self
    }
}
```

## Troubleshooting

### Common Errors

- **"@DeepCopyable can only be applied to classes or actors"**: The macro must be applied to a reference type.
- **"@DeepCopyable requires a non-convenience initializer that initializes all stored properties"**: Ensure your class has an initializer that sets all stored properties.
- **"Property X must be either a value type or another @DeepCopyable type"**: All reference type properties must also be `@DeepCopyable`.

## License

MIT

## Contribution

Contributions are welcome! Please feel free to submit a Pull Request.
