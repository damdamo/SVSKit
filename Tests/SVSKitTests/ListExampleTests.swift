//import XCTest
////@testable import PredicateStructure
//import SVSKit
//
//final class ListExampleTests: XCTestCase {
//
//  let resourcesDirectory = "/Users/damienmorard/Developer/Github/SymbolicVectorSet/Sources/SVSKit/Resources/"
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
//  func testSwimmingPool() {
//    let parserPN = PnmlParser()
//    let pnmlPath = resourcesDirectory + "SwimmingPool/SwimmingPool-1.pnml"
//    
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    print(net1)
//    print(marking1)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "SwimmingPool/ReachabilityFireabilitySwimmingPool.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//  func testERKPerformance() {
//    let parserPN = PnmlParser()
//    let pnmlPath = resourcesDirectory + "ERK/ERK-CTLFireability.pnml"
//    var (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "ERK/ERK-CTLFireability.xml"
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
//    let pnmlPath = resourcesDirectory + "ERK/ERK-CTLFireability.pnml"
//    var (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
////    print(net1)
//    let ctlPath = resourcesDirectory + "ERK/ERK-CTLFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//    let pnmlPath = resourcesDirectory + "ERK/ERK-CTLFireability.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//    let loopNb: UInt64 = 10
//
//    let ctlPath = resourcesDirectory + "ERK/ERK-CTLFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//    let pnmlPath = resourcesDirectory + "ERK/ERK-CTLFireability.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//    let loopNb: UInt64 = 10
//
//    let ctlPath = resourcesDirectory + "ERK/ERK-CTLFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//    let pnmlPath = resourcesDirectory + "ERK/ERK-CTLFireability.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "ERK/ERK-CTLFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
//
//    s.reset()
//
////    var answers: [String: Bool] = [:]
//    var answers: [String: SVS] = [:]
//    var times: [String: String] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false).queryReduction()
//      print("-------------------------------")
//      print(key)
//      answers[key] = ctlReduced.eval()
//      s.reset()
//      print("Nb sv: \(answers[key]!.count)")
//      print("Nb Expected markings: \(answers[key]!.underlyingMarkings().count)")
//      print("Nb markings: \(answers[key]!.nbOfMarkings())")
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
//    let pnmlPath = resourcesDirectory + "TwoPhaseLocking/twoPhaseLocking-model.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "TwoPhaseLocking/TwoPhaseLocking-CTLFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
//
//    s.reset()
//
//    let formula = dicCTL["TwoPhaseLocking-PT-nC00004vD-CTLFireability-01"]!
//    let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: true)
//    print(ctlReduced.eval(marking: marking1))
//
//    print(s.elapsed.humanFormat)
//  }
//  
//  func testERKReachability() {
//    let parserPN = PnmlParser()
//    let pnmlPath = resourcesDirectory + "ERK/ERK-CTLFireability.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "ERK/ERK-CTLFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//  func testLoadBalCase() {
//    let parserPN = PnmlParser()
//    let pnmlPath = resourcesDirectory + "SimpleLoadBal/simpleLoadBal-2.pnml"
//    var (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "SimpleLoadBal/CTLFireabilitySimpleLoadBal-2.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//      let pnmlPath = resourcesDirectory + "SimpleLoadBal/simpleLoadBal-2.pnml"
//      let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//      var s = Stopwatch()
//
//      let ctlPath = resourcesDirectory + "SimpleLoadBal/SimpleLoadBal-ReachabilityFireability.xml"
//      let parserCTL = CTLParser()
//      let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//    let pnmlPath = resourcesDirectory + "SimpleLoadBal/simpleLoadBal-2.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "SimpleLoadBal/SimpleLoadBal-ReachabilityFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
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
//  func testCircadianClock() {
//    let parserPN = PnmlParser()
//    let pnmlPath = resourcesDirectory + "CircadianClock-PT-000001/model.pnml"
//    let (net1, marking1) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "CircadianClock-PT-000001/ReachabilityFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
//    
//    s.reset()
//
////    var answers: [String: Bool] = [:]
//    var answers: [String: SVS] = [:]
//    var times: [String: String] = [:]
//    for (key, formula) in dicCTL.sorted(by: {$0.key < $1.key}) {
//      let ctlReduced = CTL(formula: formula, net: net1, canonicityLevel: .full, simplified: false, debug: false).queryReduction()
//      print("-------------------------------")
//      print(key)
//      answers[key] = ctlReduced.eval()
//      s.reset()
//      print("Nb sv: \(answers[key]!.count)")
//      print("Nb markings Expected: \(answers[key]!.underlyingMarkings().count)")
//      print("Nb markings formula: \(answers[key]!.nbOfMarkings())")
////      print(answers[key]!)
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
////  func evalEF(formula: Formula) -> SVS {
////    let phi = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
////    var res = phi
////    var resTemp: SVS
////    
////    var newNet = net
////    var storage: [String: Int] = [:]
////    for i in 1 ..< net.capacity.first!.value + 1 {
////      for place in net.places {
////        storage[place] = i
////      }
////      newNet.capacity = storage
////      
////    }
////  }
//  
//  func testCircadianClock04() {
//    let parserPN = PnmlParser()
//    let pnmlPath = resourcesDirectory + "CircadianClock-PT-000001/model.pnml"
//    var (net1, _) = parserPN.loadPN(filePath: pnmlPath)
//    var s = Stopwatch()
//
//    let ctlPath = resourcesDirectory + "CircadianClock-PT-000001/ReachabilityFireability.xml"
//    let parserCTL = CTLParser()
//    let dicCTL = parserCTL.loadCTL(filePath: ctlPath)
//    
//    let key = "CircadianClock-PT-000001-ReachabilityFireability-14"
//    let ctlReduced = CTL(formula: dicCTL[key]!, net: net1, canonicityLevel: .full, simplified: false, debug: true).queryReduction()
//      
//    s.reset()
//    let r1 = ctlReduced.eval()
//    print(s.elapsed.humanFormat)
//    
//    var storage: [String: Int] = [:]
//    for place in net1.places {
//      storage[place] = 2
//    }
//    net1.capacity = storage
//    s.reset()
//    let r2 = ctlReduced.eval()
//    print(s.elapsed.humanFormat)
//    print("Are r1 and r2 equal ? \(r1 == r2)")
//    
//    for place in net1.places {
//      storage[place] = 3
//    }
//    net1.capacity = storage
//    s.reset()
//    let r3 = ctlReduced.eval()
//    print(s.elapsed.humanFormat)
//    print("Are r1 and r3 equal ? \(r1 == r3)")
//  }
//  
//}
//
