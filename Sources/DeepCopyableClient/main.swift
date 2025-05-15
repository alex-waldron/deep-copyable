import DeepCopyable

let a = 17
let b = 25

@DeepCopyable()
final class MyClass: Equatable {
    static func == (lhs: MyClass, rhs: MyClass) -> Bool {
        lhs.testMutable == rhs.testMutable &&
        lhs.testConst == rhs.testConst &&
        lhs.propertyFromInit == rhs.propertyFromInit &&
        lhs.intFromInit == rhs.intFromInit
    }
    
    var testMutable = ""
    let testConst = 1

    let propertyFromInit: String

    let intFromInit: Int

    let nestedClass: NestedClass

    init(testMutable: String = "", propertyFromInit: String = "", intFromInit: Int = 100, nestedClass: NestedClass = NestedClass(text: "hello world", value: 420)) {
        self.testMutable = testMutable
        self.propertyFromInit = propertyFromInit
        self.intFromInit = intFromInit
        self.nestedClass = nestedClass
    }

}

@DeepCopyable final class NestedClass: Equatable {
    static func == (lhs: NestedClass, rhs: NestedClass) -> Bool {
        lhs.text == rhs.text &&
        lhs.value == rhs.value
    }
    
    let text: String
    let value: Int

    init(text: String, value: Int) {
        self.text = text
        self.value = value
    }
}

let initalInstance = MyClass()

initalInstance.testMutable = "new value"

let copy = initalInstance.copy()

assert(initalInstance !== copy)
assert(initalInstance.nestedClass !== copy.nestedClass)

assert(initalInstance == copy)

print("Tests passed!")

