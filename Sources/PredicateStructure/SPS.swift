/// Set of predicate structures (SPS) are a set of PS that contains specific functions
/// Some of them are different from the usual set operations, such as intersection.
public struct SPS {
  
  /// The set of predicate structures
  public let values: Set<PS>
  
  /// The related Petri net
//  private static var netStatic: PetriNet? = nil
//
//  public var net: PetriNet {
//    return SPS.netStatic!
//  }
  
  public init(values: Set<PS>) {
    self.values = values
  }
  
  
  private func ndls(ps: PS) -> SPS {
    let (qa,b) = ps.value
    var res: Set<PS> = []
    
    for psp in self {
      let (qc, _) = psp.value
      let qMax = Marking.convMax(markings: [qa,qc], net: ps.net)
      if !Marking.comparable(m1: qa, m2: qc) {
        if !(qa.leq(qc)){
          if psp.mergeable(PS(value: (qMax, b), net: psp.net)) {
            res.insert(psp)
          }
        }
      }
    }
    return SPS(values: res)
  }
  
  private func ndus(ps: PS) -> SPS {
    let (qa,b) = ps.value
    var res: Set<PS> = []
    
    for psp in self {
      let (qc, _) = psp.value
      let qMax = Marking.convMax(markings: [qa,qc], net: ps.net)
      if !Marking.comparable(m1: qa, m2: qc) {
        if !(qc.leq(qa)){
          if psp.mergeable(PS(value: (qMax, b), net: psp.net)) {
            res.insert(psp)
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
      let qat = psTemp.value.inc
      let qa =  ps.value.inc
      if !qat.leq(qa) {
        psTemp = ps
      }
    }
    
    return psTemp
  }
  
  public func add(_ ps: PS, canonicityLevel: CanonicityLevel) -> SPS {
    
    if self.isEmpty {
      return SPS(values: [ps])
    } else if ps.isEmpty() {
      return self
    }
    
    let spsSingleton = SPS(values: [ps])

    if spsSingleton.isIncluded(self) {
      return self
    }
    
    if canonicityLevel == .none {
      return SPS(values: self.values.union([ps]))
    }
        
    if spsSingleton.emptyIntersection(self) {
      let mergeableSPS: SPS = self.mergeable(ps)
      if mergeableSPS.isEmpty {
        if canonicityLevel == .full {
          let ndlsSps = self.ndls(ps: ps)
          let ndusSps = self.ndus(ps: ps)
          if ndlsSps.isEmpty && ndusSps.isEmpty {
            return SPS(values: self.values.union([ps]))
          } else if !ndlsSps.isEmpty && ndusSps.isEmpty {
            let (qa,b) = ps.value
            let psp: PS = ndlsSps.lowPs(net: ps.net)
            let (qc,_) = psp.value
            let qMax: Marking = Marking.convMax(markings: [qa, qc], net: ps.net)
            let reducedPS: PS = PS(value: ([qa], b.union([qMax])), net: ps.net).mes()
            
            let ndlsSPSReduced: SPS = SPS(values: ndlsSps.values.subtracting([psp]))
            let addTemp = ndlsSPSReduced.add(reducedPS, canonicityLevel: canonicityLevel)
            
            // Can optimise by calling merge with already computed !
            let newPSMerged: SPS = psp.merge(PS(value: (qMax, b), net: ps.net))
            
            let spsWithoutNdls: Set<PS> = self.values.subtracting(ndlsSps.values)

            return SPS(values: addTemp.values.union(newPSMerged.values).union(spsWithoutNdls))
          } else {
//            let spsWithoutNdus: SPS = SPS(values: self.values.subtracting(ndusSps.values))
//            var res: SPS = []
//            if ndlsSps.isEmpty && !ndusSps.isEmpty {
//              res = SPS(values: spsWithoutNdus.values.union([ps]))
//            } else {
//              res = spsWithoutNdus.add(ps, canonicityLevel: canonicityLevel)
//            }
//            for psp in ndusSps {
//              res = res.add(psp, canonicityLevel: canonicityLevel)
//            }
//            return res
            let spsWithoutNdus: SPS = SPS(values: self.values.subtracting(ndusSps.values))
            var res: SPS = []
            if ndlsSps.isEmpty && !ndusSps.isEmpty {
              res = [ps]
              for psp in ndusSps {
                res = res.add(psp, canonicityLevel: canonicityLevel)
              }
              res = SPS(values: spsWithoutNdus.values.union(res.values))
            } else {
              res = ndlsSps.add(ps, canonicityLevel: canonicityLevel)
              for psp in ndusSps {
                res = res.add(psp, canonicityLevel: canonicityLevel)
              }
              res = SPS(values: res.values.union(self.values.subtracting(ndlsSps.values.union(ndusSps.values))))
            }
//            for psp in ndusSps {
//              res = res.add(psp, canonicityLevel: canonicityLevel)
//            }
            return res
          }
        }
        return SPS(values: self.values.union([ps]))
      }
      let psp = mergeableSPS.lowPs(net: ps.net)
      let mergedPart = ps.merge(psp, mergeablePreviouslyComputed: true).first!
      return SPS(values: self.values.subtracting([psp])).add(mergedPart, canonicityLevel: canonicityLevel)
    }
    let nonEmptySet = SPS(values: Set(self.filter({!$0.intersection(ps, isCanonical: false).isEmpty()})))
    let lowerPs = nonEmptySet.lowPs(net: ps.net)
    let merge = ps.merge(lowerPs)
    var res: SPS = self.subtract([lowerPs], canonicityLevel: canonicityLevel)
    for psp in merge.sorted(by: {$1.value.inc <= $0.value.inc}) {
      res = res.add(psp, canonicityLevel: canonicityLevel)
    }
    return res
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
    return selfWithoutPS.union(addPsToSps, canonicityLevel: canonicityLevel)
  }
  
  /// Apply the intersection between two sets of predicate structures.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the intersection is applied
  ///   - isCanonical: An option to decide whether the application simplifies each new predicate structure into its canonical form. The intersection can create contradiction that leads to empty predicate structure or simplification. It is true by default, but it can be changed as false.
  /// - Returns: The result of the intersection.
  public func intersection(_ sps: SPS) -> SPS {
    if self.isEmpty || sps.isEmpty {
      return []
    }
    
    var res: Set<PS> = []
    for ps1 in self {
      for ps2 in sps {
        let intersect = ps1.intersection(ps2, isCanonical: true)
        if !intersect.isEmpty() {
          res.insert(intersect)
        }
      }
    }

    return SPS(values: res)
  }
  
  private func emptyIntersection(_ sps: SPS) -> Bool {
    for ps in self {
      for psp in sps {
        if !ps.intersection(psp, isCanonical: false).isEmpty() {
          return false
        }
      }
    }
    return true
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

//    if canonicityLevel == .none {
      var res: Set<PS> = []
      for ps in self {
        if !ps.isEmpty() {
          res = res.union(ps.subtract(sps, canonicityLevel: canonicityLevel).values)
        }
      }
      return SPS(values: res)
//    }
    
//    var res: SPS = []
//    for ps in self {
//      if !ps.isEmpty() {
//        res = res.union(ps.subtract(sps, canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
//      }
//    }
//    return res

  }
  /// Compute the negation of a set of predicate structures. This is the result of a combination of all elements inside a predicate structure with each element of the other predicate structures. E.g.: notSPS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Returns: The negation of a set of predicate structures
  public func not(net: PetriNet, canonicityLevel: CanonicityLevel) -> SPS {
    if self.isEmpty {
      return SPS(values: [PS(value: ([net.zeroMarking()], []), net: net)])
    }
    // The singleton containing the predicate structure that represents all markings subtract to the current sps
    return SPS(values: [PS(value: ([net.zeroMarking()], []), net: net)]).subtract(self, canonicityLevel: canonicityLevel)
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
    if self.isEmpty {
      return true
    }
    if sps.isEmpty {
      return false
    }
    
    for ps in self {
      if !ps.subtract(sps, canonicityLevel: .none).isEmpty {
        return false
      }
    }
    return true
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
  public func revertTilde(net: PetriNet, canonicityLevel: CanonicityLevel) -> SPS {
    
    if self.values.isEmpty {
      return []
    }
    
    // AX Φ ≡ ¬ EX ¬ Φ
    let step1 = self.not(net: net, canonicityLevel: canonicityLevel)
    let step2 = step1.revert(canonicityLevel: canonicityLevel)
    let step3 = step2.not(net: net, canonicityLevel: canonicityLevel)
//    print("count step 1: \(step1.count)")
//    print("count step 2: \(step2.count)")
//    print("count step 3: \(step3.count)")
    return step3
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
//  public func simplified() -> SPS {
//    if self.isEmpty {
//      return self
//    }
//
//    var spsCanonised: Set<PS> = []
//    var spsReduced: Set<PS> = []
//    var spsMerged: Set<PS> = []
//    var spsTemp: SPS = []
//    var psFirst: PS
//    var psFirstTemp: PS
//
//    for ps in self {
//      let can = ps.canonised()
//      if !can.isEmpty() {
//        spsCanonised.insert(can)
//      }
//    }
//
//    if spsCanonised.isEmpty {
//      return []
//    }
//
//    while !spsCanonised.isEmpty {
//      let firstPS = spsCanonised.removeFirst()
//      if !SPS(values: [firstPS]).isIncluded(SPS(values: spsCanonised)) {
//        spsReduced.insert(firstPS)
//      }
//    }
//
//    while !spsReduced.isEmpty {
//      psFirst = spsReduced.removeFirst()
//      psFirstTemp = psFirst
//      for ps in spsReduced {
//        if psFirst.mergeable(ps) {
//          spsTemp = psFirst.merge(ps, mergeablePreviouslyComputed: true)
//          psFirstTemp = spsTemp.first!
//          spsReduced.remove(ps)
//          spsReduced.insert(psFirstTemp)
//          break
//        }
//      }
//      if psFirst == psFirstTemp {
//        spsMerged.insert(psFirstTemp)
//      }
//    }
//    return SPS(values: spsMerged)
//  }
  public func simplified() -> SPS {
    if self.isEmpty {
      return self
    }

    var spsCanonised: Set<PS> = []
    var spsReduced: Set<PS> = []
    var spsMerged: Set<PS> = []
//    var spsTemp: SPS = []
    var psFirst: PS
    var psFirstTemp: PS

    for ps in self {
      let can = ps.canonised()
      if !can.isEmpty() {
        spsCanonised.insert(can)
      }
    }

    if spsCanonised.isEmpty {
      return []
    }
    
//    print("Number of ps in spsCanonised: \(spsCanonised.count)")
    
    while !spsCanonised.isEmpty {
      psFirst = spsCanonised.removeFirst()
      psFirstTemp = psFirst
      for ps in spsCanonised {
        if psFirst.mergeable(ps) {
          psFirstTemp = psFirst.merge(ps, mergeablePreviouslyComputed: true).first!
          spsCanonised.remove(ps)
          spsCanonised.insert(psFirstTemp)
          break
        }
      }
      if psFirst == psFirstTemp {
        spsMerged.insert(psFirstTemp)
      }
    }
    
//    print("Number of ps in spsMerged: \(spsMerged.count)")

    while !spsMerged.isEmpty {
      let firstPS = spsMerged.removeFirst()
      if !SPS(values: [firstPS]).isIncluded(SPS(values: spsMerged)) {
        spsReduced.insert(firstPS)
      }
    }

//    print("Number of ps in spsReduced: \(spsReduced.count)")
    
    return SPS(values: spsReduced)
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
    for ps in values.sorted(by: {$0.value.inc.leq($1.value.inc)}) {
      res.append(" \(ps),\n")
    }
    res.removeLast(2)
    res.append("\n}")
    return res
  }
  
}
