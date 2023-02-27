import XCTest
@testable import PredicateStructure

final class PetriNetTests: XCTestCase {
  
  func testRevertPN() {

    let pn = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1"],
      arcs: .pre(from: "p0", to: "t0", labeled: 2),
      .post(from: "t0", to: "p0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .pre(from: "p1", to: "t1", labeled: 1)
    )
    
//    let model = PetriNet<P, T>(
//      .pre(from: .p0, to: .t0, labeled: 2),
//      .post(from: .t0, to: .p0, labeled: 1),
//      .post(from: .t0, to: .p1, labeled: 1),
//      .pre(from: .p0, to: .t1, labeled: 1),
//      .pre(from: .p1, to: .t1, labeled: 1)
//    )
    
    let marking = Marking(["p0": 0, "p1": 1], net: pn)
    
//    print(model)
//    print(marking)

    let revertT0 = Marking(["p0": 2, "p1": 0], net: pn)
    let revertT1 = Marking(["p0": 1, "p1": 2], net: pn)
////    print(model.fire(transition: "t1", from: marking))
//
    XCTAssertEqual(pn.revert(marking: marking, transition: "t0"), revertT0)
    XCTAssertEqual(pn.revert(marking: marking, transition: "t1"), revertT1)
    XCTAssertEqual(pn.revert(marking: marking), [revertT0, revertT1])
    XCTAssertEqual(pn.revert(markings: [marking]), [revertT0, revertT1])
    
  }
  
  func testCapacity() {

    let pn = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 2),
      capacity: ["p0": 2, "p1": 2]
    )
      
    let marking1 = Marking(["p0": 1, "p1": 0], net: pn)
    let marking2 = Marking(["p0": 1, "p1": 1], net: pn)

    XCTAssertEqual(pn.fire(transition: "t0", from: marking1), Marking(["p0": 0, "p1": 2], net: pn))
    XCTAssertNil(pn.fire(transition: "t0", from: marking2))
  }
  
}
