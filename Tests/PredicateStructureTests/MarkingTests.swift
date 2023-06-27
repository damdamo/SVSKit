import XCTest
//@testable import PredicateStructure
import PredicateStructure

final class MarkingTests: XCTestCase {
   
  func testPS() {
    typealias SPS = Set<PS>
    
    let net = PetriNet(
      places: ["p1", "p2", "p3"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )
    
    let marking1 = Marking(["p1": 4, "p2": 5, "p3": 6], net: net)
    let marking2 = Marking(["p1": 1, "p2": 42, "p3": 2], net: net)
    let marking3 = Marking(["p1": 4, "p2": 5, "p3": 9], net: net)
    
    XCTAssertTrue(marking2.leq(marking1))
    XCTAssertFalse(marking1.leq(marking2))
    XCTAssertTrue(marking1.leq(marking3))
    XCTAssertTrue(marking1.leq(marking1))
    }
  
}
