/// Set of predicate structures (SPS) are a set of PS that contains specific functions
/// Some of them are different from the usual set operations, such as intersection.
public struct SPS {
  
  /// The set of predicate structures
  public let values: Set<PS>
  
//  /// Canonicity level
//  private static var canonicityLevelStatic: CanonicityLevel = .semi
//
//  public var canonicityLevel: CanonicityLevel {
//    return SPS.canonicityLevelStatic
//  }
  
//  public init(values: Set<PS>, canonicityLevel: CanonicityLevel = .full) {
//    self.values = values
//    SPS.canonicityLevelStatic = canonicityLevel
//  }
  
  public init(values: Set<PS>) {
    self.values = values
  }
  
  
  private func ndls(ps: PS) -> SPS {
    let (a,b) = ps.value
    let qa = Marking.convMax(markings: a, net: ps.net).first!
    var res: Set<PS> = []
    var t: Bool
    
    for psp in self {
      t = true
      let (c,d) = psp.value
      let qc = Marking.convMax(markings: c, net: ps.net).first!
      let qMax = Marking.convMax(markings: [qa,qc], net: ps.net).first!
      if !Marking.comparable(m1: qa, m2: qc) {
        if !(qa.leq(qc)){
          for qb in b {
            if qb <= qMax {
              t = false
              break
            }
          }
          
          if t {
            if d == [] {
              res.insert(psp)
            }
            for qd in d {
              if qMax <= qd {
                res.insert(psp)
                break
              }
            }
          }
        }
      }
    }
    return SPS(values: res)
  }
  
  private func ndus(ps: PS) -> SPS {
    let (a,b) = ps.value
    let qa = Marking.convMax(markings: a, net: ps.net).first!
    var res: Set<PS> = []
    var t: Bool
    
    for psp in self {
      t = true
      let (c,d) = psp.value
      let qc = Marking.convMax(markings: c, net: ps.net).first!
      let qMax = Marking.convMax(markings: [qa,qc], net: ps.net).first!
      if !Marking.comparable(m1: qa, m2: qc) {
        if !(qc.leq(qa)){
          for qd in d {
            if qd <= qMax {
              t = false
              break
            }
          }
          
          if t {
            if b == [] {
              res.insert(psp)
            }
            for qb in b {
              if qMax <= qb {
                res.insert(psp)
                break
              }
            }
          }
        }
      }
    }
    return SPS(values: res)
  }
  
  /// Lowest predicate structure, containing the singleton marking with the lowest marking using the total function order leq from marking.
  private func lowPs(net: PetriNet) -> PS {
        
    if self == [] {
      return PS(value: ([net.zeroMarking()], [net.zeroMarking()]), net: net)
    }
    
    var psTemp = self.first!
    let sps = SPS(values: self.values.subtracting([psTemp]))
    
    for ps in sps {
      let qat = Marking.convMax(markings: psTemp.value.inc, net: net).first!
      let qa = Marking.convMax(markings: ps.value.inc, net: net).first!
      if !qat.leq(qa) {
        psTemp = ps
      }
    }
    
    return psTemp
  }
  
