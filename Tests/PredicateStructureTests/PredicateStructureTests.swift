import XCTest
@testable import PredicateStructure

final class PredicateStructureTests: XCTestCase {
    func testExample() {
      enum P: Place {
        typealias Content = Int
        
        case p1,p2,p3
      }
      
      enum T: Transition {
        case t1//, t2
      }
      
      let model = HeroNet<P, T>(
        .pre(from: .p1, to: .t1, labeled: 1),
        .pre(from: .p2, to: .t1, labeled: 2),
        .post(from: .t1, to: .p3, labeled: 3)
      )
      
      let marking1 = Marking<P>([.p1: 4, .p2: 5, .p3: 6])
      let marking2 = Marking<P>([.p1: 1, .p2: 42, .p3: 2])
      let expectedConvMax = Marking<P>([.p1: 4, .p2: 42, .p3: 6])
      let expectedConvMin = Marking<P>([.p1: 1, .p2: 5, .p3: 2])

      XCTAssertEqual(PS.convMax(markings: [marking1, marking2]), [expectedConvMax])
      XCTAssertEqual(PS.convMin(markings: [marking1, marking2]), [expectedConvMin])
      
      let marking3 = Marking<P>([.p1: 3, .p2: 5, .p3: 6])
      let marking4 = Marking<P>([.p1: 0, .p2: 4, .p3: 0])
      
      XCTAssertEqual(PS.minSet(markings: [marking1, marking2, marking3, marking4]), [marking4])

      let marking5 = Marking<P>([.p1: 4, .p2: 42, .p3: 6])
      let ps = PS.ps([marking1, marking3], [marking2])
      let psCan = PS.ps([marking1], [marking5])
      
      print(psCan)
      
      XCTAssertEqual(ps.canPS(), psCan)

//      print(model.fire(transition: .t1, from: marking1))
    }
}
