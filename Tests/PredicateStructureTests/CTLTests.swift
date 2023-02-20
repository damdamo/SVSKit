import XCTest
@testable import PredicateStructure

final class CTLTests: XCTestCase {
  
  func testCTLEvalEF() {
    enum P: Place {
      typealias Content = Int

      case p1,p2,p3,p4,p5
    }

    enum T: Transition {
      case t1,t2,t4,t5
    }

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
    
    let ctlFormula: CTL<P,T> = .EF(.and(.ap(.t4), .ap(.t5)))
    let sps = ctlFormula.eval(petrinet: pn)
    
    XCTAssertEqual(expectedSPS, PS.simplifiedSPS(sps: sps))
//    print(PS.simplifiedSPS(sps: sps))
  }
  
}
