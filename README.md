# Predicate Structure: CTL Model Checking on Parametric Petri nets

This package aims at verifying CTL formulas on Petri nets with weighted arcs and potential capacity on places.
Unlike the usual technique where an initial marking is required, this is not the case here.
It can create the set of all markings that satisfy a CTL formula, using a symbolic representation called **Predicate structure**.
Furthermore, this structure allows to represent finite and infinite sets of markings.
This means that the number of markings can be unbounded.

## What are Predicate structures ?

A predicate structure is a couple `(a,b)`:
- `a` is a set of markings
- `b` is a set of markings

A marking `m` belongs to a predicate structure if all markings of `a` are included in `m` and all markings of `b` are not included in `m`.
Formally writing:
m ∈ (a,b) ⟺ ∀ m_a ∈ a, ∀ m_b ∈ b, m_a ⊆ m, m_b ⊈ m


Example of a Petri net:  
 <img src="Images/petri_net.png"  width="30%" height="30%">

For example, the predicate structure that represents all markings such as `t2` is fireable is `({(0,2)}, {})`.
Thus, accepting markings are of the form `(0,x), x ∈ [2,∞)`.
If we want all markings such as `t2` is fireable but not `t0`, we get the following predicate structure: `({(0,2)}, {(1,0)})`.
It means that if there is at least one token in `p0`, the marking is not accepted.

For a set of predicate structures `sps`, a marking `m` belongs to it if there is at least one predicate structure `ps` such as `m ∈ ps`.

## What functionalities are available ?

- Create a Petri net / fire a transition
- Create a set of predicate structures containing all markings that satisfy a CTL formula.
- Check if a marking satisfies a CTL formula.
- PNML parser, to import Petri nets from `pnml` file from a local source or a url.

## CTL syntax

```Swift
// Basic cases:
- deadlock
- isFireable(Transition) // Transition = String
- after(Transition)
// Boolean logic
- true
- and(CTL, CTL)
- or(CTL, CTL)
- not(CTL)
// CTL operators
- EX(CTL)
- EF(CTL)
- EG(CTL)
- EU(CTL, CTL)
- AX(CTL)
- AF(CTL)
- AG(CTL)
- AU(CTL, CTL)
```

Example of some CTL formulas in Swift:
```Swift
CTL.EX(.isFireable("t0"))
CTL.EU(.and(.isFireable("t0"), .not(.isFireable("t1"))), .isFireable("t0"))
CTL.EF(.deadlock)
```

Thanks to Swift inference, we do not need to write `CTL.EX(CTL.isFireable("t0"))`.
We can reduce `CTL.isFireable` into `.isFireable`.
The same logic is applicable for each operators, except for the first one of the list.

## Use case example

This is based on the previous example see above.

```Swift
import PredicateStructure

// Same Petri net as before
let net = PetriNet(
  places: ["p0", "p1"],
  transitions: ["t0", "t1", "t2"],
  arcs: .pre(from: "p0", to: "t0", labeled: 1),
  .pre(from: "p0", to: "t1", labeled: 1),
  .post(from: "t1", to: "p1", labeled: 1),
  .pre(from: "p1", to: "t2", labeled: 2),
  capacity: ["p0": 4, "p1": 4] // Optional, can be removed
)

// Three examples of CTL formulas:
let ctlFormula1: CTL = .AX(.isFireable("t2"))
let ctlFormula2: CTL = .EF(.isFireable("t2"))
let ctlFormula3: CTL = .AF(.isFireable("t2"))

let marking = Marking(["p0": 2, "p1": 1], net: net)

// Check CTL formulas for a given marking:

// Return: false
print(ctlFormula1.eval(marking: marking, net: net))
// Return: true
print(ctlFormula2.eval(marking: marking, net: net))
// Return: false
print(ctlFormula3.eval(marking: marking, net: net))

// To obtain the sets of predicate structures that represent all markings:
// Return:
// {
//   ([], [[p1: 2, p0: 0], [p0: 1, p1: 0]]),
//   ([[p0: 0, p1: 4]], [])
// }
print(ctlFormula1.eval(net: net))
// Return:
// {
//   ([[p1: 2, p0: 0]], []),
//   ([[p1: 0, p0: 2]], []),
//   ([[p1: 1, p0: 1]], [])
// }
print(ctlFormula2.eval(net: net))
// Return:
// {
//    ([[p1: 2, p0: 0]], [])
// }
print(ctlFormula3.eval(net: net))
```

For more examples, look at `Tests/PredicateStructureTests/CTLTests.swift` file.

## How to import a pnml file ?

From a pnml file, we can extract the initial marking and the Petri net.

### From an URL:

```Swift
let parser = PnmlParser()
if let url = URL(string: "https://www.pnml.org/version-2009/examples/philo.pnml") {
  let (net, marking) = parser.loadPN(url: url)
}
```

### From a local file:

This is a bit tricky because of Swift.
You need to specify explicitly in the Swift package the folder where you will put your own pnml files. Follow the instructions below to include them:

- First, create a `Resources` folder at the same level of your `main.swift`.

- Then, modify your `Package.swift` to add the following line in `targets/executableTarget`:
`resources: [.process("Resources/")]`
It works the same way if you just have `target` instead of `executableTarget`:

Here is a complete example of the definition of a package:
```Swift
let package = Package(
    name: "Test",
    dependencies: [
        .package(url: "https://github.com/damdamo/PredicateStructure.git", .branch("main")),
    ],
    targets: [
        .executableTarget(
            name: "Test",
            dependencies: ["PredicateStructure"],
            resources: [.process("Resources/")]
        ),
        .testTarget(
            name: "TestTests",
            dependencies: ["Test"]),
    ]
)
```  

- Now, you can import your pnml file as follows:

```Swift
let parser = PnmlParser()
let (net, marking) = parser.loadPN(filePath: "nameOfYourFile.pnml")
```

For examples, look at the folder `Tests/PredicateStructureTests` and the file `ListExampleTests.swift`.
