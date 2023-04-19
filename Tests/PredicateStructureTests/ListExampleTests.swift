//import XCTest
////@testable import PredicateStructure
//import PredicateStructure
//
//final class ListExampleTests: XCTestCase {
//
//
//  func testSwimmingPool() {
//    let parser = PnmlParser()
//    var (net1, marking1) = parser.loadPN(filePath: "SwimmingPool-1.pnml")
//    var s = Stopwatch()
//    //     Example to observe that we do not need to compute EF fully to return true.
//    //     Thanks to the lowest fixpoint, at each step, the state space can only grow.
//    //     Hence, if the marking belong to the predicate structure at any point of the iterations, we can return an early answer.
//    //     The additional optimisation happens when eval is called with the given marking
//    XCTAssertFalse(CTL.EU(.isFireable("GetB"), .isFireable("RBag")).eval(marking: marking1, net: net1))
//    print(s.elapsed.humanFormat)
//    s.reset()
//    XCTAssertTrue(CTL.not(.AF(.not(.EF(.isFireable("GetB"))))).eval(marking: marking1, net: net1))
//    print(s.elapsed.humanFormat)
//
//    marking1["Out"] = 2
//    marking1["Cabins"] = 1
//    marking1["Bags"] = 2
//
//    let efCTL: CTL = .not(.EF(.isFireable("RBag")))
//    XCTAssertFalse(efCTL.eval(marking: marking1, net: net1))
//    XCTAssertFalse(CTL.AG(.isFireable("RBag")).eval(marking: marking1, net: net1))
//
//    marking1["Cabins"] = 0
//    XCTAssertTrue(efCTL.eval(marking: marking1, net: net1))
//
//  }
//
//  func testSwimmingPool2() {
//    let p1 = PnmlParser()
//    var (net1, marking1) = p1.loadPN(filePath: "SwimmingPool-1.pnml")
//    var s: Stopwatch = Stopwatch()
//
//    print(net1.places)
//    // Query after reduction: EF (not EF (1 <= SwimmingPool_dash_PT_dash_01_Undress))
////    let ctl: CTL = .EF(.not(.EF(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("Undress")))))
////    let ctl: CTL = .not(.deadlock)
//    let ctl: CTL = .AG(.not(.deadlock))
////      let ctl: CTL = .not(.deadlock)
////    let ctl: CTL = .not(.EF(.deadlock))
////    let ctl: CTL = .EF(.deadlock)
//
////    AF (not EF ((SwimmingPool_dash_PT_dash_01_InBath <= 13) or (8 < SwimmingPool_dash_PT_dash_01_Undress)))
////    let ctl: CTL = .AF(.not(.EF(.or(.intExpr(e1: .tokenCount("InBath"), operator: .leq, e2: .value(13)), .intExpr(e1: .value(8), operator: .lt, e2: .tokenCount("Undress"))))))
//
////    marking1["Out"] = 2
////    marking1["Cabins"] = 1
////    marking1["Bags"] = 2
//
////    let ctl: CTL = .AG(.isFireable("RBag"))
//
////    s.reset()
//////    print(ctl.eval(marking: marking1, net: net1))
////    print(ctl.eval(net: net1).count)
////    print(s.elapsed.humanFormat)
//    
//    s.reset()
//    let e = ctl.eval(net: net1)
//    print(s.elapsed.humanFormat)
////    let spsAll = SPS(values: [PS(value: ([net1.zeroMarking()], []), net: net1)])
////    s.reset()
//////    print(e.not().isEquiv(spsAll.subtract(e)))
////    e.not()
////    print(s.elapsed.humanFormat)
////    s.reset()
////    spsAll.subtract(e)
////    print(s.elapsed.humanFormat)
//  }
//
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
//    let ctl: CTL = .AG(.not(.deadlock))
//    let marking = Marking(["p1": 3, "p2": 0, "p3": 0, "p4": 1, "p5": 2], net: net)
//    var timer = Stopwatch()
//    for i in 0 ..< 10 {
////      print(ctl.eval(net: net))
//      print(ctl.eval(marking: marking, net: net, rewrited: true))
//      print(timer.elapsed.humanFormat)
//    }
//    print("Final time: \(timer.elapsed.humanFormat)")
//
////    timer.reset()
////    print(ctl.eval(marking: marking, net: net))
////    print(timer.elapsed.humanFormat)
//
//  }
//
//  func testERK() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//
////    let id = "ERK-PT-000001-CTLFireability-15"
////    let ctl = dicCTL[id]!
////
////    print("Formula: \(ctl)")
////    s.reset()
////    print("Answer: \(ctl.eval(marking: marking1, net: net1))")
////    print(s.elapsed.humanFormat)
//    
////    let ctl: CTL = .AG(.AG(.EG(.or(.not(.isFireable("r2")), .not(.and(.isFireable("r6"), .isFireable("r1")))))))
//    
//////    let ctl: CTL = .EG(.or(.not(.isFireable("r2")), .not(.and(.isFireable("r6"), .isFireable("r1")))))
////
//////    let ctl: CTL = .AX(.or(.isFireable("r2"), .isFireable("r6")))
////    let ctl: CTL = .AX(.or(.isFireable("r2"), .isFireable("r6")))
////    let ctlReduc = ctl.queryReduction()
////
////    let x = ctl.eval(net: net1, rewrited: false)
////    let y = ctl.eval(net: net1, rewrited: true)
////
////    let markingCap = Marking(net1.capacity, net: net1)
////    let ps0 = PS(value: ([], [markingCap]), net: net1)
////    let sps0 = SPS(values: [ps0])
////
////    let xp = x.intersection(sps0)
////    let yp = x.intersection(sps0)
////
////    print(x.isIncluded(y))
////    print(y.isIncluded(x))
////
////    print("---------------")
////
////    print(x.isIncluded(yp))
////    print(yp.isIncluded(x))
////
////    print("---------------")
////    print(x.count)
////    print(y.count)
////    print(x)
////    print(y)
////    print("---------------")
////    print(yp.count)
////    print(yp)
////    print("---------------")
////    print(x.contains(marking: marking1))
////    print(y.contains(marking: marking1))
////    print(yp.contains(marking: marking1))
////    print("---------------")
//    
//    
//    s.reset()
//
//    var answers: [String: Bool] = [:]
//    for (key, ctl) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = ctl.queryReduction()
//      print("-------------------------------")
//      print(key)
////      print(ctlReduced)
//      s.reset()
//      answers[key] = ctlReduced.eval(marking: marking1, net: net1, rewrited: true)
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
//      print("Formula \(key) is: \(b)")
//    }
//
//    print(s.elapsed.humanFormat)
//  }
//  //           0123456789012345
//  // Expected: FTFTTTFTTFFFFTTF
//  // Mine V3:  FTFTTTFTTFFFFTTT
//  // Mine V2:  FTFTTTFTFFFFFTTT
//  // Mine V1:  FTTTTTFTTTFFFTTT
//  
//
//  func testERK2() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//    
//    print("Marking: \(marking1)")
//    let ctl: CTL = .AG(.not(.deadlock))
//    
//    s.reset()
//    ctl.eval(marking: marking1, net: net1, rewrited: false)
//    print("TIME FOR AG")
//    print(s.elapsed.humanFormat)
//  }
//  
//  
//  func testSimpleLoadBal() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
//    var s = Stopwatch()
//
////    print(marking1)
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "CTLFireabilitySimpleLoadBal-2.xml")
////    print(dicCTL)
////    let key = "ERK-PT-000001-CTLFireability-08"
////    let ctl = dicCTL[key]!
//
////    let ctl: CTL = .AG(.not(.deadlock))
////    let ctl: CTL = .not(.EF(.deadlock))
////    let ctl: CTL = .deadlock
//
//    print(net1.places)
//    print(net1.transitions)
//    print(net1.transitions.count)
//
////    // For not(EF(deadlock)): nb ps: 22/26, nb underlying markings: 1358
////    // For AF(not(deadlock)): nb ps/um: 119/636, 115/655
////    s.reset()
////    print(ctl.eval(marking: marking1, net: net1))
////    print(s.elapsed.humanFormat)
//
//    let id = "SimpleLoadBal-PT-02-CTLFireability-15"
//    let ctl = dicCTL[id]!
//
////    print(ctl)
////    print(ctl.eval(net: net1))
//
//    var answers: [String: Bool] = [:]
//    for (key, ctl) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = ctl.queryReduction()
//      print("-------------------------------")
//      print(key)
//      print(ctlReduced)
//      s.reset()
//      if ctlReduced.count() < 10 {
//        answers[key] = ctlReduced.eval(marking: marking1, net: net1)
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
//  
//  func testPreForAllDiff() {
//    let parserPN = PnmlParser()
//    let (net1, _) = parserPN.loadPN(filePath: "ERK-CTLFireability_v3.pnml")
//
////    let parserCTL = CTLParser()
////    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//
//    print(net1.places)
//    print(net1.transitions)
//
//    let ctl: CTL = .AG(.or(.isFireable("r7"), .isFireable("r6")))
//    let ctlReduc = ctl.queryReduction()
//    
//    print(ctl)
//    print(ctlReduc)
//    
//    print("----------")
//    let m0: Marking = Marking(["ERK": 0, "MEKPP": 0, "MEKPP_ERK": 0], net: net1)
//    let m1: Marking = Marking(["ERK": 1, "MEKPP": 1, "MEKPP_ERK": 0], net: net1)
//    let m2: Marking = Marking(["ERK": 1, "MEKPP": 1, "MEKPP_ERK": 1], net: net1)
//    let m3: Marking = Marking(["ERK": 0, "MEKPP": 0, "MEKPP_ERK": 1], net: net1)
//
//    let pExpected0 = PS(value: ([m0], []), net: net1)
//    let pExpected1 = PS(value: ([m0], [m2]), net: net1)
//    let p0 = PS(value: ([m1], [m2]), net: net1)
//    let p1 = PS(value: ([m3], [m2]), net: net1)
//    let p2 = PS(value: ([m0], [m1,m3]), net: net1)
//
//    let spsExpected0 = SPS(values: [pExpected0])
//    let spsExpected1 = SPS(values: [pExpected1])
//    let sps0 = SPS(values: [p0,p1,p2])
//
//    // BE CAREFUL:
//    // False because the bound does not appear in the context of not revert not
//    print(spsExpected0.isIncluded(sps0))
//    print(sps0.isIncluded(spsExpected0))
//    
//    // True because we include the bound
//    print(spsExpected1.isIncluded(sps0))
//    print(sps0.isIncluded(spsExpected1))
//  }
//  
//}
