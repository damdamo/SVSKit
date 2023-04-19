import XCTest
//@testable import PredicateStructure
import PredicateStructure

final class PredicateStructureTests: XCTestCase {
   
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
    let psEmpty: PS = PS(value: nil, net: net)

    XCTAssertEqual(PS.convMax(markings: [marking1, marking2], net: net), [expectedConvMax])
    XCTAssertEqual(PS.convMin(markings: [marking1, marking2], net: net), [expectedConvMin])
    
    let marking3 = Marking(["p1": 3, "p2": 5, "p3": 6], net: net)
    let marking4 = Marking(["p1": 0, "p2": 4, "p3": 0], net: net)
    
    XCTAssertEqual(psEmpty.minSet(markings: [marking1, marking2, marking3, marking4]), [marking4])

    let marking5 = Marking(["p1": 4, "p2": 42, "p3": 6], net: net)
    let ps = PS(value: ([marking1, marking3], [marking2]), net: net)
    let psCan = PS(value: ([marking1], [marking5]), net: net)
          
    XCTAssertEqual(ps.canonised(), psCan)
    
    let marking6 = Marking(["p1": 1, "p2": 3, "p3": 5], net: net)
    
    let expectedPS1 = PS(value: ([marking6], [Marking(["p1": 2, "p2": 3, "p3": 5], net: net), Marking(["p1": 1, "p2": 4, "p3": 5], net: net), Marking(["p1": 1, "p2": 3, "p3": 6], net: net)]), net: net)
    XCTAssertEqual(psEmpty.encodeMarking(marking6), expectedPS1)
    
    let marking7 = Marking(["p1": 1, "p2": 3, "p3": 6], net: net)
    let expectedPS2 = PS(value: ([marking7], [Marking(["p1": 2, "p2": 3, "p3": 6], net: net), Marking(["p1": 1, "p2": 4, "p3": 6], net: net), Marking(["p1": 1, "p2": 3, "p3": 7], net: net)]), net: net)
    
