import XCTest
@testable import PredicateStructure

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
    
    let ctlFormula: CTL = .AX(.ap("t2"))
    let sps = ctlFormula.eval(net: net)
    let simpliedSPS = sps.simplified()

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
    let ctlFormula: CTL = .EF(.and(.ap("t4"), .ap("t5")))
    let sps = ctlFormula.eval(net: net)

    XCTAssertEqual(expectedSPS, sps.simplified())
  }

  // No answers for EG/AG
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

    let ctlFormula1: CTL = .AF(.ap("t2"))
    let ctlFormula2: CTL = .EG(.ap("t2"))
    let ctlFormula3: CTL = .AG(.ap("t2"))
    let sps1 = ctlFormula1.eval(net: net)
    let sps2 = ctlFormula2.eval(net: net)
    let sps3 = ctlFormula3.eval(net: net)

    let ps = PS(value: ([Marking(["p0": 0, "p1": 1], net: net)], []), net: net)
    let expectedRes: SPS = [ps]
    
    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()

    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, [])
    XCTAssertEqual(simpliedSPS3, [])
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

    let ctlFormula1: CTL = .AF(.ap("t2"))
    let ctlFormula2: CTL = .EG(.ap("t2"))
    let ctlFormula3: CTL = .AG(.ap("t2"))
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
  }

  func testCTLEval3() {
    // Following Petri net:
    // p1
    //       2 t1
    //      <--
    // p0 o     ▭ --> o p1
    //    | -->
    //    |  5
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

    let ctlFormula1: CTL = .AX(.and(.ap("t1"), .not(.ap("t0"))))
    let ctlFormula2: CTL = .EU(.ap("t1"), .ap("t0"))
    let ctlFormula3: CTL = .AU(.ap("t1"), .ap("t0"))
    let sps1 = ctlFormula1.eval(net: net)
    let sps2 = ctlFormula2.eval(net: net)
    let sps3 = ctlFormula3.eval(net: net)

    let ps1 = PS(value: ([Marking(["p0": 2, "p1": 0, "p2": 0], net: net)], []), net: net)
    let ps2 = PS(value: ([Marking(["p0": 2, "p1": 0, "p2": 0], net: net)], [Marking(["p0": 4, "p1": 0, "p2": 0], net: net)]), net: net)
    let ps3 = PS(value: ([], [Marking(["p0": 2, "p1": 0, "p2": 0], net: net)]), net: net)

    let simpliedSPS1 = sps1.simplified()
    let simpliedSPS2 = sps2.simplified()
    let simpliedSPS3 = sps3.simplified()
    
    XCTAssertEqual(simpliedSPS1, [ps2,ps3])
    XCTAssertEqual(simpliedSPS2, [ps1])
    XCTAssertEqual(simpliedSPS3, [ps1])
    
    print("---------------------")
    print(simpliedSPS3)
    print(ps1)
  }
  
}
