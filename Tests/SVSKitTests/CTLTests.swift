import XCTest
//@testable import PredicateStructure
import SVSKit

final class CTLTests: XCTestCase {

  func testCTLEvalAX() {

    // Following Petri net:
    //          t0   p2   t3
    //       -> ▭ -> o -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o -> ▭
    //          t1   p1   t2
    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0", "t1", "t2", "t3"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p2", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .post(from: "t1", to: "p1", labeled: 1),
      .pre(from: "p2", to: "t3", labeled: 1),
      .pre(from: "p1", to: "t2", labeled: 1),
      capacity: ["p0": 10, "p1": 10, "p2": 10]
    )
    
    let ps1 = SV(value: ([Marking(["p0": 1, "p1": 2, "p2": 1], net: net)], []), net: net)
    let ps2 = SV(value: ([net.zeroMarking()], [Marking(["p0": 1, "p1": 0, "p2": 0], net: net), Marking(["p0": 0, "p1": 1, "p2": 0], net: net), Marking(["p0": 0, "p1": 0, "p2": 1], net: net)]), net: net)
    let ps3 = SV(value: ([Marking(["p0": 0, "p1": 2, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 0], net: net), Marking(["p0": 0, "p1": 2, "p2": 1], net: net)]), net: net)
    let ps4 = SV(value: ([Marking(["p0": 0, "p1": 2, "p2": 1], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 1], net: net)]), net: net)
    let ps5 = SV(value: ([Marking(["p0": 1, "p1": 2, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 1], net: net)]), net: net)
    
    let expectedSPS: SVS = [ps1, ps2, ps3, ps4, ps5]
    
    let ctlFormula = CTL(formula: .AX(.isFireable("t2")), net: net, canonicityLevel: .full, simplified: false)
    let sps = ctlFormula.eval()
    
    XCTAssertTrue(sps.isEquiv(expectedSPS))
  }

  
  func testCTLEvalEF() {

    // Petri net that models the mutual exclusion problem
    let net = PetriNet(
      places: ["p1", "p2", "p3", "p4", "p5"],
      transitions: ["t1", "t2", "t4", "t5"],
      arcs: .pre(from: "p1", to: "t1", labeled: 1),
      .pre(from: "p3", to: "t1", labeled: 1),
      .post(from: "t1", to: "p4", labeled: 1),
      .pre(from: "p2", to: "t2", labeled: 1),
      .pre(from: "p3", to: "t2", labeled: 1),
      .post(from: "t2", to: "p5", labeled: 1),
      .pre(from: "p4", to: "t4", labeled: 1),
      .post(from: "t4", to: "p1", labeled: 1),
      .post(from: "t4", to: "p3", labeled: 1),
      .pre(from: "p5", to: "t5", labeled: 1),
      .post(from: "t5", to: "p2", labeled: 1),
      .post(from: "t5", to: "p3", labeled: 1),
      capacity: ["p1": 10, "p2": 10, "p3": 10, "p4": 10, "p5": 10]
    )

    let ps1 = SV(value: ([Marking(["p1": 0, "p2": 0, "p3": 0, "p4": 1, "p5": 1], net: net)], []), net: net)
    let ps2 = SV(value: ([Marking(["p1": 0, "p2": 1, "p3": 1, "p4": 1, "p5": 0], net: net)], []), net: net)
    let ps3 = SV(value: ([Marking(["p1": 1, "p2": 0, "p3": 1, "p4": 0, "p5": 1], net: net)], []), net: net)
    let ps4 = SV(value: ([Marking(["p1": 1, "p2": 1, "p3": 2, "p4": 0, "p5": 0], net: net)], []), net: net)
    let ps5 = SV(value: ([Marking(["p1": 0, "p2": 1, "p3": 0, "p4": 2, "p5": 0], net: net)], []), net: net)
    let ps6 = SV(value: ([Marking(["p1": 1, "p2": 0, "p3": 0, "p4": 0, "p5": 2], net: net)], []), net: net)
    let equivSPS: SVS = [ps1, ps2, ps3, ps4, ps5, ps6]

    // Compute all markings that breaks the mutual exclusion
    let ctlFormula = CTL(formula: .EF(.and(.isFireable("t4"), .isFireable("t5"))), net: net, canonicityLevel: .full, simplified: false, debug: true)
    let sps = ctlFormula.eval()
//    let sps2 = ctlFormula.eval()
    
    let e = equivSPS
    XCTAssertTrue(e.isEquiv(sps))
  }

  func testCTLEval1() {
    // Following Petri net:
    //          t0
    //       -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o -> ▭
    //          t1   p1   t2
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1", "t2"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .post(from: "t1", to: "p1", labeled: 1),
      .pre(from: "p1", to: "t2", labeled: 1),
      capacity: ["p0": 6, "p1": 6]
    )

    let ctlFormula1: CTL = CTL(formula: .AF(.isFireable("t2")), net: net, canonicityLevel: .full)
    let ctlFormula2: CTL = CTL(formula: .EG(.isFireable("t2")), net: net, canonicityLevel: .full)
    let ctlFormula3: CTL = CTL(formula: .AG(.isFireable("t2")), net: net, canonicityLevel: .full)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()

    let ps = SV(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SVS = [ps]
    
    let simplifiedSPS1 = sps1.simplified()
    let simplifiedSPS2 = sps2.simplified()
    let simplifiedSPS3 = sps3.simplified()

//    let cf: CTL = CTL(formula: .EG(.isFireable("t2")), net: net, canonicityLevel: .semi)
    
    XCTAssertEqual(simplifiedSPS1, expectedRes)
    XCTAssertEqual(simplifiedSPS2, [])
    XCTAssertEqual(simplifiedSPS3, [])
    
    let ctlFormula4: CTL = CTL(formula: .AX(.isFireable("t2")), net: net, canonicityLevel: .none)
    let ctlFormula5: CTL = CTL(formula: .AX(.isFireable("t2")), net: net, canonicityLevel: .full)
    let r1 = ctlFormula4.eval()
    let r2 = ctlFormula5.eval()
    XCTAssertTrue(r1.isEquiv(r2))
    
  }

  func testCTLEval2() {
    // Following Petri net:
    //          t0
    //       -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o <-> ▭
    //          t1   p1   t2
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1", "t2"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .post(from: "t1", to: "p1", labeled: 1),
      .pre(from: "p1", to: "t2", labeled: 1),
      .post(from: "t2", to: "p1", labeled: 1)
    )
    
    let ctlFormula1: CTL = CTL(formula: .AF(.isFireable("t2")), net: net, canonicityLevel: .full)
    let ctlFormula2: CTL = CTL(formula: .EG(.isFireable("t2")), net: net, canonicityLevel: .full)
    let ctlFormula3: CTL = CTL(formula: .AG(.isFireable("t2")), net: net, canonicityLevel: .full)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()

    let ps: SV = SV(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SVS = [ps]

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    XCTAssertEqual(simpliedSPS3, expectedRes)
    
    let ctlFormula4: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, canonicityLevel: .full)
    let ctlFormula5: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, canonicityLevel: .none)
    XCTAssertEqual(ctlFormula4.eval(), ctlFormula5.eval())
  }

  func testCTLEval3() {
    // Following Petri net:
    // p1
    //       5 t1
    //      <--
    // p0 o     ▭ --> o p1
    //    | -->
    //    |  2
    //    |
    //    |
    //     -->  ▭ --> o p2
    //      7   t0
    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0", "t1"],
      arcs: .pre(from: "p0", to: "t0", labeled: 7),
      .post(from: "t0", to: "p2", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 2),
      .post(from: "t1", to: "p0", labeled: 5),
      .post(from: "t1", to: "p1", labeled: 1),
      capacity: ["p0": 20, "p1": 20, "p2": 20]
    )

    let ctlFormula1: CTL = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, canonicityLevel: .full)
    let ctlFormula2: CTL = CTL(formula: .EU(.isFireable("t1"), .isFireable("t0")), net: net, canonicityLevel: .full)
    let ctlFormula3: CTL = CTL(formula: .AU(.isFireable("t1"), .isFireable("t0")), net: net, canonicityLevel: .full)
    let ctlFormula4: CTL = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, canonicityLevel: .none)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()
    let sps4 = ctlFormula4.eval()

    let ps1 = SV(value: ([Marking(["p0": 2, "p1": 0, "p2": 0], net: net)], []), net: net)
    let ps3 = SV(value: ([net.zeroMarking()], [Marking(["p0": 2, "p1": 0, "p2": 0], net: net)]), net: net)
    let ps4 = SV(value: ([net.zeroMarking()], [Marking(["p0": 4, "p1": 0, "p2": 0], net: net)]), net: net)

    let simplifiedSPS1 = sps1.simplified()
    let simplifiedSPS2 = sps2.simplified()
    let simplifiedSPS3 = sps3.simplified()
    
    XCTAssertEqual(simplifiedSPS1, [ps4])
    XCTAssertEqual(simplifiedSPS2, [ps1])
    XCTAssertEqual(simplifiedSPS3, [ps1])
    XCTAssertTrue(sps4.isIncluded(sps1))
    
    let ctlFormula5 = CTL(formula: .deadlock, net: net, canonicityLevel: .full)
    XCTAssertEqual(ctlFormula5.eval().simplified(), [ps3])
    
    let ctlFormula6 = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, canonicityLevel: .none)
    let ctlFormula7 = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, canonicityLevel: .full)
    XCTAssertTrue(ctlFormula6.eval().isIncluded(ctlFormula7.eval()))
  }
  
  
  func testAXDiff() {
    // Following Petri net:
    //      1 p0
    //     -->
    // t0 ▭   o ---
    //     <--      \
    //      2       | 4
    //              ↓
    //           -> ▭ t1
    //        6 /   | 3
    //          |   /
    // t2 ▭ <-- o <-
    //    ↑   5 p1
    //    |
    //    o p2
    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0", "t1", "t2"],
      arcs: .pre(from: "p0", to: "t0", labeled: 2),
      .post(from: "t0", to: "p0", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 4),
      .pre(from: "p1", to: "t1", labeled: 6),
      .post(from: "t1", to: "p1", labeled: 3),
      .pre(from: "p1", to: "t2", labeled: 5),
      .pre(from: "p2", to: "t2", labeled: 1),
      capacity: ["p0": 10, "p1": 10, "p2": 10]
    )
    
    let ctlFormula1: CTL = CTL(formula: .AF(.and(.isFireable("t1"), .isFireable("t2"))), net: net, canonicityLevel: .full)
    let ctlFormula2: CTL = CTL(formula: .AF(.and(.isFireable("t1"), .not(.isFireable("t2")))), net: net, canonicityLevel: .full)
    let ctlFormula3: CTL = CTL(formula: .AG(.not(.isFireable("t0"))), net: net, canonicityLevel: .full)
    let ctlFormula4: CTL = CTL(formula: .AG(.not(.isFireable("t2"))), net: net, canonicityLevel: .full)
    let ctlFormula5: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, canonicityLevel: .none)
    let evalFormula5 = ctlFormula5.eval()
    let ctlFormula6: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, canonicityLevel: .full)
    let evalFormula6 = ctlFormula6.eval()
    
    XCTAssertEqual(ctlFormula1.eval(), ctlFormula1.eval())
    XCTAssertEqual(ctlFormula2.eval(), ctlFormula2.eval())
    XCTAssertTrue(ctlFormula3.eval().isEquiv(ctlFormula3.eval()))
    XCTAssertTrue(ctlFormula4.eval().isEquiv(ctlFormula4.eval()))
    XCTAssertTrue(evalFormula5.isEquiv(evalFormula6))
  }
  
  func testCTLAXDiff2() {
    // Following Petri net:
    // p0     t0
    // o ---> ▭
    //
    // p1     t1
    // o ---> ▭
    //
    // p2     t2
    // o ---> ▭
    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0", "t1", "t2"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .pre(from: "p1", to: "t1", labeled: 1),
      .pre(from: "p2", to: "t2", labeled: 1)
    )
    
    let ctl1 = CTL(formula: .AX(.or(.isFireable("t0"), .or(.isFireable("t1"), .isFireable("t2")))), net: net, canonicityLevel: .none)
    let ctl2 = CTL(formula: .AX(.or(.isFireable("t0"), .or(.isFireable("t1"), .isFireable("t2")))), net: net, canonicityLevel: .full)
    
    let ctl1Eval = ctl1.eval()
    let ctl2Eval = ctl2.eval()
    
    XCTAssertTrue(ctl1Eval.isEquiv(ctl2Eval))
  }

  
  func testCTLCardinality() {
    // Following Petri net:
    //          t0
    //       -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o <-> ▭
    //          t1   p1   t2
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1", "t2"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .post(from: "t1", to: "p1", labeled: 1),
      .pre(from: "p1", to: "t2", labeled: 1),
      .post(from: "t2", to: "p1", labeled: 1)
    )
    
    let ctlFormula1: CTL = CTL(formula: .AF(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net, canonicityLevel: .full)
    let ctlFormula2: CTL = CTL(formula: .EG(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net, canonicityLevel: .full)
    let ctlFormula3: CTL = CTL(formula: .AG(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net, canonicityLevel: .full)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()

    let ps: SV = SV(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SVS = [ps]

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    XCTAssertEqual(simpliedSPS3, expectedRes)
    
    let ctlFormula4: CTL = CTL(formula: .and(.intExpr(e1: .tokenCount("p0"), operator: .lt, e2: .value(4)), .intExpr(e1: .value(7), operator: .lt, e2: .tokenCount("p1"))), net: net, canonicityLevel: .full)
    let expectedSPS: SVS = [SV(value: ([Marking(["p0": 0, "p1": 8], net: net)], [Marking(["p0": 4, "p1": 8], net: net)]), net: net)]
    XCTAssertEqual(expectedSPS, ctlFormula4.eval())
  }
  
  func testLoadCTL() {
    let ctlParser = CTLParser()
    let resourcesDirectory = "/Users/damienmorard/Developer/Github/SymbolicVectorSet/Sources/SVSKit/Resources/"
    let path1 = resourcesDirectory + "SwimmingPool/CTLFireabilitySwimmingPool-1.xml"
    let ctlDic1 = ctlParser.loadCTL(filePath: path1)
    var expectedCTL1: CTL.Formula = .AX(.or(.isFireable("RKey"), .AF(.EG(.or(.AG(.isFireable("RelK")), .isFireable("GetB"))))))
    var expectedCTL2: CTL.Formula = .AG(.EF(.AF(.AG(.isFireable("GetK")))))
    XCTAssertEqual(ctlDic1["SwimmingPool-PT-01-CTLFireability-02"]!, expectedCTL1)
    XCTAssertEqual(ctlDic1["SwimmingPool-PT-01-CTLFireability-09"]!, expectedCTL2)
    
    let path2 = resourcesDirectory + "SwimmingPool/CTLCardinalitySwimmingPool-1.xml"
    let ctlDic2 = ctlParser.loadCTL(filePath: path2)
    expectedCTL1 = .AF(.AG(.intExpr(e1: .value(5), operator: .leq, e2: .tokenCount("Bags"))))
    expectedCTL2 = .AF(.EU(.intExpr(e1: .tokenCount("Undress"), operator: .leq, e2: .tokenCount("Dressed")), .intExpr(e1: .value(6), operator: .leq, e2: .tokenCount("InBath"))))
    XCTAssertEqual(ctlDic2["SwimmingPool-PT-01-CTLCardinality-04"]!, expectedCTL1)
    XCTAssertEqual(ctlDic2["SwimmingPool-PT-01-CTLCardinality-06"]!, expectedCTL2)
  }
  
//  func testRemovalOfSeqTransition() {
//    let net = PetriNet(
//      places: ["p0", "p1", "p2"],
//      transitions: ["t0", "t1", "t2", "t3", "t4", "t5"],
//      arcs: .post(from: "t0", to: "p0", labeled: 3),
//      .post(from: "t0", to: "p1", labeled: 40),
//      .post(from: "t1", to: "p0", labeled: 4),
//      .post(from: "t2", to: "p0", labeled: 5),
//      .pre(from: "p0", to: "t3", labeled: 1),
//      .post(from: "t3", to: "p1", labeled: 2),
//      .post(from: "t3", to: "p2", labeled: 7),
//      .pre(from: "p2", to: "t4", labeled: 2)
//    )
//    let ctlFormula1: CTL = CTL(formula: .EG(.isFireable("t5")), net: net, canonicityLevel: .full)
//    
//    let relatedPlaces1 = ctlFormula1.relatedPlaces()
//    let n1 = net.removalOfSeqTransition(transition: "t3", relatedPlaces: relatedPlaces1)
//        
//    let expectedNet = PetriNet(
//      places: ["p1", "p2"],
//      transitions: ["t0", "t1", "t2", "t4", "t5"],
//      arcs: .post(from: "t0", to: "p1", labeled: 46),
//      .post(from: "t1", to: "p1", labeled: 8),
//      .post(from: "t2", to: "p1", labeled: 10),
//      .post(from: "t0", to: "p2", labeled: 21),
//      .post(from: "t1", to: "p2", labeled: 28),
//      .post(from: "t2", to: "p2", labeled: 35),
//      .pre(from: "p2", to: "t4", labeled: 2)
//    )
//    XCTAssertEqual(expectedNet, n1)
//    
//    let ctlFormula2: CTL = CTL(formula: .EG(.isFireable("t1")), net: net, canonicityLevel: .full)
//    let relatedPlaces2 = ctlFormula2.relatedPlaces()
//    let n2 = net.removalOfSeqTransition(transition: "t3", relatedPlaces: relatedPlaces2)
//    
//    XCTAssertEqual(net, n2)
//  }
//  
//  func testRemovalOfSeqPlace() {
//    let net = PetriNet(
//      places: ["p0", "p1", "p2", "p3"],
//      transitions: ["t0", "t1", "t2"],
//      arcs: .post(from: "t0", to: "p0", labeled: 15),
//      .pre(from: "p0", to: "t1", labeled: 5),
//      .post(from: "t1", to: "p1", labeled: 2),
//      .post(from: "t1", to: "p2", labeled: 3),
//      .post(from: "t0", to: "p3", labeled: 100)
//    )
//    
//    let expectedNet = PetriNet(
//      places: ["p1", "p2", "p3"],
//      transitions: ["t0", "t2"],
//      arcs: .post(from: "t0", to: "p1", labeled: 6),
//      .post(from: "t0", to: "p2", labeled: 9),
//      .post(from: "t0", to: "p3", labeled: 100)
//    )
//    
//    let ctlFormula1: CTL = CTL(formula: .EG(.isFireable("t2")), net: net, canonicityLevel: .full)
//    let relatedPlaces1 = ctlFormula1.relatedPlaces()
//    XCTAssertEqual(expectedNet, net.removalOfSeqPlace(place: "p0", relatedPlaces: relatedPlaces1))
//    
//    let ctlFormula2: CTL = CTL(formula: .EG(.isFireable("t1")), net: net, canonicityLevel: .full)
//    let relatedPlaces2 = ctlFormula2.relatedPlaces()
//    XCTAssertEqual(net, net.removalOfSeqPlace(place: "p0", relatedPlaces: relatedPlaces2))
//  }
//  
//  func testRemovalOfParallelPlace() {
//    let net = PetriNet(
//      places: ["p0", "p1"],
//      transitions: ["t0", "t1", "t2"],
//      arcs: .post(from: "t0", to: "p0", labeled: 15),
//      .pre(from: "p0", to: "t1", labeled: 20),
//      .post(from: "t0", to: "p1", labeled: 3),
//      .pre(from: "p1", to: "t1", labeled: 4)
//    )
//    
//    let expectedNet = PetriNet(
//      places: ["p1"],
//      transitions: ["t0", "t1", "t2"],
//      arcs: .post(from: "t0", to: "p1", labeled: 3),
//      .pre(from: "p1", to: "t1", labeled: 4)
//    )
//    
//    let ctlFormula1: CTL = CTL(formula: .isFireable("t2"), net: net, canonicityLevel: .full)
//    let relatedPlace = ctlFormula1.relatedPlaces()
//    
//    XCTAssertEqual(expectedNet, net.removalOfParallelPlace(place: "p0", relatedPlaces: relatedPlace))
//  }
  
}
