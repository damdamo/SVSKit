//import XCTest
////@testable import PredicateStructure
//import SVSKit
//
//final class ListExampleTests: XCTestCase {
//
//  func standardDeviationUInt64(seq:[UInt64]) -> Double {
//    
//    var listDouble: [Double] = []
//    for v in seq {
//      listDouble.append(Stopwatch.TimeInterval(ns: v).toMs)
//    }
//          
//    let size: Double = Double(seq.count)
//    var sum = 0.0
//    var SD = 0.0
//    var S = 0.0
//    var resultSD = 0.0
//
//    // Calculating the mean
//    for x in 0 ..< Int(size) {
//      sum += listDouble[x]
//    }
//    let meanValue = sum/size
//
//    // Calculating standard deviation
//    for y in 0 ..< Int(size) {
//      SD += pow(Double(listDouble[y] - meanValue), 2)
//    }
//    S = SD/Double(size)
//    resultSD = sqrt(S)
//    
//    return Double(resultSD)
//  }
//  
//  func standardDeviationInt(seq:[Int]) -> Double {
//     let size = seq.count
//     var sum = 0
//     var SD = 0.0
//     var S = 0.0
//     var resultSD = 0.0
//     
//     // Calculating the mean
//     for x in 0..<size{
//        sum += seq[x]
//     }
//     let meanValue = sum/size
//     
//     // Calculating standard deviation
//     for y in 0..<size{
//        SD += pow(Double(seq[y] - meanValue), 2)
//     }
//     S = SD/Double(size)
//     resultSD = sqrt(S)
//     
//     return resultSD
//  }
//  
////  func testSwimmingPool() {
////    let parser = PnmlParser()
////    var (net1, marking1) = parser.loadPN(filePath: "SwimmingPool-1.pnml")
////    var s = Stopwatch()
////    //     Example to observe that we do not need to compute EF fully to return true.
////    //     Thanks to the lowest fixpoint, at each step, the state space can only grow.
////    //     Hence, if the marking belong to the predicate structure at any point of the iterations, we can return an early answer.
////    //     The additional optimisation happens when eval is called with the given marking
////    let ctl1 = CTL(formula: .EU(.isFireable("GetB"), .isFireable("RBag")), net: net1, canonicityLevel: .semi)
////    let ctl2 = CTL(formula: .not(.AF(.not(.EF(.isFireable("GetB"))))), net: net1, canonicityLevel: .semi, simplified: false, debug: false)
////    XCTAssertFalse(ctl1.eval(marking: marking1))
////    print(s.elapsed.humanFormat)
////    s.reset()
////    XCTAssertTrue(ctl2.eval(marking: marking1))
////    print(s.elapsed.humanFormat)
////
////    marking1["Out"] = 2
////    marking1["Cabins"] = 1
////    marking1["Bags"] = 2
////
////    let efCTL = CTL(formula: .not(.EF(.isFireable("RBag"))), net: net1, canonicityLevel: .none)
////    let agCTL = CTL(formula: .AG(.isFireable("RBag")), net: net1, canonicityLevel: .none)
////    XCTAssertFalse(efCTL.eval(marking: marking1))
////    XCTAssertFalse(agCTL.eval(marking: marking1))
////
////    marking1["Cabins"] = 0
////    XCTAssertTrue(efCTL.eval(marking: marking1))
////
////  }
//
//  func testSwimmingPool() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "SwimmingPool-1.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ReachabilityFireabilitySwimmingPool.xml")
//
//    s.reset()
//
//    print("Transitions: \(net1.transitions)")
//    var answers: [String: Bool] = [:]
////    var answers: [String: SVS] = [:]
//    var times: [String: String] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
////      print(ctlReduced)
//      print("-------------------------------")
//      print(key)
//      s.reset()
//      answers[key] = ctlReduced.eval(marking: marking1)
////      answers[key] = ctlReduced.eval()
//      print(answers[key]!)
//      times[key] = s.elapsed.humanFormat
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
//      print("Formula \(key) is: \(b) (\(times[key]!))")
////      print("Formula \(key) is: \(times[key]!)")
//    }
//
//    print(s.elapsed.humanFormat)
//  }
//  
//  // FFFTFFFTTTFTFFFF
//  // ffftfffttfffffff
//  
////  func testDeadlock() {
////    // Example 1 of paper: https://journals.sagepub.com/doi/10.1177/1687814017693542
////    let net = PetriNet(
////      places: ["p1", "p2", "p3", "p4", "p5"],
////      transitions: ["t1", "t2", "t3"],
////      arcs: .pre(from: "p1", to: "t1", labeled: 1),
////      .pre(from: "p5", to: "t1", labeled: 1),
////      .post(from: "t1", to: "p2", labeled: 1),
////      .pre(from: "p2", to: "t2", labeled: 1),
////      .pre(from: "p4", to: "t2", labeled: 1),
////      .pre(from: "p5", to: "t2", labeled: 1),
////      .post(from: "t2", to: "p3", labeled: 1),
////      .pre(from: "p3", to: "t3", labeled: 1),
////      .post(from: "t3", to: "p5", labeled: 2),
////      .post(from: "t3", to: "p4", labeled: 1),
////      .post(from: "t3", to: "p1", labeled: 1)
////    )
////
////    let ctl: CTL = CTL(formula: .EG(.not(.deadlock)), net: net, rewrited: false)
////    let marking = Marking(["p1": 3, "p2": 0, "p3": 0, "p4": 1, "p5": 2], net: net)
////    var timer = Stopwatch()
////    for _ in 0 ..< 10 {
////      print(ctl.eval(marking: marking))
////      print(timer.elapsed.humanFormat)
////    }
////    print("Final time: \(timer.elapsed.humanFormat)")
////
////  }
//
////  func testERKCaseSpecific() {
////    let parserPN = PnmlParser()
////    var (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
////    var s = Stopwatch()
////
////    let parserCTL = CTLParser()
////
////    s.reset()
////
////    let ctlReduced: CTL = CTL(formula: .EF(.isFireable("r3")), net: net1, canonicityLevel: .full, debug: true).queryReduction()
////    print(ctlReduced)
//////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true)
////
////    let e1 = ctlReduced.eval()
//////    let e2 = ctlReduced.eval()
//////
//////    print("----------------------")
//////    print(e1)
//////    print("----------------------")
//////    print(e2)
//////    print("----------------------")
//////    print(SVS(values: e1.values.subtracting(e2.values)))
//////
//////    print(e1 == e2)
//////    print(e1.isEquiv(e2))
////    var oldT2: SVS = []
////    for _ in 0 ..< 10 {
////      let t1 = e1.not(net: net1, canonicityLevel: .full)
////      print("t1 count: \(t1.count)")
////      let t2 = t1.revert(canonicityLevel: .full)
////      print("t2 count: \(t2.count)")
////      print("t2 equal to old t2 ? \(t2 == oldT2)")
////      let t3 = t2.not(net: net1, canonicityLevel: .full)
////      print("t3 count: \(t3.count)")
////      oldT2 = t2
////    }
////  }
//  
//  func testERKPerformance() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//
//
//    let key = "ERK-PT-000001-CTLFireability-15"
//    let formula = dicCTL[key]!
////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false).queryReduction()
//    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false)
////    print(ctlReduced)
//
//
//    s.reset()
//
//    for i in 0 ..< 10 {
//      print(i)
//      ctlReduced.eval(marking: marking1)
//    }
//
//    print("Average: \(s.elapsed.s/10)")
//    print(s.elapsed.humanFormat)
//  }
////
//  func testERKCase15() {
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
////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true)
//    print(ctlReduced)
//
//
////    print(ctlReduced.eval(marking: marking1))
//    let x = ctlReduced.eval()
//    
//    var total = 0
//    
//    for ps in x {
//      print(ps.value.exc.count)
//      total = total + ps.value.exc.count
//    }
//    
//    print("AVG: \(total/x.count)")
//
//
//    print(s.elapsed.humanFormat)
//  }
//
//  
//  func testERKBenchmarkGeneral() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//    let loopNb: UInt64 = 10
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-CTLFireability.xml")
//
//    s.reset()
//
//    var answers: [String: SVS] = [:]
//    var times: [String: [UInt64]] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false).queryReduction()
//      print("-------------------------------")
//      print(key)
//      for _ in 0 ..< loopNb {
//        s.reset()
//        answers[key] = ctlReduced.eval()
//        if let x = times[key] {
//          times[key]!.append(s.elapsed.ns)
//        } else {
//          times[key] = [s.elapsed.ns]
//        }
//        
//      }
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    var avgTime = 0.0
//    var avgSTD = 0.0
//    for (key, _) in answers.sorted(by: {$0.key < $1.key}) {
//      let t = times[key]!.reduce(0, {$0 + $1})/loopNb
//      let time = Stopwatch.TimeInterval(ns: t)
//      let std = standardDeviationUInt64(seq: times[key]!)
//      print("Formula \(key) is: \(time.humanFormat)")
//      print("Standard deviation: \(std) ms")
//      avgTime += time.s
//      avgSTD += std
//    }
//
//    print("AVG TIME: \(avgTime/Double(times.keys.count)) s")
//    print("AVG STD: \(avgSTD/Double(times.keys.count)) ms")
//  }
//  
//  func testERKBenchmarkReachability() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//    let loopNb: UInt64 = 10
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-ReachabilityFireability.xml")
//
//    s.reset()
//
//    var answers: [String: SVS] = [:]
//    var times: [String: [UInt64]] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false).queryReduction()
//      print("-------------------------------")
//      print(key)
//      for _ in 0 ..< loopNb {
//        s.reset()
//        answers[key] = ctlReduced.eval()
//        if let x = times[key] {
//          times[key]!.append(s.elapsed.ns)
//        } else {
//          times[key] = [s.elapsed.ns]
//        }
//        
//      }
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    for (key, _) in answers.sorted(by: {$0.key < $1.key}) {
//      let t = times[key]!.reduce(0, {$0 + $1})/loopNb
//      let time = Stopwatch.TimeInterval(ns: t)
//      print("Formula \(key) is: \(time.humanFormat)")
//      print("Standard deviation: \(standardDeviationUInt64(seq: times[key]!)) ms")
//    }
//
//    print(s.elapsed.humanFormat)
//  }
//  
//  
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
////    var answers: [String: Bool] = [:]
//    var answers: [String: SVS] = [:]
//    var times: [String: String] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
//      print("-------------------------------")
//      print(key)
//      s.reset()
////      answers[key] = ctlReduced.eval(marking: marking1)
//      answers[key] = ctlReduced.eval()
//      print(answers[key]!)
//      times[key] = s.elapsed.humanFormat
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    var svNumbers: [Int] = []
//    var markingNumbers: [Int] = []
////    var count = 0
//    
//    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
////      print("Formula \(key) is: \(b) (\(times[key]!))")
//      print("Formula \(key) is: \(times[key]!)")
//      print("Nb of sv: \(answers[key]!.count)")
//      svNumbers.append(answers[key]!.count)
//      for sv in answers[key]! {
////        count += 1
//        markingNumbers.append(1 + sv.value.exc.count)
//      }
//    }
//
//    let avgMarking = Double(markingNumbers.reduce(0, {$0+$1})) / Double(markingNumbers.count)
//    let avgSV = Double(svNumbers.reduce(0, {$0+$1})) / Double(svNumbers.count)
//  
//    print("Nb average SV: \(avgSV)")
//    print("Nb average marking: \(avgMarking)")
//    print("Std sv: \(standardDeviationInt(seq: svNumbers))")
//    print("Std marking: \(standardDeviationInt(seq: markingNumbers))")
//  }
//  
//  //           0123456789012345
//  // Expected: FTFTTTFTTFFFFTTF
//  // Mine V6:  FTFTTTFTTFFFFTTF
//  // Mine V5:  FTFTTFFTTFFFFTTF
//  // Mine V4:  FTFTTTFTTFFFFTTF
//  // Mine V3:  FTFTTTFTTFFFFTTT
//  // Mine V2:  FTFTTTFTFFFFFTTT
//  // Mine V1:  FTTTTTFTTTFFFTTT
//  
//  // ME: FTFTTFFTFFFFTFFT
//  //     FFFTTFFFFFFFFTFF
//  //     +-+++++-++++--+-
//  func testTwoPhaseLocking() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "twoPhaseLocking-model.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "TwoPhaseLocking-CTLFireability.xml")
//
//    s.reset()
//
//    let formula = dicCTL["TwoPhaseLocking-PT-nC00004vD-CTLFireability-01"]!
//    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true)
//    print(ctlReduced.eval(marking: marking1))
//    
////    var answers: [String: Bool] = [:]
//////    var answers: [String: SVS] = [:]
////    var times: [String: String] = [:]
////    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
////      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
////      print("-------------------------------")
////      print(key)
////      print("CTLReduced: \(ctlReduced)")
////      s.reset()
////      answers[key] = ctlReduced.eval(marking: marking1)
//////      answers[key] = ctlReduced.eval()
////      print(answers[key]!)
////      times[key] = s.elapsed.humanFormat
////      print(s.elapsed.humanFormat)
////      print("-------------------------------")
////    }
////
////    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
////      print("Formula \(key) is: \(b) (\(times[key]!))")
//////      print("Formula \(key) is: \(times[key]!)")
////    }
//
//    print(s.elapsed.humanFormat)
//  }
//  
//  func testERKReachability() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "ERK-ReachabilityFireability.xml")
//
//    s.reset()
//
//    var answers: [String: Bool] = [:]
////    var answers: [String: SVS] = [:]
//    var times: [String: String] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false).queryReduction()
//      print("-------------------------------")
//      print(key)
//      print(ctlReduced)
//      s.reset()
//      answers[key] = ctlReduced.eval(marking: marking1)
////      answers[key] = ctlReduced.eval()
//      print(answers[key]!)
//      times[key] = s.elapsed.humanFormat
//      print(s.elapsed.humanFormat)
//      print("-------------------------------")
//    }
//
//    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
//      print("Formula \(key) is: \(b) (\(times[key]!))")
////      print("Formula \(key) is: \(times[key]!)")
//    }
//
//    print(s.elapsed.humanFormat)
//  }
//  
//  // FTFTFTFTTTFFFFFF
//  // ftftftftttffffff
//  
////  func testSimpleLoadBal() {
////    let parserPN = PnmlParser()
////    var (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
////    var s = Stopwatch()
////
////    let parserCTL = CTLParser()
////    let dicCTL = parserCTL.loadCTL(filePath: "CTLFireabilitySimpleLoadBal-2.xml")
////
////    print(net1.places)
////    print(net1.transitions)
////    print(net1.transitions.count)
////
//////    let id = "SimpleLoadBal-PT-02-CTLFireability-15"
//////    let ctl = dicCTL[id]!
////
////    var answers: [String: Bool] = [:]
////    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
////      let ctlReduced = CTL(formula: formula, net: net1, rewrited: false, debug: true).queryReduction()
////      print("-------------------------------")
////      print(key)
////      print(ctlReduced)
////      s.reset()
////      if ctlReduced.count() < 5 {
////        answers[key] = ctlReduced.eval(marking: marking1)
////        print("Is the formula true ? \(answers[key]!)")
////      }
//////      ctlReduced.eval(net: net1)
////      print(s.elapsed.humanFormat)
////      print("-------------------------------")
////    }
////
////    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
////      print("Formula \(key) is: \(b)")
////    }
////  }
////  func testLoadBal() {
////    let parserPN = PnmlParser()
//////    let (net1, marking1) = parserPN.loadPN(filePath: "ERK-CTLFireability.pnml")
////    let (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
////    var s = Stopwatch()
////
////    let parserCTL = CTLParser()
////    let dicCTL = parserCTL.loadCTL(filePath: "CTLFireabilitySimpleLoadBal-2.xml")
////
////    s.reset()
////
////    var answers: [String: Bool] = [:]
//////    var answers: [String: SVS] = [:]
////    var times: [String: String] = [:]
////    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
////      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
////      print("-------------------------------")
////      print(key)
////      s.reset()
////      answers[key] = ctlReduced.eval(marking: marking1)
//////      answers[key] = ctlReduced.eval()
////      print(answers[key]!)
////      times[key] = s.elapsed.humanFormat
////      print(s.elapsed.humanFormat)
////      print("-------------------------------")
////    }
////
////    for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
////      print("Formula \(key) is: \(b) (\(times[key]!))")
//////      print("Formula \(key) is: \(times[key]!)")
////    }
////
////    print(s.elapsed.humanFormat)
////  }
//  
//  func testLoadBalCase() {
//    let parserPN = PnmlParser()
//    var (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "CTLFireabilitySimpleLoadBal-2.xml")
//
//    s.reset()
//
//    let key = "SimpleLoadBal-PT-02-CTLFireability-02"
//    let formula = dicCTL[key]!
////    let formula: CTL.Formula = .deadlock
//    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true)
//    
//    print(net1.places.count)
//    print(net1.transitions.count)
//        
//    print("-------------------")
//    
//    print(net1.places.count)
//    print(net1.transitions.count)
//    
//    
//
//
////    print(ctlReduced.eval(marking: marking1))
//    print(ctlReduced.eval())
//
//
//    print(s.elapsed.humanFormat)
//  }
//
//    func testLoadBalReachability() {
//      let parserPN = PnmlParser()
//      let (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
//      var s = Stopwatch()
//
//      let parserCTL = CTLParser()
//      let dicCTL = parserCTL.loadCTL(filePath: "SimpleLoadBal-ReachabilityFireability.xml")
//
//      print(net1.places.count)
//      print(net1.transitions.count)
//
//      s.reset()
//
////      var answers: [String: Bool] = [:]
//      var answers: [String: SVS] = [:]
//      var times: [String: String] = [:]
//      for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//        let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
//        print("-------------------------------")
//        print(key)
//        print("Query: \(ctlReduced)")
//        s.reset()
////        answers[key] = ctlReduced.eval(marking: marking1)
////        answers[key] = ctlReduced.eval()
////        print(answers[key]!)
//        times[key] = s.elapsed.humanFormat
//        print(s.elapsed.humanFormat)
//        print("-------------------------------")
//      }
//
//      for (key, b) in answers.sorted(by: {$0.key < $1.key}) {
////        print("Formula \(key) is: \(b) (\(times[key]!))")
//        print("Formula \(key) is: \(times[key]!)")
//      }
//
//      print(s.elapsed.humanFormat)
//    }
//  
//  // 00 (96sec): 0
//  // 01 (180/120sec): 1
//  // 09 good (22sec): 0 !
//  // 14 good
//  func testLoadBalReachabilityOne() {
//    let parserPN = PnmlParser()
//    let (net1, marking1) = parserPN.loadPN(filePath: "simpleLoadBal-2.pnml")
//    var s = Stopwatch()
//
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: "SimpleLoadBal-ReachabilityFireability.xml")
//
//    print(net1.places.count)
//    print(net1.transitions.count)
//    
//    let key = "SimpleLoadBal-PT-02-ReachabilityFireability-01"
//    let formula = dicCTL[key]!
//    let ctl = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: false, debug: true).queryReduction()
//    
//    s.reset()
//    
//    let svs = ctl.eval()
//
//    print(s.elapsed.humanFormat)
//    
//    print(svs.count)
//    print(svs.contains(marking: marking1))
//    
//    s.reset()
//    let can = svs.canonised()
//    print(s.elapsed.humanFormat)
//    
//    print(svs == can)
//
//  }
//  
////
////  func testIotpPurchase() {
////    let parserPN = PnmlParser()
////    var (net1, _) = parserPN.loadPN(filePath: "des.pnml")
////    var s = Stopwatch()
////
////    s.reset()
////
//////    let formula = dicCTL[key]!
////    let formula: CTL.Formula = .deadlock
////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true)
//////    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .none, simplified: true, debug: true)
////    print(ctlReduced)
////
////    print(net1.places.count)
////    print(net1.transitions.count)
//////    print(ctlReduced.eval(marking: marking1))
////    let x = ctlReduced.eval()
////    print(x.first!.value.exc.count)
////    print(x.count)
////
////
////    print(s.elapsed.humanFormat)
////  }
//  
//}