    XCTAssertEqual(psEmpty.encodeMarkingSet([marking6, marking7]), [expectedPS1,expectedPS2])
  }
  
  func testSPS1() {
    let net = PetriNet(
      places: ["p1", "p2", "p3"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )

    let marking1 = Marking(["p1": 4, "p2": 5, "p3": 6], net: net)
    let marking2 = Marking(["p1": 1, "p2": 42,"p3": 2], net: net)
    let marking3 = Marking(["p1": 3, "p2": 5, "p3": 6], net: net)
    let marking4 = Marking(["p1": 0, "p2": 4, "p3": 0], net: net)

    let ps1 = PS(value: ([marking1], [marking2]), net: net)
    let ps2 = PS(value: ([marking3], [marking4]), net: net)

    XCTAssertEqual(SPS(values: [ps1]).union([PS(value: nil, net: net)]), [ps1])
    XCTAssertEqual(SPS(values: [ps1]).intersection([ps2], isCanonical: false), [PS(value: ([marking1, marking3], [marking2, marking4]), net: net)])

    let ps3 = PS(value: ([marking2], [marking3]), net: net)

    let expectedSPS: SPS = [
      PS(value: ([marking1, marking2], [marking2, marking3]), net: net),
      PS(value: ([marking3, marking2], [marking3, marking4]), net: net),
    ]
    
    XCTAssertEqual(SPS(values: [ps1,ps2]).intersection([ps3], isCanonical: false), expectedSPS)
  }

  func testSPS2() {
    let net = PetriNet(
      places: ["p1", "p2"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )

    let marking1 = Marking(["p1": 1, "p2": 2], net: net)
    let marking2 = Marking(["p1": 3, "p2": 2], net: net)
    let marking3 = Marking(["p1": 3, "p2": 0], net: net)
    let marking4 = Marking(["p1": 5, "p2": 8], net: net)
    let sps: SPS = [PS(value: ([marking1], [marking2]), net: net), PS(value: ([marking3], [marking4]), net: net)]
    let expectedSPS: SPS = [PS(value: ([net.zeroMarking()], [marking1, marking3]), net: net), PS(value: ([marking4], []), net: net)]

    XCTAssertEqual(sps.not(), expectedSPS)
  }

  func testSPSObservator() {
    let net = PetriNet(
      places: ["p1", "p2"],
      transitions: ["t1"],
      arcs: .pre(from: "p1", to: "t1", labeled: 2)
    )

    var marking1 = Marking(["p1": 4, "p2": 5], net: net)
    var marking2 = Marking(["p1": 9, "p2": 10], net: net)
    var marking3 = Marking(["p1": 3, "p2": 5], net: net)
    var marking4 = Marking(["p1": 11, "p2": 10], net: net)
    var sps1: SPS = [PS(value: ([marking1], [marking2]), net: net)]
    var sps2: SPS = [PS(value: ([marking3], [marking4]), net: net)]

    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(11,10)})}
    XCTAssertTrue(sps1.isIncluded(sps2))

    marking4 = Marking(["p1": 11, "p2": 9], net: net)
    sps2 = [PS(value: ([marking3], [marking4]), net: net)]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(11,9)})}
    XCTAssertFalse(sps1.isIncluded(sps2))

    marking4 = Marking(["p1": 7, "p2": 7], net: net)
    let marking5 = Marking(["p1": 6, "p2": 4], net: net)
    let marking6 = Marking(["p1": 14, "p2": 11], net: net)
    sps2 = [PS(value: ([marking3], [marking4]), net: net), PS(value: ([marking5], [marking6]), net: net)]
    // {({(4,5)}, {(9,10)})} ⊆ {({(3,5)}, {(7,7)}), ({(6,4)}, {(14,11)})}
    XCTAssertTrue(sps1.isIncluded(sps2))
    // ({(4,5)}, {(9,10)}) ∈ {({(3,5)}, {(7,7)}), ({(6,4)}, {(14,11)})}
    XCTAssertTrue(sps2.contains(ps: PS(value: ([marking1], [marking2]), net: net)))

    // ∅ ⊆ {({(4,5)}, {(9,10)})}
    XCTAssertTrue(SPS(values: []).isIncluded(sps1))
    // {({(4,5)}, {(9,10)})} ⊆ ∅
    XCTAssertFalse(sps1.isIncluded([]))

    XCTAssertTrue(sps1.isEquiv(sps1))

    marking1 = Marking(["p1": 1, "p2": 2], net: net)
    marking2 = Marking(["p1": 5, "p2": 8], net: net)
    marking3 = Marking(["p1": 3, "p2": 0], net: net)
    marking4 = Marking(["p1": 3, "p2": 2], net: net)

    sps1 = [PS(value: ([marking1], [marking2]), net: net), PS(value: ([marking3], [marking4]), net: net)]
    sps2 = [PS(value: ([marking1], [marking4]), net: net), PS(value: ([marking3], [marking2]), net: net)]

    // {({(1,2)}, {(5,8)}), ({(3,0)}, {(3,2)})} ≈ {({(1,2)}, {(3,2)}), ({(3,0)}, {(5,8)})}
    XCTAssertTrue(sps1.isEquiv(sps2))

    let ps1 = PS(value: ([Marking(["p1": 1, "p2": 4], net: net)], [Marking(["p1": 5, "p2": 5], net: net)]), net: net)
    let ps2 = PS(value: ([Marking(["p1": 5, "p2": 5], net: net)], [Marking(["p1": 10, "p2": 7], net: net)]), net: net)
    let ps3 = PS(value: ([Marking(["p1": 1, "p2": 4], net: net)], [Marking(["p1": 10, "p2": 7], net: net)]), net: net)

    XCTAssertTrue(SPS(values: [ps1, ps2]).isEquiv([ps3]))

    let ps4 = PS(value: ([Marking(["p1": 2, "p2": 3], net: net)], [Marking(["p1": 8, "p2": 9], net: net)]), net: net)
    let ps5 = PS(value: ([Marking(["p1": 7, "p2": 8], net: net)], [Marking(["p1": 10, "p2": 10], net: net)]), net: net)
    let ps6 = PS(value: ([Marking(["p1": 2, "p2": 3], net: net)], [Marking(["p1": 10, "p2": 10], net: net)]), net: net)
    XCTAssertTrue(SPS(values: [ps4, ps5]).isEquiv([ps6]))

    let ps7 = PS(value: ([Marking(["p1": 4, "p2": 1], net: net)], [Marking(["p1": 4, "p2": 4], net: net)]), net: net)
    let ps8 = PS(value: ([Marking(["p1": 1, "p2": 4], net: net)], []), net: net)
    let ps9 = PS(value: ([Marking(["p1": 4, "p2": 1], net: net)], []), net: net)
    let ps10 = PS(value: ([Marking(["p1": 1, "p2": 4], net: net)], [Marking(["p1": 4, "p2": 4], net: net)]), net: net)

    XCTAssertTrue(SPS(values: [ps7, ps8]).isEquiv([ps9,ps10]))
  }

  func testRevertPS() {
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0", "t1"],
      arcs: .pre(from: "p0", to: "t0", labeled: 2),
      .post(from: "t0", to: "p0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      .pre(from: "p0", to: "t1", labeled: 1),
      .pre(from: "p1", to: "t1", labeled: 1),
      capacity: ["p0": 10, "p1": 10]
    )
    let marking1 = Marking(["p0": 0, "p1": 1], net: net)
    let marking2 = Marking(["p0": 1, "p1": 1], net: net)

    let revertT0 = Marking(["p0": 2, "p1": 0], net: net)
    let revertT1 = Marking(["p0": 1, "p1": 2], net: net)
    let revertT2 = Marking(["p0": 2, "p1": 2], net: net)

    let ps1 = PS(value: ([marking1], []), net: net)
    let ps2 = PS(value: ([revertT0], []), net: net)
    let ps3 = PS(value: ([revertT1], []), net: net)
    let ps4 = PS(value: ([marking1, marking2], []), net: net)
    let ps5 = PS(value: ([revertT1, revertT2], []), net: net)

    XCTAssertEqual(ps1.revert(transition: "t0"), ps2)
    XCTAssertEqual(ps1.revert(transition: "t1"), ps3)
    XCTAssertEqual(ps4.revert(transition: "t1"), ps5)
  }

  func testUnderlyingMarking() {
    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      capacity: ["p0": 3, "p1": 3, "p2": 3]
    )

    var ps: PS = PS(value: ([Marking(["p0": 0, "p1": 1, "p2": 0], net: net)], [Marking(["p0": 1, "p1": 1, "p2": 0], net: net), Marking(["p0": 0, "p1": 2, "p2": 0], net: net), Marking(["p0": 0, "p1": 1, "p2": 1], net: net)]), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 1)

    // 4*4*4
    ps = PS(value: ([Marking(["p0": 0, "p1": 0, "p2": 0], net: net)], []), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 64)

    // 4*4*3
    ps = PS(value: ([Marking(["p0": 0, "p1": 0, "p2": 1], net: net)], []), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 48)

    ps = PS(value: ([Marking(["p0": 0, "p1": 0, "p2": 2], net: net)], [Marking(["p0": 0, "p1": 0, "p2": 1], net: net)]), net: net)
    XCTAssertEqual(ps.underlyingMarkings().count, 0)
    
    let sps = SPS(values: [ps, PS(value: ([Marking(["p0": 0, "p1": 0, "p2": 0], net: net)], []), net: net)])
    XCTAssertEqual(sps.underlyingMarkings().count, 64)
  }
  
  func testSimplified() {
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1)
    )
    
    let marking1 = Marking(["p0": 0, "p1": 0], net: net)
    let marking2 = Marking(["p0": 5, "p1": 5], net: net)
    let marking3 = Marking(["p0": 10, "p1": 10], net: net)
    let marking4 = Marking(["p0": 15, "p1": 15], net: net)
    
    let ps1 = PS(value: ([marking1], [marking2]), net: net)
    let ps2 = PS(value: ([marking2], [marking3]), net: net)
    let ps3 = PS(value: ([marking3], [marking4]), net: net)
    let ps4 = PS(value: ([marking1], [marking4]), net: net)
    
    let sps1 = SPS(values: [ps1, ps2, ps3])
    let sps2 = SPS(values: [ps4])
    XCTAssertEqual(sps1.simplified(), sps2)
    XCTAssertEqual(ps1.merge(ps3), [ps1,ps3])
    
    let ps5 = PS(value: ([marking2], []), net: net)
    XCTAssertEqual(ps5.merge(ps3), [ps5])
    
    let marking5 = Marking(["p0": 3, "p1": 3], net: net)
    let ps6 = PS(value: ([marking5], [marking4]), net: net)
    let ps7 = PS(value: ([marking1], [marking4]), net: net)
    XCTAssertEqual(ps6.merge(ps1), [ps7])
    
    let ps8 = PS(value: ([marking3], [marking2]), net: net)
    XCTAssertEqual(SPS(values: [ps8]).simplified(), [])
  }
  
  func testInclude() {
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1)
    )
    
    let marking1 = Marking(["p0": 1, "p1": 1], net: net)
    let marking2 = Marking(["p0": 0, "p1": 1], net: net)
    let ps1 = PS(value: ([marking2], [marking1]), net: net)
    let ps2 = PS(value: ([marking1], []), net: net)
    
    XCTAssertFalse(ps1.isIncluded(ps2))
    XCTAssertFalse(ps2.isIncluded(ps1))
    
    let ps3 = PS(value: ([marking2], []), net: net)
    
    XCTAssertTrue(ps1.isIncluded(ps3))
    XCTAssertFalse(ps3.isIncluded(ps1))
 