  public func add(_ ps: PS, canonicityLevel: CanonicityLevel) -> SPS {
    if self == [] {
      return SPS(values: [ps])
    }
    
    if canonicityLevel == .none {
      return SPS(values: self.values.union([ps]))
    }
    
    let spsSingleton = SPS(values: [ps])
    
    if spsSingleton.intersection(self, canonicityLevel: canonicityLevel) == [] {
      let mergeableSPS: SPS = self.mergeable(ps)
      if mergeableSPS == [] {
        if canonicityLevel == .full {
          let ndlsSps = self.ndls(ps: ps)
          let ndusSps = self.ndus(ps: ps)
          if ndlsSps == [] && ndusSps == [] {
            return SPS(values: self.values.union([ps]))
          } else if ndlsSps != [] && ndusSps == [] {
            let (a,b) = ps.value
            let psp: PS = ndlsSps.lowPs(net: ps.net)
            let (c,_) = psp.value
            let qMax: Set<Marking> = Marking.convMax(markings: a.union(c), net: ps.net)
            let reducedPS: PS = PS(value: (a, b.union(qMax)), net: ps.net).mes()
            
            let ndlsSPSReduced: SPS = SPS(values: ndlsSps.values.subtracting([psp]))
            let addTemp = ndlsSPSReduced.add(reducedPS, canonicityLevel: canonicityLevel)
            
            let newPSMerged: SPS = psp.merge(PS(value: (qMax, b), net: ps.net))
            let spsWithoutNdls: Set<PS> = self.values.subtracting(ndlsSps.values)

            return SPS(values: addTemp.values.union(newPSMerged.values).union(spsWithoutNdls))
          } else {
            let spsWithoutNdus: SPS = SPS(values: self.values.subtracting(ndusSps.values))
            var res: SPS = []
            if ndlsSps == [] && ndusSps != [] {
              res = SPS(values: spsWithoutNdus.values.union([ps]))
            } else {
              res = spsWithoutNdus.add(ps, canonicityLevel: canonicityLevel)
            }
            for psp in ndusSps {
              res = res.add(psp, canonicityLevel: canonicityLevel)
            }
          }
        }
        return SPS(values: self.values.union([ps]))
      }
      let psp = mergeableSPS.lowPs(net: ps.net)
      return SPS(values: ps.merge(psp).values.union(self.values.subtracting([psp])))
    }
    let spsMinusPs: SPS = self.subtract(spsSingleton, canonicityLevel: canonicityLevel)
    return spsMinusPs.add(ps, canonicityLevel: canonicityLevel)
  }
  
  /// Apply the union between two sets of predicate structures. Almost the same as set union, except we remove the predicate structure empty if there is one.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the union is applied
  /// - Returns: The result of the union.
  public func union(_ sps: SPS, canonicityLevel: CanonicityLevel) -> SPS {
    if self.isEmpty {
      return sps
    } else if sps.isEmpty{
      return self
    }
    
    let ps = self.values.first!
    
    if canonicityLevel == .none {
      var union = self.values.union(sps.values)
      if union.contains(PS(value: ps.emptyValue, net: ps.net)) {
        union.remove(PS(value: ps.emptyValue, net: ps.net))
      }
      return SPS(values: union)
    }
    
    let selfWithoutPS = SPS(values: self.values.subtracting([ps]))
    let addPsToSps = sps.add(ps, canonicityLevel: canonicityLevel)
//    print("OKKKKK")
//    print(addPsToSps)
    return selfWithoutPS.union(addPsToSps, canonicityLevel: canonicityLevel)
  }
//  public func union(_ sps: SPS, canonicityLevel: CanonicityLevel = .semi) -> SPS {
//    if self.isEmpty {
//      return sps
//    } else if sps.isEmpty{
//      return self
//    }
//
//    if canonicityLevel != .none {
//      let firstSelf = self.values.first!
//      let restSelf = SPS(values: self.values.subtracting([firstSelf]))
//      if self.intersection(sps, canonicityLevel: canonicityLevel).isEmpty {
//        let mergeablePS = sps.mergeable(firstSelf)
//        if mergeablePS.isEmpty {
//          let newSPS = SPS(values: sps.values.union([firstSelf]))
//          return restSelf.union(newSPS, canonicityLevel: canonicityLevel)
//        }
//        let extractPSToMerge = mergeablePS.sorted(by: {(ps1, ps2) -> Bool in
//          let markingIncPs1 = ps1.value.inc.first!
//          let markingIncPs2 = ps2.value.inc.first!
//          return markingIncPs1.leq(markingIncPs2)
//        }).first!
//
//        let mergePS: SPS = firstSelf.merge(extractPSToMerge)
//        let restSPS = SPS(values: sps.values.subtracting([extractPSToMerge]))
//
//        return restSelf.union(mergePS.union(restSPS), canonicityLevel: canonicityLevel)
//      }
//      let spsSingleton = SPS(values: [firstSelf])
//      let qa = firstSelf.value.inc.first!
//      let spsLower = SPS(values: Set(sps.filter({!(qa.leq($0.value.inc.first!))})))
//      let spsWithoutLower = SPS(values: sps.values.subtracting(spsLower.values))
//      let newSPS = SPS(values: spsWithoutLower.subtract(spsSingleton, canonicityLevel: canonicityLevel).values.union(spsLower.values))
//      return restSelf.union(spsSingleton.subtract(spsLower, canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel).union(newSPS)
//    }
//
//    let ps = self.values.first!
//    var union = self.values.union(sps.values)
//    if union.contains(PS(value: ps.emptyValue, net: ps.net)) {
//      union.remove(PS(value: ps.emptyValue, net: ps.net))
//    }
//    return SPS(values: union)
//  }
  
