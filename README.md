# Symbolic Vector Set Kit (SVSKit): CTL Model Checking on Petri nets with Parametric Markings

This package aims at verifying CTL formulas on Petri nets with weighted arcs and potential capacity on places.
Unlike the usual technique where an initial marking is required, this is not the case here.
It can create the set of all markings that satisfy a CTL formula, using a symbolic representation called **Symbolic vector set**.
Furthermore, this structure allows to represent finite and infinite sets of markings.
This means that the number of markings can be unbounded.

The theory has been originally invented by Pascal Racloz & Didier Buchs [1].
In addition to the first theory, a canonical form has been invented in order to keep a unique form during manipulation. 
Currently, this canonical form does not provide results that are more efficient than the usual technique.
However, the current state will be evolving and thanks to the canonical form new optimisations will be made.

## What are symbolic vectors and symbolic vector sets ?

A symbolic vector is a couple `(a,b)`:
- `a` is a set of markings (vectors)
- `b` is a set of markings (vectors)

A marking `m` belongs to a symbolic vector if all markings of `a` are included in `m` and all markings of `b` are not included in `m`.
Formally writing:
m ∈ (a,b) ⟺ ∀ m_a ∈ a, ∀ m_b ∈ b, m_a ⊆ m, m_b ⊈ m

A symbolic vector set is a set containing multiple symbolic vectors.
A symbolic vector is not sufficient to represent all sets of markings, which is the reason of why we need to introduce an additional layer.


Example of a Petri net:  
 <img src="Images/petri_net.png"  width="30%" height="30%">

For example, the symbolic vector that represents all markings such as `t2` is fireable is `({(0,2)}, {})`.
Thus, accepting markings are of the form `(0,x), x ∈ [2,∞)`.
If we want all markings such as `t2` is fireable but not `t0`, we get the following symbolic vector: `({(0,2)}, {(1,0)})`.
It means that if there is at least one token in `p0`, the marking is not accepted.

For a symbolic vector set `svs`, a marking `m` belongs to it if there is at least one symbolic vector `sv` such as `m ∈ sv`.

## What functionalities are available ?

- Create a Petri net / fire a transition.
- Create a symbolic vector set containing all markings that satisfy a CTL formula / return a symbolic vector set as a set of markings.
- Check if a marking satisfies a CTL formula.
- PNML parser to import Petri nets from `pnml` file from a local source or a url.
- XML parser to import CTL formulas.
- Query reduction for a CTL formula: From the paper in [2].

## CTL syntax

```Swift
// Basic cases:
- deadlock
- isFireable(Transition) // Transition = String
- intExpr(e1: Expression, operator: Operator, e2: Expression)
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
let net = PetriNet(
  places: ["p0", "p1"],
  transitions: ["t0", "t1", "t2"],
  arcs: .pre(from: "p0", to: "t0", labeled: 1),
  .post(from: "t0", to: "p1", labeled: 1),
  .pre(from: "p1", to: "t1", labeled: 1),
  .post(from: "t1", to: "p0", labeled: 1)
)

// EX(t0)
let ctl1 = CTL(formula: .EX(.isFireable("t0")), net: net, canonicityLevel: .full)
// E (t0 ∧ ¬t1) U (t0)
let ctl2 = CTL(formula: .EU(.and(.isFireable("t0"), .not(.isFireable("t1"))), .isFireable("t0")), net: net, canonicityLevel: .full)
// EF(deadlock)
let ctl3 = CTL(formula: .deadlock, net: net, canonicityLevel: .full)
// AF(1 <= p1)
let ctl4 = CTL(formula: .AF(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net, canonicityLevel: .full)
// (p0 < 4) ∧ (7 < p1)
let ctl5 = CTL(formula: .and(.intExpr(e1: .tokenCount("p0"), operator: .lt, e2: .value(4)), .intExpr(e1: .value(7), operator: .lt, e2: .tokenCount("p1"))), net: net, canonicityLevel: .full)
```

Note that you must provide the parameter `canonicityLevel`, which has two possibilities:
- `.none`: No application of the canonicity
- `.full`: Application of all canonical reductions

Although there are two possibilities that could be resolved by a logical value, this option leaves open the possibility of an intermediate canonical version.

For `intExpr`, type `Expression` and `Operator` are expressible as follows:
- `Expression`:
  - `value(Int)`: The expression is an `Int`.
  - `tokenCount(String)`: The expression is a place that must belong to the set of places of the Petri net.
- `Operator`:
  - `lt`: Operator lesser than (`<`).
  - `leq`: Operator lesser than or equal to (`≤`).

In the case you try to compare two values, this is equivalent to having no constraint.
The program does not support the comparison between two places.
Therefore, an example such as `p1 < p2` is not supported.

