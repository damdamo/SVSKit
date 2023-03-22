import XCTest
//@testable import PredicateStructure
import PredicateStructure

final class ListExampleTests: XCTestCase {
  
  
  func testSwimmingPool() {
    let parser = PnmlParser()
    let (net1, marking1) = parser.loadPN(filePath: "SwimmingPool-1.pnml")
    
    //     Example to observe that we do not need to compute EF fully to return true.
    //     Thanks to the lowest fixpoint, at each step, the state space can only grow.
    //     Hence, if the marking belong to the predicate structure at any point of the iterations, we can return an early answer.
    //     The additional optimisation happens when eval is called with the given marking
    XCTAssertFalse(CTL.EU(.isFireable("GetB"), .isFireable("RBag")).eval(marking: marking1, net: net1))
    XCTAssertTrue(CTL.not(.AF(.not(.EF(.isFireable("GetB"))))).eval(marking: marking1, net: net1))
  }
  
  func testSwimmingPool2() {
    let p1 = PnmlParser()
    let (net1, marking1) = p1.loadPN(filePath: "SwimmingPool-1.pnml")
    var s: Stopwatch = Stopwatch()

    //
    //    let ctlFormula1: CTL = .EX(.ap("RBag"))
    //    let eval1 = ctlFormula1.eval(net: net1).simplified()
    //    print(eval1)
    //    print("Nb d'états: \(eval1.count)")
    //
    //    print("---------------------------------")
    //
    //    let ctlFormula2: CTL = .AX(.ap("RBag"))
    //    let eval2 = ctlFormula2.eval(net: net1).simplified()
    //    print(eval2)
    //    print("Nb d'états: \(eval2.count)")
    //
    //    let ctlFormula3: CTL = .AXBis(.ap("RBag"))
    //    let eval3 = ctlFormula3.eval(net: net1).simplified()
    //    print(eval3)
    //    print("Nb d'états: \(eval3.count)")

//    let ctlFormula4: CTL = .and(.isFireable("GetK"), .not(.isFireable("RBag")))
//    let eval4 = ctlFormula4.eval(net: net1)
//    s.reset()
//    let r1 = eval4.revertTilde(rewrited: true)
//    print(r1.count)
//    print(s.elapsed.humanFormat)
//    s.reset()
//    let r2 = eval4.revertTilde(rewrited: false).revertTilde(rewrited: false).revertTilde(rewrited: false).revertTilde(rewrited: false).revertTilde(rewrited: false)
//    print(CTL.AX(.AX(.AX(.AX(.AX(ctlFormula4))))).eval(marking: marking1, net: net1))
//    print(s.elapsed.humanFormat)
  }
  
  func testTapaal() {
    let p1 = PnmlParser()
    let (net1, marking1) = p1.loadPN(filePath: "angiogenesis.pnml")
    let ctlFormula1: CTL = .EF(.AG(.EF(.not(.AX(.and(.isFireable("k50"), .isFireable("k49")))))))

    let ctlFormula1Reduced = ctlFormula1.queryReduction()

    print(marking1)
    print(ctlFormula1.queryReduction())

//    print(ctlFormula1Reduced.eval(marking: marking1, net: net1))
  }
  
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
    
//    let ctl: CTL = .AG(.not(.deadlock))
//    let marking = Marking(["p1": 3, "p2": 0, "p3": 0, "p4": 1, "p5": 2], net: net)
//    var timer = Stopwatch()
//    print(ctl.eval(net: net))
//    print(timer.elapsed.humanFormat)
//    timer.reset()
//    print(ctl.eval(marking: marking, net: net))
//    print(timer.elapsed.humanFormat)
    
  }
  
    
}
