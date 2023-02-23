import XCTest
@testable import PredicateStructure

final class CTLTests: XCTestCase {
  
  func testCTLEvalAX() {
    enum P: Place {
      typealias Content = Int

      case p0,p1,p2
    }

    enum T: Transition {
      case t0,t1,t2,t3
    }

    // Following Petri net:
    //          t0   p2   t3
    //       -> ▭ -> o -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o -> ▭
    //          t1   p1   t2
    let pn = PetriNet<P, T>(
      .pre(from: .p0, to: .t0, labeled: 1),
      .post(from: .t0, to: .p2, labeled: 1),
      .pre(from: .p0, to: .t1, labeled: 1),
      .post(from: .t1, to: .p1, labeled: 1),
      .pre(from: .p2, to: .t3, labeled: 1),
      .pre(from: .p1, to: .t2, labeled: 1)
    )
    
    let ps1: PS<P,T> = .ps([Marking([.p0: 1, .p1: 2, .p2: 1])], [])
    let ps2: PS<P,T> = .ps([], [Marking([.p0: 1, .p1: 0, .p2: 0]), Marking([.p0: 0, .p1: 1, .p2: 0]), Marking([.p0: 0, .p1: 0, .p2: 1])])
    let ps3: PS<P,T> = .ps([Marking([.p0: 0, .p1: 2, .p2: 0])], [Marking([.p0: 1, .p1: 2, .p2: 0]), Marking([.p0: 0, .p1: 2, .p2: 1])])
    let ps4: PS<P,T> = .ps([Marking([.p0: 0, .p1: 2, .p2: 1])], [Marking([.p0: 1, .p1: 2, .p2: 1])])
    let ps5: PS<P,T> = .ps([Marking([.p0: 1, .p1: 2, .p2: 0])], [Marking([.p0: 1, .p1: 2, .p2: 1])])
    
    let expectedSPS: Set<PS<P,T>> = [ps1, ps2, ps3, ps4, ps5]
    
    let ctlFormula: CTL<P,T> = .AX(.ap(.t2))
    let sps = ctlFormula.eval(petrinet: pn)
    let simpliedSPS = PS.simplifiedSPS(sps: sps)

    XCTAssertTrue(PS.equiv(sps1: simpliedSPS, sps2: expectedSPS))
  }

  
  func testCTLEvalEF() {
    enum P: Place {
      typealias Content = Int

      case p1,p2,p3,p4,p5
    }

    enum T: Transition {
      case t1,t2,t4,t5
    }

    // Petri net that models the mutual exclusion problem
    let pn = PetriNet<P, T>(
      .pre(from: .p1, to: .t1, labeled: 1),
      .pre(from: .p3, to: .t1, labeled: 1),
      .post(from: .t1, to: .p4, labeled: 1),
      .pre(from: .p2, to: .t2, labeled: 1),
      .pre(from: .p3, to: .t2, labeled: 1),
      .post(from: .t2, to: .p5, labeled: 1),
      .pre(from: .p4, to: .t4, labeled: 1),
      .post(from: .t4, to: .p1, labeled: 1),
      .post(from: .t4, to: .p3, labeled: 1),
      .pre(from: .p5, to: .t5, labeled: 1),
      .post(from: .t5, to: .p2, labeled: 1),
      .post(from: .t5, to: .p3, labeled: 1)
    )
    
    let ps1: PS<P,T> = .ps([Marking([.p1: 0, .p2: 0, .p3: 0, .p4: 1, .p5: 1])], [])
    let ps2: PS<P,T> = .ps([Marking([.p1: 0, .p2: 1, .p3: 1, .p4: 1, .p5: 0])], [])
    let ps3: PS<P,T> = .ps([Marking([.p1: 1, .p2: 0, .p3: 1, .p4: 0, .p5: 1])], [])
    let ps4: PS<P,T> = .ps([Marking([.p1: 1, .p2: 1, .p3: 2, .p4: 0, .p5: 0])], [])
    let ps5: PS<P,T> = .ps([Marking([.p1: 0, .p2: 1, .p3: 0, .p4: 2, .p5: 0])], [])
    let ps6: PS<P,T> = .ps([Marking([.p1: 1, .p2: 0, .p3: 0, .p4: 0, .p5: 2])], [])
    let expectedSPS: Set<PS<P,T>> = [ps1, ps2, ps3, ps4, ps5, ps6]
    
    // Compute all markings that breaks the mutual exclusion
    let ctlFormula: CTL<P,T> = .EF(.and(.ap(.t4), .ap(.t5)))
    let sps = ctlFormula.eval(petrinet: pn)
    
    XCTAssertEqual(expectedSPS, PS.simplifiedSPS(sps: sps))
  }
  