  /// Apply the intersection between two sets of predicate structures.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the intersection is applied
  ///   - isCanonical: An option to decide whether the application simplifies each new predicate structure into its canonical form. The intersection can create contradiction that leads to empty predicate structure or simplification. It is true by default, but it can be changed as false.
  /// - Returns: The result of the intersection.
  public func intersection(_ sps: SPS, canonicityLevel: CanonicityLevel) -> SPS {
    if self.isEmpty || sps.isEmpty {
      return []
    }
    
    var isCanonical = true
    if canonicityLevel == .none {
      isCanonical = false
    }
    
    var res: Set<PS> = []
    for ps1 in self {
      for ps2 in sps {
        let intersect = ps1.intersection(ps2, isCanonical: isCanonical)
        if canonicityLevel != .none {
          if !intersect.isEmpty() {
            res.insert(intersect)
          }
        } else {
          res.insert(intersect)
        }
      }
    }

    return SPS(values: res)
  }

  /// Subtract two sets of predicate structures
  /// - Parameter sps: The set of predicate structures to subtract
  /// - Returns: The resulting set of predicate structures
  public func subtract(_ sps: SPS, canonicityLevel: CanonicityLevel) -> SPS {
    if self == sps || self.isEmpty {
      return []
    } else if sps.isEmpty {
      return self
    }
    
    var res: Set<PS> = []
    
    for ps1 in self {
      if ps1.canonised().value != ps1.emptyValue {
        res = res.union(ps1.subtract(sps, canonicityLevel: canonicityLevel).values)
//        res = res.union(ps1.subtract(sps, isCanonical: isCanonical))
      }
    }
    return SPS(values: res)
  }

  
  /// Compute the negation of a set of predicate structures. This is the result of a combination of all elements inside a predicate structure with each element of the other predicate structures. E.g.: notSPS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Returns: The negation of a set of predicate structures
  public func not(canonicityLevel: CanonicityLevel) -> SPS {
    if self.isEmpty {
      return self
    }
    // The singleton containing the predicate structure that represents all markings subtract to the current sps
    return SPS(values: [PS(value: self.first!.allValue, net: self.first!.net)]).subtract(self, canonicityLevel: canonicityLevel)
  }
  
  // All mergeable markings with ps
  public func mergeable(_ ps: PS) -> SPS {
    var res: Set<PS> = []
    for ps1 in self {
      if ps.mergeable(ps1) {
        res.insert(ps1)
      }
    }
    return SPS(values: res)
  }
  
  /// Compute all of the underlying markings for a set of predicate structures.
  /// - Returns: All the markings encoded by a set of predicate structures
  public func underlyingMarkings() -> Set<Marking> {
    var markings: Set<Marking> = []
    for ps in self.values {
      markings = markings.union(ps.underlyingMarkings())
    }
    return markings
  }
  
  
  /// Is the current set of predicate structures is included in another one ?
  /// - Parameters:
  ///   - sps: The right set of predicate structures
  /// - Returns: True if it is included, false otherwise
  public func isIncluded(_ sps: SPS) -> Bool {
    if self == [] {
      return true
    }
    if sps == [] {
      return false
    }
    return self.subtract(sps, canonicityLevel: .semi) == []
  }
  
  /// Are two sets of predicate structures equivalent ?
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the equivalence is checked
  /// - Returns: True is they are equivalentm false otherwise
  public func isEquiv(_ sps: SPS) -> Bool {
    return self.isIncluded(sps) && sps.isIncluded(self)
  }
  
  
  /// Is a predicate structutre is included/contained in a sps ?
  /// - Parameters:
  ///   - ps: The predicate structure to check
  /// - Returns: A boolean that returns true if the predicate structure is included, false otherwise
  public func contains(ps: PS) -> Bool {
    return SPS(values: [ps]).isIncluded(self)
  }
  
