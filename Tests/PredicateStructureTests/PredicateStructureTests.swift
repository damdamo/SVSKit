import XCTest
@testable import PredicateStructure

final class PredicateStructureTests: XCTestCase {
  
//  func testReminderPN() {
//    enum P: Place {
//      typealias Content = Int
//
//      case p1,p2,p3
//    }
//
//    enum T: Transition {
//      case t1//, t2
//    }
//
//    let model = HeroNet<P, T>(
//      .pre(from: .p1, to: .t1, labeled: 1),
//      .pre(from: .p2, to: .t1, labeled: 2),
//      .post(from: .t1, to: .p3, labeled: 3)
//    )
//    let marking1 = Marking<P>([.p1: 4, .p2: 5, .p3: 6])
//
//    print(model.fire(transition: .t1, from: marking1))
//  }
  
  func testPS() {
    
    typealias SPS = Set<PS<P>>
    enum P: Place {
      typealias Content = Int
      
      case p1,p2,p3
    }
    
    enum T: Transition {
      case t1//, t2
    }
    
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
          
    XCTAssertEqual(ps.canPS(), psCan)
  }
  
  func testSPS1() {
    typealias SPS = Set<PS<P>>
    enum P: Place {
      typealias Content = Int
      
      case p1,p2,p3
    }
    
    enum T: Transition {
      case t1//, t2
    }
    
    let marking1 = Marking<P>([.p1: 4, .p2: 5, .p3: 6])
    let marking2 = Marking<P>([.p1: 1, .p2: 42, .p3: 2])
    let marking3 = Marking<P>([.p1: 3, .p2: 5, .p3: 6])
    let marking4 = Marking<P>([.p1: 0, .p2: 4, .p3: 0])
    
    let ps1 = PS.ps([marking1], [marking2])
    let ps2 = PS.ps([marking3], [marking4])
    
    XCTAssertEqual(PS.intersection(s1: [ps1], s2: [ps2] , isCanonical: false), [PS.ps([marking1, marking3], [marking2, marking4])])
    
    let ps3 = PS.ps([marking2], [marking3])
    
    let expectedSPS: SPS = [
      .ps([marking1, marking2], [marking2, marking3]),
      .ps([marking3, marking2], [marking3, marking4]),
    ]
    
    XCTAssertEqual(PS.intersection(s1: [ps1,ps2], s2: [ps3], isCanonical: false), expectedSPS)
  }
  
  func testSPS2() {
    typealias SPS = Set<PS<P>>
    enum P: Place {
      typealias Content = Int
      
      case p1,p2
    }
    
    enum T: Transition {
      case t1//, t2
    }
    
    let marking1 = Marking<P>([.p1: 1, .p2: 2])
    let marking2 = Marking<P>([.p1: 3, .p2: 2])
    let marking3 = Marking<P>([.p1: 3, .p2: 0])
    let marking4 = Marking<P>([.p1: 5, .p2: 8])
    let sps: SPS = [.ps([marking1], [marking2]), .ps([marking3], [marking4])]
    let expectedSPS: SPS = [.ps([], [marking1, marking3]), .ps([marking4], [])]
    
    XCTAssertEqual(PS.notSPS(sps: sps), expectedSPS)
  }

  
}