  // No answers for EG/AG
  func testCTLEval1() {
    enum P: Place {
      typealias Content = Int

      case p0,p1
    }

    enum T: Transition {
      case t0,t1,t2
    }

    // Following Petri net:
    //          t0
    //       -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o -> ▭
    //          t1   p1   t2
    let pn = PetriNet<P, T>(
      .pre(from: .p0, to: .t0, labeled: 1),
      .pre(from: .p0, to: .t1, labeled: 1),
      .post(from: .t1, to: .p1, labeled: 1),
      .pre(from: .p1, to: .t2, labeled: 1),
      capacity: [.p0: 4, .p1: 4]
    )
    
    let ctlFormula1: CTL<P,T> = .AF(.ap(.t2))
    let ctlFormula2: CTL<P,T> = .EG(.ap(.t2))
    let ctlFormula3: CTL<P,T> = .AG(.ap(.t2))
    let sps1 = ctlFormula1.eval(petrinet: pn)
    let simpliedSPS1 = PS.simplifiedSPS(sps: sps1)
    let sps2 = ctlFormula2.eval(petrinet: pn)
    let simpliedSPS2 = PS.simplifiedSPS(sps: sps2)
    let sps3 = ctlFormula3.eval(petrinet: pn)
    let simpliedSPS3 = PS.simplifiedSPS(sps: sps3)
    
    let ps: PS<P,T> = .ps([Marking([.p0: 0, .p1: 1])], [])
    let expectedRes: Set<PS<P,T>> = [ps]
    
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, [])
    XCTAssertEqual(simpliedSPS3, [])
  }
  
  func testCTLEval2() {
    enum P: Place {
      typealias Content = Int

      case p0,p1
    }

    enum T: Transition {
      case t0,t1,t2
    }

    // Following Petri net:
    //          t0
    //       -> ▭
    // p0  /
    // o -
    //     \
    //       -> ▭ -> o <-> ▭
    //          t1   p1   t2
    let pn = PetriNet<P, T>(
      .pre(from: .p0, to: .t0, labeled: 1),
      .pre(from: .p0, to: .t1, labeled: 1),
      .post(from: .t1, to: .p1, labeled: 1),
      .pre(from: .p1, to: .t2, labeled: 1),
      .post(from: .t2, to: .p1, labeled: 1)
    )
    
    let ctlFormula1: CTL<P,T> = .AF(.ap(.t2))
    let ctlFormula2: CTL<P,T> = .EG(.ap(.t2))
    let ctlFormula3: CTL<P,T> = .AG(.ap(.t2))
    let sps1 = ctlFormula1.eval(petrinet: pn)
    let simpliedSPS1 = PS.simplifiedSPS(sps: sps1)
    let sps2 = ctlFormula2.eval(petrinet: pn)
    let simpliedSPS2 = PS.simplifiedSPS(sps: sps2)
    let sps3 = ctlFormula3.eval(petrinet: pn)
    let simpliedSPS3 = PS.simplifiedSPS(sps: sps3)
    
    let ps: PS<P,T> = .ps([Marking([.p0: 0, .p1: 1])], [])
    let expectedRes: Set<PS<P,T>> = [ps]
    
    XCTAssertEqual(simpliedSPS1, expectedRes)
    XCTAssertEqual(simpliedSPS2, expectedRes)
    XCTAssertEqual(simpliedSPS3, expectedRes)
  }
  
  func testForMe() {
    enum P: Place {
      typealias Content = Int

      case p0,p1
    }

    enum T: Transition {
      case t0
    }
    
    let sps1: Set<PS<P,T>> = [.ps([Marking([.p0: 0, .p1: 1])], [])]
    let sps2: Set<PS<P,T>> = [
      .ps([Marking([.p0: 1, .p1: 2])], []),
      .ps([Marking([.p0: 0, .p1: 2])], [Marking([.p0: 0, .p1: 2])])
    ]
    print(PS.isIncluded(sps1: sps1, sps2: sps2))
//
//    resTemp [([[p0: 0, p1: 1]], [])
//    ]
//    res [([[p0: 1, p1: 2]], [])
//    , ([[p0: 0, p1: 2]], [[p0: 1, p1: 2]])
  }
  
}
