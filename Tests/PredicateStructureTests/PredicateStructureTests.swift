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
    
    typealias SPS = Set<PS>
    
    let net = PetriNet(
      places: ["p1", "p2", "p3"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )
    
    let marking1 = Marking(["p1": 4, "p2": 5, "p3": 6], net: net)
    let marking2 = Marking(["p1": 1, "p2": 42, "p3": 2], net: net)
    let expectedConvMax = Marking(["p1": 4, "p2": 42, "p3": 6], net: net)
    let expectedConvMin = Marking(["p1": 1, "p2": 5, "p3": 2], net: net)
    let psEmpty: PS = PS(ps: nil, net: net)

    XCTAssertEqual(psEmpty.convMax(markings: [marking1, marking2]), [expectedConvMax])
    XCTAssertEqual(psEmpty.convMin(markings: [marking1, marking2]), [expectedConvMin])
    
    let marking3 = Marking(["p1": 3, "p2": 5, "p3": 6], net: net)
    let marking4 = Marking(["p1": 0, "p2": 4, "p3": 0], net: net)
    
    XCTAssertEqual(psEmpty.minSet(markings: [marking1, marking2, marking3, marking4]), [marking4])

    let marking5 = Marking(["p1": 4, "p2": 42, "p3": 6], net: net)
    let ps = PS(ps: ([marking1, marking3], [marking2]), net: net)
    let psCan = PS(ps: ([marking1], [marking5]), net: net)
          
    XCTAssertEqual(ps.canonised(), psCan)
    
    let marking6 = Marking(["p1": 1, "p2": 3, "p3": 5], net: net)
    
    let expectedPS1 = PS(ps: ([marking6], [Marking(["p1": 2, "p2": 3, "p3": 5], net: net), Marking(["p1": 1, "p2": 4, "p3": 5], net: net), Marking(["p1": 1, "p2": 3, "p3": 6], net: net)]), net: net)
    XCTAssertEqual(psEmpty.encodeMarking(marking6), expectedPS1)
    
    let marking7 = Marking(["p1": 1, "p2": 3, "p3": 6], net: net)
    let expectedPS2 = PS(ps: ([marking7], [Marking(["p1": 2, "p2": 3, "p3": 6], net: net), Marking(["p1": 1, "p2": 4, "p3": 6], net: net), Marking(["p1": 1, "p2": 3, "p3": 7], net: net)]), net: net)
    
    XCTAssertEqual(psEmpty.encodeMarkingSet([marking6, marking7]), [expectedPS1,expectedPS2])
  }
  
  func testSPS1() {
    typealias SPS = Set<PS>
    
    let net = PetriNet(
      places: ["p1", "p2", "p3"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )

    let marking1 = Marking(["p1": 4, "p2": 5, "p3": 6], net: net)
    let marking2 = Marking(["p1": 1, "p2": 42,"p3": 2], net: net)
    let marking3 = Marking(["p1": 3, "p2": 5, "p3": 6], net: net)
    let marking4 = Marking(["p1": 0, "p2": 4, "p3": 0], net: net)

    let ps1 = PS(ps: ([marking1], [marking2]), net: net)
    let ps2 = PS(ps: ([marking3], [marking4]), net: net)

    XCTAssertEqual(ps1.union(sps1: [ps1], sps2: [PS(ps: nil, net: net)]), [ps1])
    XCTAssertEqual(ps1.intersection(sps1: [ps1], sps2: [ps2] , isCanonical: false), [PS(ps: ([marking1, marking3], [marking2, marking4]), net: net)])

    let ps3 = PS(ps: ([marking2], [marking3]), net: net)

    let expectedSPS: SPS = [
      PS(ps: ([marking1, marking2], [marking2, marking3]), net: net),
      PS(ps: ([marking3, marking2], [marking3, marking4]), net: net),
    ]

    XCTAssertEqual(ps1.intersection(sps1: [ps1,ps2], sps2: [ps3], isCanonical: false), expectedSPS)
  }

  func testSPS2() {
    
    typealias SPS = Set<PS>
    
    let net = PetriNet(
      places: ["p1", "p2"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )

    let marking1 = Marking(["p1": 1, "p2": 2], net: net)
    let marking2 = Marking(["p1": 3, "p2": 2], net: net)
    let marking3 = Marking(["p1": 3, "p2": 0], net: net)
    let marking4 = Marking(["p1": 5, "p2": 8], net: net)
    let sps: SPS = [PS(ps: ([marking1], [marking2]), net: net), PS(ps: ([marking3], [marking4]), net: net)]
    let expectedSPS: SPS = [PS(ps: ([], [marking1, marking3]), net: net), PS(ps: ([marking4], []), net: net)]

    let emptyPS = PS(ps: nil, net: net)
    XCTAssertEqual(emptyPS.not(sps: sps), expectedSPS)
  }

  func testSPSObservator() {
    
    typealias SPS = Set<PS>
    
    let net = PetriNet(
      places: ["p1", "p2"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )

    var marking1 = Marking(["p1": 4, "p2": 5], net: net)
    var marking2 = Marking(["p1": 9, "p2": 10], net: net)
    var marking3 = Marking(["p1": 3, "p2": 5], net: net)
    var marking4 = Marking(["p1": 11, "p2": 10], net: net)
    var sps1: SPS = [PS(ps: ([marking1], [marking2]), net: net)]
    var sps2: SPS = [PS(ps: ([marking3], [marking4]), net: net)]
    
    let emptyPS = PS(ps: nil, net: net)
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(11,10)})}
    XCTAssertTrue(emptyPS.isIncluded(sps1: sps1, sps2: sps2))

    marking4 = Marking(["p1": 11, "p2": 9], net: net)
    sps2 = [PS(ps: ([marking3], [marking4]), net: net)]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(11,9)})}
    XCTAssertFalse(emptyPS.isIncluded(sps1: sps1, sps2: sps2))

    marking4 = Marking(["p1": 7, "p2": 7], net: net)
    let marking5 = Marking(["p1": 6, "p2": 4], net: net)
    let marking6 = Marking(["p1": 14, "p2": 11], net: net)
    sps2 = [PS(ps: ([marking3], [marking4]), net: net), PS(ps: ([marking5], [marking6]), net: net)]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(7,7)}), ({(6,4)}, {(14,11)})}
    XCTAssertTrue(emptyPS.isIncluded(sps1: sps1, sps2: sps2))
    // ({(4,5)}, {(9,10)}) ∈ {({(3,5)}, {(7,7)}), ({(6,4)}, {(14,11)})}
    XCTAssertTrue(emptyPS.isIn(ps: PS(ps: ([marking1], [marking2]), net: net), sps: sps2))

    // ∅ ⊆ {({(4,5)}, {(9,10)})}
    XCTAssertTrue(emptyPS.isIncluded(sps1: [], sps2: sps1))
    // {({(4,5)}, {(9,10)})} ⊆ ∅
    XCTAssertFalse(emptyPS.isIncluded(sps1: sps1, sps2: []))

    XCTAssertTrue(emptyPS.isEquiv(sps1: sps1, sps2: sps1))

    marking1 = Marking(["p1": 1, "p2": 2], net: net)
    marking2 = Marking(["p1": 5, "p2": 8], net: net)
    marking3 = Marking(["p1": 3, "p2": 0], net: net)
    marking4 = Marking(["p1": 3, "p2": 2], net: net)

    sps1 = [PS(ps: ([marking1], [marking2]), net: net), PS(ps: ([marking3], [marking4]), net: net)]
    sps2 = [PS(ps: ([marking1], [marking4]), net: net), PS(ps: ([marking3], [marking2]), net: net)]

    // {({(1,2)}, {(5,8)}), ({(3,0)}, {(3,2)})} ≈ {({(1,2)}, {(3,2)}), ({(3,0)}, {(5,8)})}
    XCTAssertTrue(emptyPS.isEquiv(sps1: sps1, sps2: sps2))

    let ps1 = PS(ps: ([Marking(["p1": 1, "p2": 4], net: net)], [Marking(["p1": 5, "p2": 5], net: net)]), net: net)
    let ps2 = PS(ps: ([Marking(["p1": 5, "p2": 5], net: net)], [Marking(["p1": 10, "p2": 7], net: net)]), net: net)
    let ps3 = PS(ps: ([Marking(["p1": 1, "p2": 4], net: net)], [Marking(["p1": 10, "p2": 7], net: net)]), net: net)

    XCTAssertTrue(emptyPS.isEquiv(sps1: [ps1,ps2], sps2: [ps3]))

    let ps4 = PS(ps: ([Marking(["p1": 2, "p2": 3], net: net)], [Marking(["p1": 8, "p2": 9], net: net)]), net: net)
    let ps5 = PS(ps: ([Marking(["p1": 7, "p2": 8], net: net)], [Marking(["p1": 10, "p2": 10], net: net)]), net: net)
    let ps6 = PS(ps: ([Marking(["p1": 2, "p2": 3], net: net)], [Marking(["p1": 10, "p2": 10], net: net)]), net: net)
    XCTAssertTrue(emptyPS.isEquiv(sps1: [ps4,ps5], sps2: [ps6]))

    let ps7 = PS(ps: ([Marking(["p1": 4, "p2": 1], net: net)], [Marking(["p1": 4, "p2": 4], net: net)]), net: net)
    let ps8 = PS(ps: ([Marking(["p1": 1, "p2": 4], net: net)], []), net: net)
    let ps9 = PS(ps: ([Marking(["p1": 4, "p2": 1], net: net)], []), net: net)
    let ps10 = PS(ps: ([Marking(["p1": 1, "p2": 4], net: net)], [Marking(["p1": 4, "p2": 4], net: net)]), net: net)

    XCTAssertTrue(emptyPS.isEquiv(sps1: [ps7,ps8], sps2: [ps9,ps10]))
  }

  func testRevertPS() {

    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1"],
      arcs: .pre(from: "p0", to: "t0", labeled: 2),
      .post(from: "t0", to: "p0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .pre(from: "p1", to: "t1", labeled: 1)
    )
    let marking1 = Marking(["p0": 0, "p1": 1], net: net)
    let marking2 = Marking(["p0": 1, "p1": 1], net: net)

    let revertT0 = Marking(["p0": 2, "p1": 0], net: net)
    let revertT1 = Marking(["p0": 1, "p1": 2], net: net)
    let revertT2 = Marking(["p0": 2, "p1": 2], net: net)
//    print(model.fire(transition: .t1, from: marking1))
    
    let ps1 = PS(ps: ([marking1], []), net: net)
    let ps2 = PS(ps: ([revertT0], []), net: net)
    let ps3 = PS(ps: ([revertT1], []), net: net)
    let ps4 = PS(ps: ([marking1, marking2], []), net: net)
    let ps5 = PS(ps: ([revertT1, revertT2], []), net: net)

    XCTAssertEqual(ps1.revert(transition: "t0"), ps2)
    XCTAssertEqual(ps1.revert(transition: "t1"), ps3)
    XCTAssertEqual(ps4.revert(transition: "t1"), ps5)
    print(net.revert(marking: marking2))
  }

  func testUnderlyingMarking() {

    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      capacity: ["p0": 3, "p1": 3, "p2": 3]
    )

    var ps: PS = PS(ps: ([Marking(["p0": 0, "p1": 1, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 1, "p2": 0], net: net), Marking(["p0": 0, "p1": 2, "p2": 0], net: net), Marking(["p0": 0, "p1": 1, "p2": 1], net: net)]), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 1)

    // 4*4*4
    ps = PS(ps: ([Marking(["p0": 0, "p1": 0, "p2": 0], net: net)], []), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 64)

    // 4*4*3
    ps = PS(ps: ([Marking(["p0": 0, "p1": 0, "p2": 1], net: net)], []), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 48)

    ps = PS(ps: ([Marking(["p0": 0, "p1": 0, "p2": 2], net: net)], [Marking(["p0": 0, "p1": 0, "p2": 1], net: net)]), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 0)
  }
  
}
