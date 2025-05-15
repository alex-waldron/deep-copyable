// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Protocol that types with deep copying capabilities conform to
public protocol DeepCopyable {
    /// Returns a deep copy of this instance
    func copy() -> Self
}

/// Macro that adds deep copying capability to a class
@attached(member, names: named(copy), named(deepCopy))
@attached(extension, conformances: DeepCopyable)
public macro DeepCopyable() = #externalMacro(
    module: "DeepCopyableMacros",
    type: "DeepCopyableMacro"
)