## Use case examples

### Example 1

The below example, based on the previous Petri net, shows how to:
- Create a petri net
- Create CTL formulas
- Evaluate CTL formulas from a marking or without it
- Get all the markings encoded by a symbolic vector set

```Swift
import SVSKit

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
let ctlFormula1 = CTL(formula: .AX(.isFireable("t2")), net: net, canonicityLevel: .full)
let ctlFormula2 = CTL(formula: .EF(.isFireable("t2")), net: net, canonicityLevel: .full)
let ctlFormula3 = CTL(formula: .AF(.isFireable("t2")), net: net, canonicityLevel: .full)

let marking = Marking(["p0": 2, "p1": 1], net: net)

// Check CTL formulas for a given marking:

// Return: false
print(ctlFormula1.eval(marking: marking))
// Return: true
print(ctlFormula2.eval(marking: marking))
// Return: false
print(ctlFormula3.eval(marking: marking))

// To obtain the symbolic vector set that represent all markings:
let eval1 = ctlFormula1.eval()
// Return:
// {
//   ([], [[p1: 2, p0: 0], [p0: 1, p1: 0]]),
//   ([[p0: 0, p1: 4]], [])
// }
print(eval1)
// Return: [[p0: 0, p1: 0], [p0: 0, p1: 1], [p0: 0, p1: 4], [p0: 1, p1: 4], [p0: 2, p1: 4], [p0: 3, p1: 4], [p0: 4, p1: 4]]
print(eval1.underlyingMarkings())
// Return:
// {
//   ([[p1: 2, p0: 0]], []),
//   ([[p1: 0, p0: 2]], []),
//   ([[p1: 1, p0: 1]], [])
// }
print(ctlFormula2.eval())
// Return:
// {
//    ([[p1: 2, p0: 0]], [])
// }
print(ctlFormula3.eval())
```

For more examples, look at `Tests/SVSKitTests/CTLTests.swift` file.

The signatures of the `eval` function are the following:

If we want to check for a marking:
`eval(marking: Marking) -> Bool`

If we want to obtain all markings:
`eval() -> SVS`

Two parameters are optionals when you create a ctl formula and can be modified:
- simplified: false by default. Another way of reducing the number of symbolic vectors. This is unnecessary if the level of canonicality is set to `.full'. This can be used to compare performance when every effort is made to preserve a canonical form, and when minimal effort is made to avoid certain redundancies.
- debug: false by default. Display number of symbolic vectors between each step of the computation.

To get all the underlying markings of a symbolic vector set, you should use the function `underlyingMarkings`, which works on symbolic vectors and symbolic vector sets.
Because a symbolic vector can represent an infinite number of markings, the place capacity is used to bound the number of solutions.
The capacity is set by default to 20 for each place, but may be adapted as in the previous example with `capacity: ["p0": 4, "p1": 4]`.

### Example 2

The below example shows how to use the query reduction:

```swift
// We suppose the declaration of a net before
...
let ctl1 = CTL(formula: .not(.not(.true)), net: net, canonicityLevel: .full)

// Return: .true
print(ctl1.queryReduction())

let ctl2 = CTL(formula: .EF(.EF(.true)), net: net, canonicityLevel: .full)
// Return: .EF(.true)
print(ctl2.queryReduction())
```

All the reduction rules can be found in [2].

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
        .package(url: "https://github.com/damdamo/SVSKit.git", .branch("main")),
    ],
    targets: [
        .executableTarget(
            name: "Test",
            dependencies: ["SVSKit"],
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

For examples, look at the folder `Tests/SVSKitTests` and the file `ListExampleTests.swift`.

## TODO:

<!--- Integrate linear expressions with Predicate structure. For now, linear expressions can be written but not be evaluated.-->
- When a Petri net contains a transition without a pre arc and only a post arc, the old function pre for all returns a result when it should be empty. The reason is we cannot avoid to fire this transition, thus the logic of pre for all cannot be handled.
<!--- Uniformise with a the Petri net bound between two versions of pre for all (example test in ListExampleTests)-->

## References

[1] Racloz, P., & Buchs, D. (1994). Properties of Petri Nets Modellings: the temporal way. In 7th International Conference on Formal Description Techniques for Distributed Systems Communications Protocols. Services, Technologies.

[2] Bønneland, F., Dyhr, J., Jensen, P. G., Johannsen, M., & Srba, J. (2018). Simplification of CTL formulae for efficient model checking of Petri nets. In Application and Theory of Petri Nets and Concurrency: 39th International Conference, PETRI NETS 2018, Bratislava, Slovakia, June 24-29, 2018, Proceedings 39 (pp. 143-163). Springer International Publishing.
