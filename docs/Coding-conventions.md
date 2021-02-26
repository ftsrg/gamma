# Coding conventions

We mainly follow the standard Java coding conventions and most of the conventions from the books _Effective Java_ [1] and _Clean Code_ [4]. Some exceptions and additional rules are listed below. Each rule starts with _DO_, _CONSIDER_, _AVOID_ or _DO NOT_, according to [2].

## Naming and formatting

* **DO** use the generally accepted naming and source code formatting conventions of Java (Item 56 of [1], Chapter 1 of [5]).
* **DO** start project names with the prefix `hu.bme.mit.gamma`.
* **DO** use CamelCase for class names containing subsequent capital letters, except when the whole name is a sequence of capital letters. Examples: `CFA`, `CfaEdge`, `OsHelper`.
* **DO** add a single space after keywords like `for`, `do`, `while`, `if` and `else`.
* **DO** add a single space before `{`.
* **DO** put the `else` keyword in a new line (and not like this: `} else {`).

## Classes and interfaces

* **CONSIDER** making classes immutable if possible (Item 15 of [1]). If initialization of an immutable class seems to be difficult, consider using a builder.
* **CONSIDER** making classes final if they are not designed to be inherited from (Item 17 of [1]).
* **AVOID** unused modifiers, for example methods of interfaces are automatically public.
* **CONSIDER** using the weakest types on interfaces. For example, instead of `ArrayList`, use `List`, `Collection` or `Iterable` if possible.
* **CONSIDER** adding a final modifier to a variable if its value is not expected to change.

## Testing and verification

* **CONSIDER** using `com.google.common.base.Preconditions` methods to check if the preconditions of a method holds. For example: null checks, bound checks, etc. **CONSIDER** filling the `errorMessage` parameter of these functions with a short error message.

## Transformation classes

* **DO** declare every object necessary for the tranformation in the constructor. If the EMF objects to be transformed are expected to be in a ResourceSet, communicate this constraint in a comment above the constructor.
* **DO** mark every not changable attribute in the class `final`.
* **DO** define a single `void execute()` method for the transformation.
* If the transformer returns multiple artifacts, **DO** define an inner class named *Result* that contains these.

## Xtend-specific constructs

* **DO** use the `val` keyword instead of the `var` keyword when declaring variables whenever possible.
* **CONSIDER** using the += and -= operator for adding and removing a single value or a collection of values to/from another collection.
* **DO NOT** cast an object to a certain type after checking whether the object is the instance of that certain type. Xtend  does that implicitly in the subsequent block of the if-structure.
* **CONSIDER** creating collections with the automatically imported `newCollectionType` method, e.g., newArrayList and newHashSet.

## Ecore metamodel projects

* **DO** set the Model directory to `src-gen` in the respective genmodel file.

## Other
* **AVOID** platform specific constructs. For example, prefer `System.lineSeparator()` over `\r\n` or `\n`.

# References

1. Joshua Bloch: Effective Java (2nd edition)
1. Krzysztof Cwalina, Brad Abrams: Framework Design Guidelines (2nd edition)
1. https://en.wikipedia.org/wiki/Initialization-on-demand_holder_idiom
1. Robert C. Martin: Clean Code: A Handbook of Agile Software Craftsmanship
1. Robert Liguori, Patricia Liguori: Java 8 Pocket Guide
