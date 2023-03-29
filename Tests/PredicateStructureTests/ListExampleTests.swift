import XCTest
//@testable import PredicateStructure
import PredicateStructure

final class ListExampleTests: XCTestCase {
  
  
  func testSwimmingPool() {
    let parser = PnmlParser()
    let (net1, marking1) = parser.loadPN(filePath: "SwimmingPool-1.pnml")
    var s = Stopwatch()
    //     Example to observe that we do not need to compute EF fully to return true.
    //     Thanks to the lowest fixpoint, at each step, the state space can only grow.
    //     Hence, if the marking belong to the predicate structure at any point of the iterations, we can return an early answer.
    //     The additional optimisation happens when eval is called with the given marking
    XCTAssertFalse(CTL.EU(.isFireable("GetB"), .isFireable("RBag")).eval(marking: marking1, net: net1))
    print(s.elapsed.humanFormat)
    s.reset()
    XCTAssertTrue(CTL.not(.AF(.not(.EF(.isFireable("GetB"))))).eval(marking: marking1, net: net1))
    print(s.elapsed.humanFormat)
  }
  
  func testSwimmingPool2() {
    let p1 = PnmlParser()
    let (net1, marking1) = p1.loadPN(filePath: "SwimmingPool-1.pnml")
    var s: Stopwatch = Stopwatch()

    // Query after reduction: EF (not EF (1 <= SwimmingPool_dash_PT_dash_01_Undress))
    let ctl: CTL = .EF(.not(.EF(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("Undress")))))
//    let ctl: CTL = .AG(.not(.deadlock))
//    AF (not EF ((SwimmingPool_dash_PT_dash_01_InBath <= 13) or (8 < SwimmingPool_dash_PT_dash_01_Undress)))
//    let ctl: CTL = .AF(.not(.EF(.or(.intExpr(e1: .tokenCount("InBath"), operator: .leq, e2: .value(13)), .intExpr(e1: .value(8), operator: .lt, e2: .tokenCount("Undress"))))))
    s.reset()
//    ctl.eval(marking: marking1, net: net1)
//    print(ctl.eval(net: net1).count)
    print(s.elapsed.humanFormat)
  }
  
//  func testTapaal() {
//    let p1 = PnmlParser()
//    let (net1, marking1) = p1.loadPN(filePath: "angiogenesis.pnml")
//    let ctlFormula1: CTL = .EF(.AG(.EF(.not(.AX(.and(.isFireable("k50"), .isFireable("k49")))))))
//
//    let ctlFormula1Reduced = ctlFormula1.queryReduction()
//
//    print(marking1)
//    print(ctlFormula1.queryReduction())
//
////    print(ctlFormula1Reduced.eval(marking: marking1, net: net1))
//  }
  
  func testDeadlock() {
    // Example 1 of paper: https://journals.sagepub.com/doi/10.1177/1687814017693542
    let net = PetriNet(
      places: ["p1", "p2", "p3", "p4", "p5"],
      transitions: ["t1", "t2", "t3"],
      arcs: .pre(from: "p1", to: "t1", labeled: 1),
      .pre(from: "p5", to: "t1", labeled: 1),
      .post(from: "t1", to: "p2", labeled: 1),
      .pre(from: "p2", to: "t2", labeled: 1),
      .pre(from: "p4", to: "t2", labeled: 1),
      .pre(from: "p5", to: "t2", labeled: 1),
      .post(from: "t2", to: "p3", labeled: 1),
      .pre(from: "p3", to: "t3", labeled: 1),
      .post(from: "t3", to: "p5", labeled: 2),
      .post(from: "t3", to: "p4", labeled: 1),
      .post(from: "t3", to: "p1", labeled: 1)
    )
    
    let ctl: CTL = .AG(.not(.deadlock))
    let marking = Marking(["p1": 3, "p2": 0, "p3": 0, "p4": 1, "p5": 2], net: net)
    var timer = Stopwatch()
    for i in 0 ..< 10 {
      ctl.eval(net: net) 
//      ctl.eval(marking: marking, net: net)
      print(timer.elapsed.humanFormat)
    }
    print("Final time: \(timer.elapsed)")
    
//    timer.reset()
//    print(ctl.eval(marking: marking, net: net))
//    print(timer.elapsed.humanFormat)
    
  }
  
  func testERK() {
    let parserPN = PnmlParser()
    let (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
    var s = Stopwatch()
    
//    print(marking1)
    
    let parserCTL = CTLParser()
    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//    print(dicCTL)
    let key = "ERK-PT-000001-CTLFireability-08"
    let ctl = dicCTL[key]!
//    for (key, ctl) in dicCTL {
      let ctlReduced = ctl.queryReduction()
      print(key)
      print(ctlReduced)
//      print(ctlReduced.eval(net: net1))
//    }
  }
  
    
}
