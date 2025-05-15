import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

// Define the DeepCopyable macro
public struct DeepCopyableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Ensure the declaration is a class or actor
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw DeepCopyableError.notAppliedToClass
        }

        // Extract class name and members
        let className = classDecl.name.text
        let members = classDecl.memberBlock.members

        // Find all stored properties
        var storedProperties: [(name: String, type: String)] = []

        for member in members {
            guard let varDecl = member.decl.as(VariableDeclSyntax.self),
                  varDecl.bindingSpecifier.text == "var" || varDecl.bindingSpecifier.text == "let",
                  !varDecl.modifiers.contains(where: { $0.name.text == "static" || $0.name.text == "class" }) else {
                continue
            }

            guard let binding = varDecl.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                  let typeAnnotation = binding.typeAnnotation?.type else {
                continue
            }

            let propertyName = identifier.identifier.text
            let propertyType = typeAnnotation.description.trimmingCharacters(in: .whitespaces)

            storedProperties.append((propertyName, propertyType))
        }

        // Find an initializer that covers all properties
        var initializer: InitializerDeclSyntax? = nil

        for member in members {
            guard let initDecl = member.decl.as(InitializerDeclSyntax.self) else {
                continue
            }

            // Skip convenience initializers
            if initDecl.modifiers.contains(where: { $0.name.text == "convenience" }) {
                continue
            }

            // Check if this initializer has parameters for all stored properties
            let parameterNames = initDecl.signature.parameterClause.parameters.compactMap { param -> String? in
                let firstName = param.firstName
                return firstName.text
            }

            let allPropertiesCovered = storedProperties.allSatisfy { property in
                parameterNames.contains(property.name)
            }

            if allPropertiesCovered {
                initializer = initDecl
                break
            }
        }

        // If no proper initializer found, throw an error
        guard let initializer = initializer else {
            throw DeepCopyableError.noValidInitializer
        }

        // Generate the copy method
        let initParams = initializer.signature.parameterClause.parameters.map { param -> String in
            let paramName = param.firstName.text
            return "\(paramName): deepCopy(self.\(paramName))"
        }.joined(separator: ", ")

        // Generate the deep copy helper method and copy method
        let copyMethodString = """
        
            /// Helper method to create deep copies of properties
            private func deepCopy<T>(_ value: T) -> T {
                if let copyable = value as? DeepCopyable {
                    // If the value conforms to DeepCopyable, call its copy method
                    return copyable.copy() as! T
                } else {
                    // For value types, return as is (they're already copied)
                    return value
                }
            }
            
            /// Returns a deep copy of this instance
            public func copy() -> \(className) {
                return \(className)(\(initParams))
            }
        """

        return [DeclSyntax(stringLiteral: copyMethodString)]
    }
}

// Define a protocol for type verification at runtime
extension DeepCopyableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let protocolExtension = try ExtensionDeclSyntax("extension \(type): DeepCopyable {}")
        return [protocolExtension]
    }
}

// Enhanced error types
enum DeepCopyableError: Error, CustomStringConvertible {
    case notAppliedToClass
    case noValidInitializer
    case propertyTypeNotSupported(String)

    var description: String {
        switch self {
        case .notAppliedToClass:
            return "@DeepCopyable can only be applied to classes or actors"
        case .noValidInitializer:
            return "@DeepCopyable requires a non-convenience initializer that initializes all stored properties"
        case .propertyTypeNotSupported(let name):
            return "Property '\(name)' must be either a value type or another @DeepCopyable type"
        }
    }
}

// Register the macro with the compiler plugin
@main
struct DeepCopyablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        DeepCopyableMacro.self
    ]
}