//    let ps4 = PS(value: ([],[]), net: net)
//    
//    XCTAssertTrue(ps1.isIncluded(ps4))
//    XCTAssertTrue(ps2.isIncluded(ps4))
//    XCTAssertFalse(ps4.isIncluded(ps1))
//    XCTAssertFalse(ps4.isIncluded(ps2))
    
    let ps5 = PS(value: ([],[marking1]), net: net)
    XCTAssertTrue(ps1.isIncluded(ps5))
    XCTAssertFalse(ps5.isIncluded(ps1))
  }
  
  func testSubtraction1() {
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1)
    )
    
    let m1 = Marking(["p0": 2, "p1": 3], net: net)
    let m2 = Marking(["p0": 0, "p1": 8], net: net)
    let m3 = Marking(["p0": 0, "p1": 6], net: net)
    let m4 = Marking(["p0": 3, "p1": 3], net: net)
    let m5 =  Marking(["p0": 2, "p1": 6], net: net)
    let m1p = Marking(["p0": 3, "p1": 6], net: net)
    let m2p = Marking(["p0": 3, "p1": 8], net: net)
    
    let ps1 = PS(value: ([m1],[m2]), net: net)
    let ps2 = PS(value: ([m3],[m4]), net: net)
    let ps3 = PS(value: ([m1],[m5]), net: net)
    let ps1p = PS(value: ([m1p],[m2p]), net: net)
    
    XCTAssertEqual(ps1.subtract(ps1), [])
    // ({(2,3)}, {(0,8)}) - ({(0,6)}, {(3,3)}) = {({(2,3)}, {(2,6)}), ({(3,6)}, {(3,8)})}
    XCTAssertEqual(ps1.subtract(ps2), SPS(values: [ps3, ps1p]))
    XCTAssertEqual(ps1.subtract([ps2]), SPS(values: [ps3, ps1p]))
    
    let m6 = Marking(["p0": 1, "p1": 2], net: net)
    let m7 = Marking(["p0": 8, "p1": 8], net: net)
    let m8 = Marking(["p0": 1, "p1": 6], net: net)
    let ps4 = PS(value: ([m6],[]), net: net)
    let ps5 = PS(value: ([m3],[m7]), net: net)
    let ps5p = PS(value: ([m3],[]), net: net)
    let ps6 = PS(value: ([m6],[m8]), net: net)
    let ps7 = PS(value: ([m7],[]), net: net)
    
    // ({(1,2)}, {}) - ({(0,6)}, {(8,8)}) = {({(1,2)}, {(1,6)}), ({(8,8)}, {})}
    XCTAssertEqual(ps4.subtract(ps5), SPS(values: [ps6,ps7]))
    XCTAssertEqual(ps4.subtract([ps5]), SPS(values: [ps6,ps7]))
    // ({(1,2)}, {}) - ({(0,6)}, {}) = {({(1,2)}, {(1,6)})}
    XCTAssertEqual(ps4.subtract(ps5p), SPS(values: [ps6]))
    
    let m9 = Marking(["p0": 0, "p1": 4], net: net)
    let m10 = Marking(["p0": 5, "p1": 3], net: net)
    let m11 = Marking(["p0": 1, "p1": 1], net: net)
    let m12 = Marking(["p0": 5, "p1": 4], net: net)

    
    let ps8 = PS(value: ([m6],[m9]), net: net)
    let ps9 = PS(value: ([m11],[m10]), net: net)
    let ps10 = PS(value: ([m10],[m12]), net: net)
    
    
    // ({(1,2)}, {(0,4)}) - ({(1,1)}, {(5,3)}) = {({(5,3)}, {(5,4)})}
    XCTAssertEqual(ps8.subtract(ps9), [ps10])
    
    let ps11 = PS(value: ([m10],[]), net: net)
    // ({(1,2)}, {(0,4)}) - {({(1,1)}, {(5,3)}), ({(5,3)}, {})} = {}
    XCTAssertEqual(ps8.subtract([ps9,ps11]), [])
    
    let m13 = Marking(["p0": 5, "p1": 5], net: net)
    let m14 = Marking(["p0": 10, "p1": 10], net: net)
    let m15 = Marking(["p0": 3, "p1": 3], net: net)
    let m16 = Marking(["p0": 6, "p1": 6], net: net)
    let m17 = Marking(["p0": 8, "p1": 8], net: net)
    
    let ps12 = PS(value: ([m13],[m14]), net: net)
    let ps13 = PS(value: ([m15],[m16]), net: net)
    let ps14 = PS(value: ([m17],[]), net: net)
    let ps15 = PS(value: ([m16],[m17]), net: net)
    XCTAssertEqual(ps12.subtract([ps13, ps14]), [ps15])
  }
  
  func testSubtraction2() {
    
    let net = PetriNet(
      places: ["p0", "p1", "p2"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1),
      capacity: ["p0": 10, "p1": 10, "p2": 10]
    )
    
    let m1 = Marking(["p0": 2, "p1": 0, "p2": 0], net: net)
    let m2 = Marking(["p0": 0, "p1": 5, "p2": 1], net: net)
    let ps1 = PS(value: ([],[m1]), net: net)
    let ps2 = PS(value: ([],[m1,m2]), net: net)
    
    // ({}, {(2,0,0)}) - ({}, {(2,0,0), (0,5,1)}) = {}
    XCTAssertEqual(ps2.subtract(ps1), [])
    
    // {([[p0: 8, p1: 9, p2: 0]], [[p0: 8, p1: 9, p2: 1]]), ([[p0: 4, p1: 6, p2: 0]], [[p0: 4, p1: 6, p2: 1]])} - ([[p0: 4, p1: 6, p2: 0]], [[p0: 4, p1: 6, p2: 1]])
    let m3 = Marking(["p0": 8, "p1": 9, "p2": 0], net: net)
    let m4 = Marking(["p0": 8, "p1": 9, "p2": 1], net: net)
    let m5 = Marking(["p0": 4, "p1": 6, "p2": 0], net: net)
    let m6 = Marking(["p0": 4, "p1": 6, "p2": 2], net: net)
    
    let ps3 = PS(value: ([m3], [m4]), net: net)
    let ps4 = PS(value: ([m5], [m6]), net: net)
    let sps1 = SPS(values: [ps3,ps4])
    let sps2 = SPS(values: [ps4])
    
    XCTAssertTrue(sps1.isEquiv(sps2))

  }
  
  func testSubtraction3() {
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1)
    )
    let m1 = Marking(["p0": 0, "p1": 3], net: net)
    let m2 = Marking(["p0": 1, "p1": 1], net: net)
    let m3 = Marking(["p0": 0, "p1": 4], net: net)
    let m4 = Marking(["p0": 1, "p1": 2], net: net)
    let m5 =  Marking(["p0": 2, "p1": 1], net: net)
    
    let ps1 = PS(value: ([m1],[]), net: net)
    let ps2 = PS(value: ([m2],[]), net: net)
    let ps3 = PS(value: ([m3],[]), net: net)
    let ps4 = PS(value: ([m4],[]), net: net)
    let ps5 = PS(value: ([m5],[]), net: net)
    
    let sps1 = SPS(values: [ps1,ps2])
    let sps2 = SPS(values: [ps3,ps4,ps5])
    // {({(0,3)}, {}), ({(1,1)}, {})} - {({(0,4)}, {}), ({(1,2)}, {}), ({(2,1)}, {})}
    // =
    // {({(0,3)}, {}), ({(1,1)}, {})} ∩ ¬({({(0,4)}, {}), ({(1,2)}, {}), ({(2,1)}, {})})
    XCTAssertEqual(sps1.subtract(sps2), sps1.intersection(sps2.not()))
    
    let m6 = Marking(["p0": 10, "p1": 10], net: net)
    let m7 = Marking(["p0": 5, "p1": 0], net: net)
    let m8 = Marking(["p0": 0, "p1": 5], net: net)
    
    let ps6 = PS(value: ([net.zeroMarking()],[m6]), net: net)
    let ps7 = PS(value: ([net.zeroMarking()],[m7,m8]), net: net)
    let ps8 = PS(value: ([m7],[m6]), net: net)
    let ps9 = PS(value: ([m8],[m6]), net: net)
    
    let sps3 = SPS(values: [ps6])
    let sps4 = SPS(values: [ps7])
    let sps5 = SPS(values: [ps8,ps9])
    
    // ({}, {(10,10)}) - ({}, {(5,0),(0,5)})
    XCTAssertEqual(sps3.subtract(sps4), sps5)
  }
    
  func testMergePS() {
    let net = PetriNet(
      places: ["p0", "p1"],
      transitions: ["t0"],
      arcs: .pre(from: "p0", to: "t0", labeled: 1),
      .post(from: "t0", to: "p1", labeled: 1)
    )
    
    let m1 = Marking(["p0": 0, "p1": 0], net: net)
    let m2 = Marking(["p0": 4, "p1": 4], net: net)
    let m3 = Marking(["p0": 8, "p1": 8], net: net)
    let m4 = Marking(["p0": 12, "p1": 7], net: net)
    
    let ps1 = PS(value: ([m1],[m3]), net: net)
    let ps2 = PS(value: ([m2],[m4]), net: net)
    XCTAssertEqual(ps1.merge(ps2), [ps1, ps2])
  }
  
