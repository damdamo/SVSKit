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
    
    XCTAssertEqual(PS.union(s1: [ps1], s2: [.empty]), [ps1])
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
  
  func testSPSObservator() {
    typealias SPS = Set<PS<P>>
    enum P: Place {
      typealias Content = Int
      
      case p1,p2
    }
    
    enum T: Transition {
      case t1//, t2
    }
    
    var marking1 = Marking<P>([.p1: 4, .p2: 5])
    var marking2 = Marking<P>([.p1: 9, .p2: 10])
    var marking3 = Marking<P>([.p1: 3, .p2: 5])
    var marking4 = Marking<P>([.p1: 11, .p2: 10])
    var sps1: SPS = [.ps([marking1], [marking2])]
    var sps2: SPS = [.ps([marking3], [marking4])]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(11,10)})}
    XCTAssertTrue(PS.isIncluded(s1: sps1, s2: sps2))

    marking4 = Marking<P>([.p1: 11, .p2: 9])
    sps2 = [.ps([marking3], [marking4])]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(11,9)})}
    XCTAssertFalse(PS.isIncluded(s1: sps1, s2: sps2))
    
    marking4 = Marking<P>([.p1: 7, .p2: 7])
    let marking5 = Marking<P>([.p1: 6, .p2: 4])
    let marking6 = Marking<P>([.p1: 14, .p2: 11])
    sps2 = [.ps([marking3], [marking4]), .ps([marking5], [marking6])]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(7,7)}), ({(6,4)}, {(14,11)})}
    XCTAssertTrue(PS.isIncluded(s1: sps1, s2: sps2))
    
    // ∅ ⊆ {({(4,5)}, {(9,10)})}
    XCTAssertTrue(PS.isIncluded(s1: [], s2: sps1))
    
    XCTAssertTrue(PS.equiv(s1: sps1, s2: sps1))
    
    marking1 = Marking<P>([.p1: 1, .p2: 2])
    marking2 = Marking<P>([.p1: 5, .p2: 8])
    marking3 = Marking<P>([.p1: 3, .p2: 0])
    marking4 = Marking<P>([.p1: 3, .p2: 2])
    
    sps1 = [.ps([marking1], [marking2]), .ps([marking3], [marking4])]
    sps2 = [.ps([marking1], [marking4]), .ps([marking3], [marking2])]

    // {({(1,2)}, {(5,8)}), ({(3,0)}, {(3,2)})} ≈ {({(1,2)}, {(3,2)}), ({(3,0)}, {(5,8)})}
    XCTAssertTrue(PS.equiv(s1: sps1, s2: sps2))
  }

  
}
