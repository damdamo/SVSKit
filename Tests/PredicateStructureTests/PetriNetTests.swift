//import XCTest
//@testable import PredicateStructure
//
//final class PetriNetTests: XCTestCase {
//  
//  func testRevertPN() {
//    enum P: Place {
//      typealias Content = Int
//
//      case p0,p1
//    }
//
//    enum T: Transition {
//      case t0, t1
//    }
//
//    let model = PetriNet<P, T>(
//      .pre(from: .p0, to: .t0, labeled: 2),
//      .post(from: .t0, to: .p0, labeled: 1),
//      .post(from: .t0, to: .p1, labeled: 1),
//      .pre(from: .p0, to: .t1, labeled: 1),
//      .pre(from: .p1, to: .t1, labeled: 1)
//    )
//    let marking = Marking<P>([.p0: 0, .p1: 1])
//
//    let revertT0 = Marking<P>([.p0: 2, .p1: 0])
//    let revertT1 = Marking<P>([.p0: 1, .p1: 2])
////    print(model.fire(transition: .t1, from: marking1))
//    
//    XCTAssertEqual(model.revert(marking: marking, transition: .t0), revertT0)
//    XCTAssertEqual(model.revert(marking: marking, transition: .t1), revertT1)
//    XCTAssertEqual(model.revert(marking: marking), [revertT0, revertT1])
//    XCTAssertEqual(model.revert(markings: [marking]), [revertT0, revertT1])
//    
//  }
//  
//  func testCapacity() {
//    enum P: Place {
//      typealias Content = Int
//
//      case p0,p1
//    }
//
//    enum T: Transition {
//      case t0
//    }
//
//    let model = PetriNet<P, T>(
//      .pre(from: .p0, to: .t0, labeled: 1),
//      .post(from: .t0, to: .p1, labeled: 2),
//      capacity: [.p0: 2, .p1: 2]
//    )
//    let marking1 = Marking<P>([.p0: 1, .p1: 0])
//    let marking2 = Marking<P>([.p0: 1, .p1: 1])
//
//    XCTAssertEqual(model.fire(transition: .t0, from: marking1), Marking<P>([.p0: 0, .p1: 2]))
//    XCTAssertNil(model.fire(transition: .t0, from: marking2))
//  }
//  
//}
