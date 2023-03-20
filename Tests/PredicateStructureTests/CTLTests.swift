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
      .pre(from: "p1", to: "t2", labeled: 1)
    )
    
    let ps1 = PS(value: ([Marking(["p0": 1, "p1": 2, "p2": 1], net: net)], []), net: net)
    let ps2 = PS(value: ([], [Marking(["p0": 1, "p1": 0, "p2": 0], net: net), Marking(["p0": 0, "p1": 1, "p2": 0], net: net), Marking(["p0": 0, "p1": 0, "p2": 1], net: net)]), net: net)
    let ps3 = PS(value: ([Marking(["p0": 0, "p1": 2, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 0], net: net), Marking(["p0": 0, "p1": 2, "p2": 1], net: net)]), net: net)
    let ps4 = PS(value: ([Marking(["p0": 0, "p1": 2, "p2": 1], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 1], net: net)]), net: net)
    let ps5 = PS(value: ([Marking(["p0": 1, "p1": 2, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 2, "p2": 1], net: net)]), net: net)
    
    let expectedSPS: SPS = [ps1, ps2, ps3, ps4, ps5]
    
    let ctlFormula: CTL = .AX(.isFireable("t2"))
    let sps = ctlFormula.eval(net: net, rewrited: true)
    let simpliedSPS = sps.simplified(complete: true)

    XCTAssertTrue(simpliedSPS.isEquiv(expectedSPS))
    
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
      .post(from: "t5", to: "p3", labeled: 1)
    )

    let ps1 = PS(value: ([Marking(["p1": 0, "p2": 0, "p3": 0, "p4": 1, "p5": 1], net: net)], []), net: net)
    let ps2 = PS(value: ([Marking(["p1": 0, "p2": 1, "p3": 1, "p4": 1, "p5": 0], net: net)], []), net: net)
    let ps3 = PS(value: ([Marking(["p1": 1, "p2": 0, "p3": 1, "p4": 0, "p5": 1], net: net)], []), net: net)
    let ps4 = PS(value: ([Marking(["p1": 1, "p2": 1, "p3": 2, "p4": 0, "p5": 0], net: net)], []), net: net)
    let ps5 = PS(value: ([Marking(["p1": 0, "p2": 1, "p3": 0, "p4": 2, "p5": 0], net: net)], []), net: net)
    let ps6 = PS(value: ([Marking(["p1": 1, "p2": 0, "p3": 0, "p4": 0, "p5": 2], net: net)], []), net: net)
    let expectedSPS: SPS = [ps1, ps2, ps3, ps4, ps5, ps6]

    // Compute all markings that breaks the mutual exclusion
    let ctlFormula: CTL = .EF(.and(.isFireable("t4"), .isFireable("t5")))
    let sps = ctlFormula.eval(net: net)

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
      capacity: ["p0": 4, "p1": 4]
    )

    let ctlFormula1: CTL = .AF(.isFireable("t2"))
    let ctlFormula2: CTL = .EG(.isFireable("t2"))
    let ctlFormula3: CTL = .AG(.isFireable("t2"))
    let sps1 = ctlFormula1.eval(net: net)
    let sps2 = ctlFormula2.eval(net: net)
    let sps3 = ctlFormula3.eval(net: net)

    let ps = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]
    
    let simplifiedSPS1 = sps1.simplified()
    let simplifiedSPS2 = sps2.simplified()
    let simplifiedSPS3 = sps3.simplified()

    XCTAssertEqual(simplifiedSPS1, expectedRes)
    XCTAssertEqual(simplifiedSPS2, [])
    XCTAssertEqual(simplifiedSPS3, [])
    
    let ctlFormula4: CTL = .AX(.isFireable("t2"))
    XCTAssertTrue(ctlFormula4.eval(net: net).isEquiv(ctlFormula4.eval(net: net, rewrited: true)))
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
    
    let ctlFormula1: CTL = .AF(.isFireable("t2"))
    let ctlFormula2: CTL = .EG(.isFireable("t2"))
    let ctlFormula3: CTL = .AG(.isFireable("t2"))
    let sps1 = ctlFormula1.eval(net: net)
    let sps2 = ctlFormula2.eval(net: net)
    let sps3 = ctlFormula3.eval(net: net)

    let ps: PS = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    print(sps3)
    print(simpliedSPS3)
    XCTAssertEqual(simpliedSPS3, expectedRes)
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
      .post(from: "t1", to: "p1", labeled: 1)
    )

    let ctlFormula1: CTL = .AX(.and(.isFireable("t1"), .not(.isFireable("t0"))))
    let ctlFormula2: CTL = .EU(.isFireable("t1"), .isFireable("t0"))
    let ctlFormula3: CTL = .AU(.isFireable("t1"), .isFireable("t0"))
    let sps1 = ctlFormula1.eval(net: net, rewrited: true)
    let sps2 = ctlFormula2.eval(net: net)
    let sps3 = ctlFormula3.eval(net: net)
    let sps4 = ctlFormula1.eval(net: net)

    let ps1 = PS(value: ([Marking(["p0": 2, "p1": 0, "p2": 0], net: net)], []), net: net)
    let ps2 = PS(value: ([Marking(["p0": 2, "p1": 0, "p2": 0], net: net)], [Marking(["p0": 4, "p1": 0, "p2": 0], net: net)]), net: net)
    let ps3 = PS(value: ([], [Marking(["p0": 2, "p1": 0, "p2": 0], net: net)]), net: net)

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    
    XCTAssertEqual(simpliedSPS1, [ps2,ps3])
    XCTAssertEqual(simpliedSPS2, [ps1])
    XCTAssertEqual(simpliedSPS3, [ps1])
    XCTAssertTrue(sps4.isIncluded(sps1))
    
    let ctlFormula4: CTL = .deadlock
    XCTAssertEqual(ctlFormula4.eval(net: net).simplified(), [ps3])
    
    let ctlFormula5: CTL = .AX(.and(.isFireable("t1"), .not(.isFireable("t0"))))
    XCTAssertTrue(ctlFormula5.eval(net: net).isIncluded(ctlFormula5.eval(net: net, rewrited: true)))
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
      .pre(from: "p2", to: "t2", labeled: 1)
    )
    
    let ctlFormula1: CTL = .AF(.and(.isFireable("t1"), .isFireable("t2")))
    let ctlFormula2: CTL = .AF(.and(.isFireable("t1"), .not(.isFireable("t2"))))
    let ctlFormula3: CTL = .AG(.not(.isFireable("t0")))
    let ctlFormula4: CTL = .AG(.not(.isFireable("t2")))

    XCTAssertEqual(ctlFormula1.eval(net: net), ctlFormula1.eval(net: net, rewrited: true))
    XCTAssertEqual(ctlFormula2.eval(net: net), ctlFormula2.eval(net: net, rewrited: true))
    XCTAssertTrue(ctlFormula3.eval(net: net).isEquiv(ctlFormula3.eval(net: net, rewrited: true)))
    XCTAssertTrue(ctlFormula4.eval(net: net).isEquiv(ctlFormula4.eval(net: net, rewrited: true)))
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
    
    let ctlFormula1: CTL = .AF(.cardinalityFormula(e1: .value(1), operator: .leq, e2: .place("p1")))
    let ctlFormula2: CTL = .EG(.cardinalityFormula(e1: .value(1), operator: .leq, e2: .place("p1")))
    let ctlFormula3: CTL = .AG(.cardinalityFormula(e1: .value(1), operator: .leq, e2: .place("p1")))
    let sps1 = ctlFormula1.eval(net: net)
    let sps2 = ctlFormula2.eval(net: net)
    let sps3 = ctlFormula3.eval(net: net)

    let ps: PS = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    XCTAssertEqual(simpliedSPS3, expectedRes)
    
    let ctlFormula4: CTL = .and(.cardinalityFormula(e1: .place("p0"), operator: .lt, e2: .value(4)), .cardinalityFormula(e1: .value(7), operator: .lt, e2: .place("p1")))
    let expectedSPS: SPS = [PS(value: ([Marking(["p0": 0, "p1": 8], net: net)], [Marking(["p0": 4, "p1": 8], net: net)]), net: net)]
    XCTAssertEqual(expectedSPS, ctlFormula4.eval(net: net))
  }
    
  func testLoadCTL() {
    let ctlParser = CTLParser()
    let ctlDic = ctlParser.loadCTL(filePath: "CTLFireability.xml")
//    for (key, values) in ctl {
//      print("------------------")
//      print(key)
//      print(values)
//    }
//    let ctlFormula = ctlDic["SwimmingPool-PT-01-CTLFireability-09"]!
    
    let pnmlParser = PnmlParser()
    let (net, marking) = pnmlParser.loadPN(filePath: "SwimmingPool-1.pnml")
    
    for (id, ctlFormula) in ctlDic {
      print(id)
      print(ctlFormula)
      print("-")
      print(ctlFormula.queryReduction())
//      print(ctlFormula.eval(marking: marking, net: net))
      print("-----------------------")
    }
  }
}
