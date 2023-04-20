import XCTest
//@testable import PredicateStructure
import PredicateStructure

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
    
    let ps1 = PS(value: ([Marking(["p0": 1, "p1": 2, "p2": 1], net: net)], []), net: net)
    let ps2 = PS(value: ([net.zeroMarking()], [Marking(["p0": 1, "p1": 0, "p2": 0], net: net), Marking(["p0": 0, "p1": 1, "p2": 0], net: net), Marking(["p0": 0, "p1": 0, "p2": 1], net: net)]), net: net)
    let ps3 = PS(value: ([Marking(["p0": 0, "p1": 2, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 0], net: net), Marking(["p0": 0, "p1": 2, "p2": 1], net: net)]), net: net)
    let ps4 = PS(value: ([Marking(["p0": 0, "p1": 2, "p2": 1], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 1], net: net)]), net: net)
    let ps5 = PS(value: ([Marking(["p0": 1, "p1": 2, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 1], net: net)]), net: net)
    
    let expectedSPS: SPS = [ps1, ps2, ps3, ps4, ps5]
    
    let ctlFormula = CTL(formula: .AX(.isFireable("t2")), net: net, rewrited: true, simplified: true)
    let sps = ctlFormula.eval()
//    let simplifiedSPS = sps.simplified(complete: true)

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

    let ps1 = PS(value: ([Marking(["p1": 0, "p2": 0, "p3": 0, "p4": 1, "p5": 1], net: net)], []), net: net)
    let ps2 = PS(value: ([Marking(["p1": 0, "p2": 1, "p3": 1, "p4": 1, "p5": 0], net: net)], []), net: net)
    let ps3 = PS(value: ([Marking(["p1": 1, "p2": 0, "p3": 1, "p4": 0, "p5": 1], net: net)], []), net: net)
    let ps4 = PS(value: ([Marking(["p1": 1, "p2": 1, "p3": 2, "p4": 0, "p5": 0], net: net)], []), net: net)
    let ps5 = PS(value: ([Marking(["p1": 0, "p2": 1, "p3": 0, "p4": 2, "p5": 0], net: net)], []), net: net)
    let ps6 = PS(value: ([Marking(["p1": 1, "p2": 0, "p3": 0, "p4": 0, "p5": 2], net: net)], []), net: net)
    let expectedSPS: SPS = [ps1, ps2, ps3, ps4, ps5, ps6]

    // Compute all markings that breaks the mutual exclusion
    let ctlFormula = CTL(formula: .EF(.and(.isFireable("t4"), .isFireable("t5"))), net: net)
    let sps = ctlFormula.eval()

    XCTAssertEqual(expectedSPS, sps.simplified())
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

    let ctlFormula1: CTL = CTL(formula: .AF(.isFireable("t2")), net: net)
    let ctlFormula2: CTL = CTL(formula: .EG(.isFireable("t2")), net: net)
    let ctlFormula3: CTL = CTL(formula: .AG(.isFireable("t2")), net: net)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()

    let ps = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]
    
    let simplifiedSPS1 = sps1.simplified()
    let simplifiedSPS2 = sps2.simplified()
    let simplifiedSPS3 = sps3.simplified()

    XCTAssertEqual(simplifiedSPS1, expectedRes)
    XCTAssertEqual(simplifiedSPS2, [])
    XCTAssertEqual(simplifiedSPS3, [])
    
    let ctlFormula4: CTL = CTL(formula: .AX(.isFireable("t2")), net: net, rewrited: false)
    let ctlFormula5: CTL = CTL(formula: .AX(.isFireable("t2")), net: net, rewrited: true)
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
    
    let ctlFormula1: CTL = CTL(formula: .AF(.isFireable("t2")), net: net)
    let ctlFormula2: CTL = CTL(formula: .EG(.isFireable("t2")), net: net)
    let ctlFormula3: CTL = CTL(formula: .AG(.isFireable("t2")), net: net)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()

    let ps: PS = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    XCTAssertEqual(simpliedSPS3, expectedRes)
    
    let ctlFormula4: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, rewrited: true)
    let ctlFormula5: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, rewrited: false)
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

    let ctlFormula1: CTL = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, rewrited: true)
    let ctlFormula2: CTL = CTL(formula: .EU(.isFireable("t1"), .isFireable("t0")), net: net)
    let ctlFormula3: CTL = CTL(formula: .AU(.isFireable("t1"), .isFireable("t0")), net: net)
    let ctlFormula4: CTL = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, rewrited: false)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()
    let sps4 = ctlFormula4.eval()

    let ps1 = PS(value: ([Marking(["p0": 2, "p1": 0, "p2": 0], net: net)], []), net: net)
    let ps3 = PS(value: ([net.zeroMarking()], [Marking(["p0": 2, "p1": 0, "p2": 0], net: net)]), net: net)
    let ps4 = PS(value: ([net.zeroMarking()], [Marking(["p0": 4, "p1": 0, "p2": 0], net: net)]), net: net)

    let simplifiedSPS1 = sps1.simplified()
    let simplifiedSPS2 = sps2.simplified()
    let simplifiedSPS3 = sps3.simplified()
    
    XCTAssertEqual(simplifiedSPS1, [ps4])
    XCTAssertEqual(simplifiedSPS2, [ps1])
    XCTAssertEqual(simplifiedSPS3, [ps1])
    XCTAssertTrue(sps4.isIncluded(sps1))
    
    let ctlFormula5 = CTL(formula: .deadlock, net: net)
    XCTAssertEqual(ctlFormula5.eval().simplified(), [ps3])
    
    let ctlFormula6 = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, rewrited: false)
    let ctlFormula7 = CTL(formula: .AX(.and(.isFireable("t1"), .not(.isFireable("t0")))), net: net, rewrited: true)
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
    
    let ctlFormula1: CTL = CTL(formula: .AF(.and(.isFireable("t1"), .isFireable("t2"))), net: net)
    let ctlFormula2: CTL = CTL(formula: .AF(.and(.isFireable("t1"), .not(.isFireable("t2")))), net: net)
    let ctlFormula3: CTL = CTL(formula: .AG(.not(.isFireable("t0"))), net: net)
    let ctlFormula4: CTL = CTL(formula: .AG(.not(.isFireable("t2"))), net: net)
    let ctlFormula5: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, rewrited: false)
    let ctlFormula6: CTL = CTL(formula: .AX(.or(.isFireable("t0"), .isFireable("t2"))), net: net, rewrited: true)
    
    XCTAssertEqual(ctlFormula1.eval(), ctlFormula1.eval())
    XCTAssertEqual(ctlFormula2.eval(), ctlFormula2.eval())
    XCTAssertTrue(ctlFormula3.eval().isEquiv(ctlFormula3.eval()))
    XCTAssertTrue(ctlFormula4.eval().isEquiv(ctlFormula4.eval()))
    XCTAssertTrue(ctlFormula5.eval().isEquiv(ctlFormula6.eval()))
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
    
    let ctl1 = CTL(formula: .AX(.or(.isFireable("t0"), .or(.isFireable("t1"), .isFireable("t2")))), net: net, rewrited: true)
    let ctl2 = CTL(formula: .AX(.or(.isFireable("t0"), .or(.isFireable("t1"), .isFireable("t2")))), net: net, rewrited: false)
    
    XCTAssertTrue(ctl1.eval().isEquiv(ctl2.eval()))
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
    
    let ctlFormula1: CTL = CTL(formula: .AF(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net)
    let ctlFormula2: CTL = CTL(formula: .EG(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net)
    let ctlFormula3: CTL = CTL(formula: .AG(.intExpr(e1: .value(1), operator: .leq, e2: .tokenCount("p1"))), net: net)
    let sps1 = ctlFormula1.eval()
    let sps2 = ctlFormula2.eval()
    let sps3 = ctlFormula3.eval()

    let ps: PS = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    XCTAssertEqual(simpliedSPS3, expectedRes)
    
    let ctlFormula4: CTL = CTL(formula: .and(.intExpr(e1: .tokenCount("p0"), operator: .lt, e2: .value(4)), .intExpr(e1: .value(7), operator: .lt, e2: .tokenCount("p1"))), net: net)
    let expectedSPS: SPS = [PS(value: ([Marking(["p0": 0, "p1": 8], net: net)], [Marking(["p0": 4, "p1": 8], net: net)]), net: net)]
    XCTAssertEqual(expectedSPS, ctlFormula4.eval())
  }
  
  func testLoadCTL() {
    let ctlParser = CTLParser()
    let ctlDic1 = ctlParser.loadCTL(filePath: "CTLFireabilitySwimmingPool-1.xml")
    var expectedCTL1: CTL.Formula = .AX(.or(.isFireable("RKey"), .AF(.EG(.or(.AG(.isFireable("RelK")), .isFireable("GetB"))))))
    var expectedCTL2: CTL.Formula = .AG(.EF(.AF(.AG(.isFireable("GetK")))))
    XCTAssertEqual(ctlDic1["SwimmingPool-PT-01-CTLFireability-02"]!, expectedCTL1)
    XCTAssertEqual(ctlDic1["SwimmingPool-PT-01-CTLFireability-09"]!, expectedCTL2)
    
    let ctlDic2 = ctlParser.loadCTL(filePath: "CTLCardinalitySwimmingPool-1.xml")
    expectedCTL1 = .AF(.AG(.intExpr(e1: .value(5), operator: .leq, e2: .tokenCount("Bags"))))
    expectedCTL2 = .AF(.EU(.intExpr(e1: .tokenCount("Undress"), operator: .leq, e2: .tokenCount("Dressed")), .intExpr(e1: .value(6), operator: .leq, e2: .tokenCount("InBath"))))
    XCTAssertEqual(ctlDic2["SwimmingPool-PT-01-CTLCardinality-04"]!, expectedCTL1)
    XCTAssertEqual(ctlDic2["SwimmingPool-PT-01-CTLCardinality-06"]!, expectedCTL2)
  }
  
}