//  func testCanonicalSPS() {
//    let net = PetriNet(
//      places: ["p0", "p1", "p2"],
//      transitions: ["t0"],
//      arcs: .pre(from: "p0", to: "t0", labeled: 1),
//      .post(from: "t0", to: "p1", labeled: 1),
//      capacity: ["p0": 10, "p1": 10, "p2": 10]
//    )
//
//    let marking1 = Marking(["p0": 1, "p1": 0,  "p2": 2], net: net)
//    let marking2 = Marking(["p0": 2, "p1": 0,  "p2": 1], net: net)
//    let marking3 = Marking(["p0": 3, "p1": 0,  "p2": 2], net: net)
//    let marking4 = Marking(["p0": 2, "p1": 1,  "p2": 4], net: net)
//    let marking5 = Marking(["p0": 3, "p1": 1,  "p2": 4], net: net)
//
//    let ps1 = PS(value: ([marking1],[marking3, marking4]), net: net)
//    let ps2 = PS(value: ([marking2],[]), net: net)
//    let sps1 = SPS(values: [ps1, ps2])
//    let ps3 = PS(value: ([marking2], [marking3, marking4]), net: net)
//    let ps4 = PS(value: ([marking3], [marking5]), net: net)
//    let ps5 = PS(value: ([marking4], [marking5]), net: net)
//    let ps6 = PS(value: ([marking5], []), net: net)
//    let sps2 = SPS(values: [ps1, ps3, ps4, ps5, ps6])
//
//    print(sps1.isEquiv(sps2))
//
//    let marking6 = Marking(["p0": 2, "p1": 1,  "p2": 1], net: net)
//    let ps7 = PS(value: ([marking2],[marking6]), net: net)
//    let ps8 = PS(value: ([marking2],[marking3, marking4, marking6]), net: net)
//    let ps9 = PS(value: ([marking3],[marking6]), net: net)
//    let ps10 = PS(value: ([marking4],[marking6]), net: net)
//    let sps3 = SPS(values: [ps1, ps7])
//    let sps4 = SPS(values: [ps1, ps8, ps9, ps10])
//
//    print(sps3.isEquiv(sps4))
//
//    print(sps3.subtract(sps4))
//    print(sps4.subtract(sps3))
//    
//    let spsAll = SPS(values: [PS(value: ([net.zeroMarking()], []), net: net)])
//    
//    print(sps4.not().isEquiv(spsAll.subtract(sps4)))
//  }
  
}
