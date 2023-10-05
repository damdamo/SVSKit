import XCTest
//@testable import PredicateStructure
import SVSKit

final class PetriNetTests: XCTestCase {
  
  func testRevertPN() {
    let pn = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1"],
      arcs: .pre(from: "p0", to: "t0", labeled: 2),
      .post(from: "t0", to: "p0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .pre(from: "p1", to: "t1", labeled: 1),
      capacity: ["p0": 10, "p1": 10]
    )
    
    let marking = Marking(["p0": 0, "p1": 1], net: pn)
    let revertT0 = Marking(["p0": 2, "p1": 0], net: pn)
    let revertT1 = Marking(["p0": 1, "p1": 2], net: pn)
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
  
  func testLoadPN() {
    let p1 = PnmlParser()
    let (net1, _) = p1.loadPN(filePath: "SwimmingPool-1.pnml")
    var countArcs = 0
    for (_, arcs) in net1.input {
      countArcs += arcs.count
    }
    for (_, arcs) in net1.output {
      countArcs += arcs.count
    }
    XCTAssertEqual(net1.places.count, 9)
    XCTAssertEqual(net1.transitions.count, 7)
    XCTAssertEqual(countArcs, 20)
    
    let p2 = PnmlParser()
    let (net2, _) = p2.loadPN(filePath: "NQueens-PT-05.xml")
    countArcs = 0
    for (_, arcs) in net2.input {
      countArcs += arcs.count
    }
    for (_, arcs) in net2.output {
      countArcs += arcs.count
    }
    XCTAssertEqual(net2.places.count, 55)
    XCTAssertEqual(net2.transitions.count, 25)
    XCTAssertEqual(countArcs, 125)
    
    // This is how to upload a pnml from an url
//    let p3 = PnmlParser()
//    if let url = URL(string: "https://www.pnml.org/version-2009/examples/philo.pnml") {
//      let (net3, marking3) = p3.loadPN(url: url)
//    }
  }
  
}
