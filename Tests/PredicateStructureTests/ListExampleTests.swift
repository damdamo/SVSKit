import XCTest
//@testable import PredicateStructure
import PredicateStructure

final class ListExampleTests: XCTestCase {

//  func testSwimmingPool() {
//    let parser = PnmlParser()
//    var (net1, marking1) = parser.loadPN(filePath: "SwimmingPool-1.pnml")
//    var s = Stopwatch()
//    //     Example to observe that we do not need to compute EF fully to return true.
//    //     Thanks to the lowest fixpoint, at each step, the state space can only grow.
//    //     Hence, if the marking belong to the predicate structure at any point of the iterations, we can return an early answer.
//    //     The additional optimisation happens when eval is called with the given marking
//    let ctl1 = CTL(formula: .EU(.isFireable("GetB"), .isFireable("RBag")), net: net1, canonicityLevel: .semi)
//    let ctl2 = CTL(formula: .not(.AF(.not(.EF(.isFireable("GetB"))))), net: net1, canonicityLevel: .semi, simplified: false, debug: false)
//    XCTAssertFalse(ctl1.eval(marking: marking1))
//    print(s.elapsed.humanFormat)
//    s.reset()
//    XCTAssertTrue(ctl2.eval(marking: marking1))
//    print(s.elapsed.humanFormat)
//
//    marking1["Out"] = 2
//    marking1["Cabins"] = 1
//    marking1["Bags"] = 2
//
//    let efCTL = CTL(formula: .not(.EF(.isFireable("RBag"))), net: net1, canonicityLevel: .none)
//    let agCTL = CTL(formula: .AG(.isFireable("RBag")), net: net1, canonicityLevel: .none)
//    XCTAssertFalse(efCTL.eval(marking: marking1))
//    XCTAssertFalse(agCTL.eval(marking: marking1))
//
//    marking1["Cabins"] = 0
//    XCTAssertTrue(efCTL.eval(marking: marking1))
//
//  }

//  func testDeadlock() {
//    // Example 1 of paper: https://journals.sagepub.com/doi/10.1177/1687814017693542
//    let net = PetriNet(
//      places: ["p1", "p2", "p3", "p4", "p5"],
//      transitions: ["t1", "t2", "t3"],
//      arcs: .pre(from: "p1", to: "t1", labeled: 1),
//      .pre(from: "p5", to: "t1", labeled: 1),
//      .post(from: "t1", to: "p2", labeled: 1),
//      .pre(from: "p2", to: "t2", labeled: 1),
//      .pre(from: "p4", to: "t2", labeled: 1),
//      .pre(from: "p5", to: "t2", labeled: 1),
//      .post(from: "t2", to: "p3", labeled: 1),
//      .pre(from: "p3", to: "t3", labeled: 1),
//      .post(from: "t3", to: "p5", labeled: 2),
//      .post(from: "t3", to: "p4", labeled: 1),
//      .post(from: "t3", to: "p1", labeled: 1)
//    )
//
//    let ctl: CTL = CTL(formula: .EG(.not(.deadlock)), net: net, rewrited: false)
//    let marking = Marking(["p1": 3, "p2": 0, "p3": 0, "p4": 1, "p5": 2], net: net)
//    var timer = Stopwatch()
//    for _ in 0 ..< 10 {
//      print(ctl.eval(marking: marking))
//      print(timer.elapsed.humanFormat)
//    }
//    print("Final time: \(timer.elapsed.humanFormat)")
//
//  }

  func testERKCaseSpecific() {
    let parserPN = PnmlParser()
    var (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
    var s = Stopwatch()

    let parserCTL = CTLParser()

    s.reset()

    let ctlReduced: CTL = CTL(formula: .EF(.isFireable("r3")), net: net1, canonicityLevel: .full, debug: true).queryReduction()
    print(ctlReduced)
//    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true)

    let e1 = ctlReduced.eval()
//    let e2 = ctlReduced.eval()
//
//    print("----------------------")
//    print(e1)
//    print("----------------------")
//    print(e2)
//    print("----------------------")
//    print(SPS(values: e1.values.subtracting(e2.values)))
//
//    print(e1 == e2)
//    print(e1.isEquiv(e2))
    var oldT2: SPS = []
    for _ in 0 ..< 10 {
      let t1 = e1.not(net: net1, canonicityLevel: .full)
      print("t1 count: \(t1.count)")
      let t2 = t1.revert(canonicityLevel: .full)
      print("t2 count: \(t2.count)")
      print("t2 equal to old t2 ? \(t2 == oldT2)")
      let t3 = t2.not(net: net1, canonicityLevel: .full)
      print("t3 count: \(t3.count)")
      oldT2 = t2
    }
  }
  
//  func testERKCase3() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//
//    s.reset()
//
//    let key = "ERK-PT-000001-CTLFireability-03"
//    let formula = dicCTL[key]!
//    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
//    print(ctlReduced)
////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true)
//
//    print(ctlReduced.eval(marking: marking1))
//
//    print(s.elapsed.humanFormat)
//  }

  
//  func testERK() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//
//    s.reset()
//
//    var answers: [String: Bool] = [:]
//    var times: [String: String] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true).queryReduction()
//      print("-------------------------------")
//      print(key)
//      s.reset()
//      answers[key] = ctlReduced.eval(marking: marking1)
//      print(answers[key]!)
//      times[key] = s.elapsed.humanFormat
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
//      print("Formula \(key) is: \(b) (\(times[key]!))")
//    }
//
//    print(s.elapsed.humanFormat)
//  }
  
  //           0123456789012345
  // Expected: FTFTTTFTTFFFFTTF
  // Mine V6:  FTFTTTFTTFFFFTTF
  // Mine V5:  FTFTTFFTTFFFFTTF
  // Mine V4:  FTFTTTFTTFFFFTTF
  // Mine V3:  FTFTTTFTTFFFFTTT
  // Mine V2:  FTFTTTFTFFFFFTTT
  // Mine V1:  FTTTTTFTTTFFFTTT
  
//  func testSimpleLoadBal() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "CTLFireabilitySimpleLoadBal-2.xml")
//
//    print(net1.places)
//    print(net1.transitions)
//    print(net1.transitions.count)
//
////    let id = "SimpleLoadBal-PT-02-CTLFireability-15"
////    let ctl = dicCTL[id]!
//
//    var answers: [String: Bool] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, rewrited: false, debug: true).queryReduction()
//      print("-------------------------------")
//      print(key)
//      print(ctlReduced)
//      s.reset()
//      if ctlReduced.count() < 5 {
//        answers[key] = ctlReduced.eval(marking: marking1)
//        print("Is the formula true ? \(answers[key]!)")
//      }
////      ctlReduced.eval(net: net1)
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
//      print("Formula \(key) is: \(b)")
//    }
//  }
  
}