  public func contains(marking: Marking) -> Bool {
    for ps in values {
      if ps.contains(marking: marking) {
        return true
      }
    }
    return false
  }
  
  
  /// Compute the revert function on all markings of each predicate structures
  /// - Returns: A new set of predicate structures after the revert application
  public func revert(canonicityLevel: CanonicityLevel) -> SPS {
    var res: SPS = []
    for ps in self {
      res = res.union(ps.revert(canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
    }
    return res
  }
  
  /// An extension of the revert function that represents AX in CTL logic.
  /// - Returns: A new set of predicate structures
  public func revertTilde(canonicityLevel: CanonicityLevel) -> SPS {
    
    if self.values.isEmpty {
      return []
    }
    
    // AX Φ ≡ ¬ EX ¬ Φ
    return self.not(canonicityLevel: canonicityLevel).revert(canonicityLevel: canonicityLevel).not(canonicityLevel: canonicityLevel)
    
//    // The trick is to take the predicate structure containing all markings, and to apply the subtraction with the current sps to get the negation.
//    let net = self.values.first!.net
//    let spsAll = SPS(values: [PS(value: ([net.zeroMarking()], []), net: net)])
//    let applyNot = spsAll.subtract(self)
//    let applyRevert = applyNot.revert()
//    return spsAll.subtract(applyRevert)
  }
  
  /// The function reduces a set of predicate structures such as there is no overlap/intersection and no direct connection between two predicates structures (e.g.: ([p0: 1, p1: 2], [p0: 5, p1: 5]) and ([p0: 5, p1: 5], [p0: 10, p1: 10]) is equivalent to ([p0: 1, p1: 2], [p0: 10, p1: 10]). However, it should be noted that there is no canonical form ! Depending on the set exploration of the SPS, some reductions can be done in a different order. Thus, the resulting sps can be different, but they are equivalent in term of marking representations. Here another example of such case:
  /// ps1 = ([(p0: 0, p1: 2, p2: 1)], [(p0: 1, p1: 2, p2: 1)])
  /// ps2 = ([(p0: 1, p1: 2, p2: 0)], [(p0: 1, p1: 2, p2: 1)])
  /// ps3 = ([(p0: 1, p1: 2, p2: 1)], [])
  /// ps1 and ps2 can be both merged with ps3, however, once this merging is done, it is not possible do it with the resting predicate structure.
  /// Thus, both choices are correct in their final results:
  /// {([(p0: 0, p1: 2, p2: 1)], [(p0: 1, p1: 2, p2: 1)]), ([(p0: 1, p1: 2, p2: 0)], [])}
  /// or
  /// {([(p0: 1, p1: 2, p2: 0)], [(p0: 1, p1: 2, p2: 1)]), ([(p0: 0, p1: 2, p2: 1)], [])}
  /// - Parameter sps: The set of predicate structures to simplify
  /// - Returns: The simplified version of the sps.
  public func simplified() -> SPS {
    if self.isEmpty {
      return self
    }
    
    var mergedSet: Set<PS> = []
    var setTemp1: Set<PS> = []
    var setTemp2: Set<PS> = []
    var spsTemp: SPS = []
    var psFirst: PS
    var psFirstTemp: PS
    var b: Bool
    
    for ps in self {
      let can = ps.canonised()
      if can.value != can.emptyValue {
        setTemp1.insert(can)
      }
    }
    
    if setTemp1 == [] {
      return []
    }
    
    while !setTemp1.isEmpty {
      b = true
      let firstPS = setTemp1.first!
      setTemp1.remove(firstPS)
      for ps in setTemp1 {
        if ps.isIncluded(firstPS) {
          setTemp1.remove(ps)
        } else if firstPS.isIncluded(ps) {
          b = false
          break
        }
      }
      if b {
        setTemp2.insert(firstPS)
      }
    }
            
    while !setTemp2.isEmpty {
      psFirst = setTemp2.first!
      psFirstTemp = psFirst
      setTemp2.remove(psFirst)
      for ps in setTemp2 {
        spsTemp = psFirst.merge(ps)
        if spsTemp.count == 1 {
          psFirstTemp = spsTemp.first!
          setTemp2.remove(ps)
          setTemp2.insert(psFirstTemp)
          break
        }
      }
      if psFirst == psFirstTemp {
        mergedSet.insert(psFirstTemp)
      }
    }

    var reducedSPS: Set<PS> = mergedSet

    while !mergedSet.isEmpty {
      let firstPS = mergedSet.first!
      mergedSet.remove(firstPS)
      if SPS(values: [firstPS]).isIncluded(SPS(values: mergedSet)) {
        reducedSPS.remove(firstPS)
      }
    }
    
    return SPS(values: reducedSPS)
    
  }
  
  /// Create a set of predicate structures to represent all markings such as no transition are fireable.
  /// - Parameter net: The Petri net
  /// - Returns: The corresponding set of predicate structures
  public static func deadlock(net: PetriNet, canonicityLevel: CanonicityLevel = .semi) -> SPS {
    var markings: Set<Marking> = []
    for transition in net.transitions {
      markings.insert(net.inputMarkingForATransition(transition: transition))
    }
    let ps = PS(value: ([net.zeroMarking()], markings), net: net).canonised()
    if ps.value != ps.emptyValue {
      return SPS(values: [PS(value: ([net.zeroMarking()], markings), net: net).canonised()])
    }
    return []
  }
    
}

/// Allow the comparison between SPS.
extension SPS: Hashable {
  public static func == (lhs: SPS, rhs: SPS) -> Bool {
    return lhs.values == rhs.values
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(values)
  }
}

/// Allow to use for .. in .. .
extension SPS: Sequence {
  public func makeIterator() -> Set<PS>.Iterator {
      return values.makeIterator()
  }
}

/// Allow to get the first element of a collection.
extension SPS: Collection {
  public var startIndex: Set<PS>.Index {
    return values.startIndex
  }
  
  public var endIndex: Set<PS>.Index {
    return values.endIndex
  }
  
  public subscript(position: Set<PS>.Index) -> PS {
    return values[position]
  }
  
  public func index(after i: Set<PS>.Index) -> Set<PS>.Index {
    return values.index(after: i)
  }
  
  public var isEmpty: Bool {
    return values.isEmpty
  }
  
  public var count: Int {
    return values.count
  }

}

/// Allow to express a set of PS as an array which is converted into a set.
extension SPS: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = PS
  public init(arrayLiteral elements: PS...) {
    self.values = Set(elements)
  }
}

extension SPS: CustomStringConvertible {
  public var description: String {
    if values.isEmpty {
      return "{}"
    }
    var res: String = "{\n"
    for ps in values {
      res.append(" \(ps),\n")
    }
    res.removeLast(2)
    res.append("\n}")
    return res
  }
  
}

//// --------------------------------------------------------------------------------------
//// Alternative version of the intersection for SPS in a functional way
//// --------------------------------------------------------------------------------------
//  public func intersection(_ sps: SPS, isCanonical: Bool = true) -> SPS {
//    if self.isEmpty || sps.isEmpty {
//      return []
//    }
//
//    if self.values.count == 1 {
//      let firstValue = sps.values.first!
//      let restSPS = SPS(values: sps.values.subtracting([firstValue]))
//      let intersect = self.first!.intersection(firstValue, isCanonical: isCanonical)
//      if isCanonical {
//        if intersect.isEmpty() {
//          return self.intersection(restSPS, isCanonical: isCanonical)
//        }
//      }
//      return SPS(values: [intersect]).union(self.intersection(restSPS, isCanonical: isCanonical))
//    }
//
//    let firstValue = self.values.first!
//    let restSPS = SPS(values: self.values.subtracting([firstValue]))
//
//    return SPS(values: [firstValue]).intersection(sps, isCanonical: isCanonical).union(restSPS.intersection(sps, isCanonical: isCanonical))
//  }
