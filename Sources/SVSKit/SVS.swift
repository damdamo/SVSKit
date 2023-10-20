/// Symbolic vector sets (SVS) are a set of SV that contains specific functions
/// Some of them are different from the usual set operations, such as intersection.
public struct SVS {
  
  /// The symbolic vector set
  public let values: Set<SV>
  
  public init(values: Set<SV>) {
    self.values = values
  }
  
  /// Return all the symbolic vector in a symbolic vector set that shared a part that could be moved from sv to the other symbolic vectors of self
  /// - Parameter sv: The compared symbolic vector
  /// - Returns: All symbolic vectors where sharingPart exists
  func sharingSvs(sv: SV) -> SVS {
    var res: Set<SV> = []
    for svp in self {
      if sv.shareable(sv: svp) {
        res.insert(svp)
      }
    }
    return SVS(values: res)
  }
  
  /// Find the first symbolic vector in self that shares a part with sv. This is to avoid computing every shareable sv in svs
  /// - Parameter sv: The related symbolic vector
  /// - Returns: The first symbolic vector that shares a common part with sv. If not, returns nil.
  func firstSharingSV(sv: SV) -> (SV, SV)? {
    for svp in self {
      let shared = sv.sharingPart(sv: svp)
      if !shared.isEmpty() {
        return (svp, shared)
      }
    }
    return nil
  }
  
  /// Add a symbolic vector into a symbolic vector set, ensuring canonicity if required.
  /// - Parameters:
  ///   - sv: The symbolic vector to add
  ///   - canonicityLevel: The form of canonicity required
  /// - Returns: The new symbolic vector set containing the new symbolic vector
  func add(_ sv: SV, canonicityLevel: CanonicityLevel) -> SVS {

    if self.isEmpty {
      if sv.isEmpty() {
        return SVS(values: [sv.zeroSV])
      }
       return SVS(values: [sv])
    } else if sv.isEmpty() {
       return self
    }

    if canonicityLevel == .none {
      return SVS(values: self.values.union([sv]))
    }

    var sharedSVS = self.sharingSvs(sv: sv).values
    
    if !sharedSVS.isEmpty {
      let svsWithoutSharedSVS = SVS(values: self.values.subtracting(sharedSVS))
      let svp = sharedSVS.removeFirst()
      let shared = sv.sharingPart(sv: svp)
      var res: SVS = []
      
      if sv.value.inc.leq(svp.value.inc) {
        let merged = sv.merge(shared, mergeablePreviouslyComputed: true)
        if merged.count > 1 {
          fatalError("Should not be possible")
        }
        res = svp.subtract(shared, canonicityLevel: .full).add(merged.first!, canonicityLevel: .none).union(SVS(values: sharedSVS), canonicityLevel: .full)
      } else {
        let merged = svp.merge(shared, mergeablePreviouslyComputed: true)
        if merged.count > 1 {
          fatalError("Should not be possible")
        }
        res = sv.subtract(shared, canonicityLevel: .full).add(merged.first!, canonicityLevel: .none).union(SVS(values: sharedSVS), canonicityLevel: .full)
      }
      return res.union(svsWithoutSharedSVS, canonicityLevel: .full)
    }
    // If some of the symbolic vectors are not canonical, the result could contain non canonical symbolic vectors. In this case, it would be required to add mes()
    // return SVS(values: self.values.union([sv.mes()]))
    return SVS(values: self.values.union([sv]))
  }
  
  
  /// Apply the union between two symbolic vector sets. Almost the same as set union, except we remove the symbolic vector empty if there is one.
  /// - Parameters:
  ///   - svs: The symbolic vector set on which the union is applied
  ///   - canonicityLevel: The level of the canonicity
  /// - Returns: The result of the union.
  public func union(_ svs: SVS, canonicityLevel: CanonicityLevel) -> SVS {
    if self.isEmpty {
      return svs
    } else if svs.isEmpty{
      return self
    }
    
    let sv = self.values.first!
    
    if canonicityLevel == .none {
      var union = self.values.union(svs.values)
      if union.contains(SV(value: sv.emptyValue, net: sv.net)) {
        union.remove(SV(value: sv.emptyValue, net: sv.net))
      }
      return SVS(values: union)
    }
    let selfWithoutSV = SVS(values: self.values.subtracting([sv]))
    let addSvToSvs = svs.add(sv, canonicityLevel: canonicityLevel)
    return selfWithoutSV.union(addSvToSvs, canonicityLevel: canonicityLevel)
  }
  
  /// Apply the intersection between two symbolic vector sets.
  /// - Parameters:
  ///   - svs: The symbolic vector set on which the intersection is applied
  ///   - canonicityLevel: The level of the canonicity.
  /// - Returns: The result of the intersection.
  public func intersection(_ svs: SVS, canonicityLevel: CanonicityLevel) -> SVS {
    if self.isEmpty || svs.isEmpty {
      return []
    }
    
    if canonicityLevel == .none {
      var res: Set<SV> = []
      for sv1 in self {
        for sv2 in svs {
          let intersect = sv1.intersection(sv2, isCanonical: true)
          if !intersect.isEmpty() {
            res.insert(intersect)
          }
        }
      }
  
      return SVS(values: res)
    }
    
    var res: SVS = []
    for sv1 in self {
      for sv2 in svs {
        let intersect = sv1.intersection(sv2, isCanonical: true)
        if !intersect.isEmpty() {
          res = res.add(intersect, canonicityLevel: .none)
        }
      }
    }

    return res
  }
  
  /// An efficient function to compute whether intersection of two symbolic vector sets is empty.
  func emptyIntersection(_ svs: SVS) -> Bool {
    for sv in self {
      for svp in svs {
        if !sv.intersection(svp, isCanonical: false).isEmpty() {
          return false
        }
      }
    }
    return true
  }

  /// Subtract two symbolic vector sets
  /// - Parameters:
  ///   - svs: The symbolic vector set to subtract
  ///   - canonicityLevel: The level of the canonicity
  /// - Returns: The resulting symbolic vector set
  public func subtract(_ svs: SVS, canonicityLevel: CanonicityLevel) -> SVS {
    if self == svs || self.isEmpty {
      return []
    } else if svs.isEmpty {
      return self
    }

    if canonicityLevel == .none {
      var res: Set<SV> = []
      for sv in self {
        if !sv.isEmpty() {
          res = res.union(sv.subtract(svs, canonicityLevel: canonicityLevel).values)
        }
      }
      return SVS(values: res)
    }

    var res: SVS = []
    for sv in self {
      if !sv.isEmpty() {
        res = res.union(sv.subtract(svs, canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
      }
    }
    return res

  }
  /// Compute the negation of a symbolic vector set. This is the result of a combination of all elements inside a symbolic vector with each element of the other symbolic vectors. E.g.: notSVS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Parameters:
  ///   - net: The current Petri net
  ///   - canonicityLevel: The level of the canonicity
  /// - Returns: The negation of a symbolic vector set
  public func not(net: PetriNet, canonicityLevel: CanonicityLevel) -> SVS {
    if self.isEmpty {
      return SVS(values: [SV(value: ([net.zeroMarking()], []), net: net)])
    }
    // The singleton containing the symbolic vector that represents all markings subtract to the current svs
    return SVS(values: [SV(value: ([net.zeroMarking()], []), net: net)]).subtract(self, canonicityLevel: canonicityLevel)
  }
  
  // All mergeable markings with sv
  public func mergeable(_ sv: SV) -> SVS {
    var res: Set<SV> = []
    for sv1 in self {
      if sv.mergeable(sv1) {
        res.insert(sv1)
      }
    }
    return SVS(values: res)
  }
  
  public func nbOfMarkings() -> Double {
    if self.isEmpty {
      return 0
    }
    let net = self.first!.net
    let markingCapacity = Marking(net.capacity, net: net)
    var res: Double = 0
    for sv in self.values {
      res += sv.nbOfMarkings()
    }
    
    return self.contains(marking: markingCapacity) ? res + 1 : res
  }
  
  /// Compute all of the underlying markings for a symbolic vector set.
  /// - Returns: All the markings encoded by a symbolic vector set
  public func underlyingMarkings() -> Set<Marking> {
    var markings: Set<Marking> = []
    for sv in self.values {
      markings = markings.union(sv.underlyingMarkings())
    }
    return markings
  }
  
  
  /// Is the current symbolic vector set is included in another one ?
  /// - Parameters:
  ///   - svs: The right symbolic vector set
  /// - Returns: True if it is included, false otherwise
  public func isIncluded(_ svs: SVS) -> Bool {
    if self.isEmpty {
      return true
    }
    if svs.isEmpty {
      return false
    }
    
    for sv in self {
      if !sv.subtract(svs, canonicityLevel: .none).isEmpty {
        return false
      }
    }
    return true
  }
  
  /// Are two symbolic vector sets equivalent ?
  /// - Parameters:
  ///   - svs: The symbolic vector set on which the equivalence is checked
  /// - Returns: True is they are equivalentm false otherwise
  public func isEquiv(_ svs: SVS) -> Bool {
    return self.isIncluded(svs) && svs.isIncluded(self)
  }
  
  
  /// Does the set of predicate structutres include a symbolic vector ?
  /// - Parameters:
  ///   - sv: The symbolic vector to check
  /// - Returns: True if the symbolic vector belongs to the symbolic vector set, false otherwise
  public func contains(sv: SV) -> Bool {
    return SVS(values: [sv]).isIncluded(self)
  }
  
  
  /// Does the symbolic vector contain a marking ?
  /// - Parameter marking: The marking to check
  /// - Returns: True if the marking belongs to the symbolic vector, false otherwise
  public func contains(marking: Marking) -> Bool {
    for sv in values {
      if sv.contains(marking: marking) {
        return true
      }
    }
    return false
  }
  
  
  /// Compute the revert function on all markings of each symbolic vectors
  /// - Parameter canonicityLevel: The level of the canonicity
  /// - Returns: A new symbolic vector set after the revert application
  public func revert(canonicityLevel: CanonicityLevel, capacity: [String: Int]) -> SVS {
    
//    if let res = Memoization.memoizationRevertTable[self] {
//      return res
//    }
    
    if canonicityLevel == .none {
      var res: Set<SV> = []
      for sv in self {
        res = res.union(sv.revert(canonicityLevel: canonicityLevel, capacity: capacity).values)
      }
      return SVS(values: res)
    }

    var res: SVS = []
    for sv in self {
      res = res.union(sv.revert(canonicityLevel: canonicityLevel, capacity: capacity), canonicityLevel: canonicityLevel)
    }
    
//    Memoization.memoizationRevertTable[self] = res
    
    return res
  }
  
  /// An extension of the revert function that represents AX in CTL logic.
  /// - Parameters:
  ///   - net: The current Petri net
  ///   - canonicityLevel: The level of canonicity
  /// - Returns: A new symbolic vector set
  public func revertTilde(net: PetriNet, canonicityLevel: CanonicityLevel, capacity: [String: Int]) -> SVS {
    
//    if let res = Memoization.memoizationRevertTildeTable[self] {
//      return res
//    }
    
    if self.values.isEmpty {
      return []
    }
    
    // AX Φ ≡ ¬ EX ¬ Φ
    let step1 = self.not(net: net, canonicityLevel: canonicityLevel)
    let step2 = step1.revert(canonicityLevel: canonicityLevel, capacity: capacity)
    let step3 = step2.not(net: net, canonicityLevel: canonicityLevel)
    
//    Memoization.memoizationRevertTildeTable[self] = step3
    
    return step3
  }
  
  /// The function reduces a symbolic vector set such as there is no overlap/intersection and no direct connection between two predicates structures (e.g.: ([p0: 1, p1: 2], [p0: 5, p1: 5]) and ([p0: 5, p1: 5], [p0: 10, p1: 10]) is equivalent to ([p0: 1, p1: 2], [p0: 10, p1: 10]). However, it should be noted that there is no canonical form ! Depending on the set exploration of the SVS, some reductions can be done in a different order. Thus, the resulting svs can be different, but they are equivalent in term of marking representations. Here another example of such case:
  /// sv1 = ([(p0: 0, p1: 2, p2: 1)], [(p0: 1, p1: 2, p2: 1)])
  /// sv2 = ([(p0: 1, p1: 2, p2: 0)], [(p0: 1, p1: 2, p2: 1)])
  /// sv3 = ([(p0: 1, p1: 2, p2: 1)], [])
  /// sv1 and sv2 can be both merged with sv3, however, once this merging is done, it is not possible do it with the resting symbolic vector.
  /// Thus, both choices are correct in their final results:
  /// {([(p0: 0, p1: 2, p2: 1)], [(p0: 1, p1: 2, p2: 1)]), ([(p0: 1, p1: 2, p2: 0)], [])}
  /// or
  /// {([(p0: 1, p1: 2, p2: 0)], [(p0: 1, p1: 2, p2: 1)]), ([(p0: 0, p1: 2, p2: 1)], [])}
  /// - Parameter svs: The symbolic vector set to simplify
  /// - Returns: The simplified version of the svs.
  public func simplified() -> SVS {
    if self.isEmpty {
      return self
    }

    var svsCanonised: Set<SV> = []
    var svsReduced: Set<SV> = []
    var svsMerged: Set<SV> = []
    var svFirst: SV
    var svFirstTemp: SV

    for sv in self {
      let can = sv.canonised()
      if !can.isEmpty() {
        svsCanonised.insert(can)
      }
    }

    if svsCanonised.isEmpty {
      return []
    }
        
    while !svsCanonised.isEmpty {
      svFirst = svsCanonised.removeFirst()
      svFirstTemp = svFirst
      for sv in svsCanonised {
        if svFirst.mergeable(sv) {
          svFirstTemp = svFirst.merge(sv, mergeablePreviouslyComputed: true).first!
          svsCanonised.remove(sv)
          svsCanonised.insert(svFirstTemp)
          break
        }
      }
      if svFirst == svFirstTemp {
        svsMerged.insert(svFirstTemp)
      }
    }
    
    while !svsMerged.isEmpty {
      let firstSV = svsMerged.removeFirst()
      if !SVS(values: [firstSV]).isIncluded(SVS(values: svsMerged)) {
        svsReduced.insert(firstSV)
      }
    }
    
    return SVS(values: svsReduced)
  }
  

  /// Create a symbolic vector set to represent all markings such as no transition are fireable.
  /// - Parameter net: The Petri net
  /// - Returns: The corresponding symbolic vector set
  public static func deadlock(net: PetriNet, canonicityLevel: CanonicityLevel = .semi) -> SVS {
    var markings: Set<Marking> = []
    for transition in net.transitions {
      markings.insert(net.inputMarkingForATransition(transition: transition))
    }
    let sv = SV(value: ([net.zeroMarking()], markings), net: net).canonised()
    if sv.value != sv.emptyValue {
      return SVS(values: [SV(value: ([net.zeroMarking()], markings), net: net).canonised()])
    }
    return []
  }
  
  public func canonised() -> SVS {
    var res: SVS = []
    for el in self {
      res = res.union(SVS(values: [el]), canonicityLevel: .full)
    }
    return res
  }
    
}

/// Allow the comparison between SVS.
extension SVS: Hashable {
  public static func == (lhs: SVS, rhs: SVS) -> Bool {
    return lhs.values == rhs.values
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(values)
  }
}

/// Allow to use for .. in .. .
extension SVS: Sequence {
  public func makeIterator() -> Set<SV>.Iterator {
      return values.makeIterator()
  }
}

/// Allow to get the first element of a collection.
extension SVS: Collection {
  public var startIndex: Set<SV>.Index {
    return values.startIndex
  }
  
  public var endIndex: Set<SV>.Index {
    return values.endIndex
  }
  
  public subscript(position: Set<SV>.Index) -> SV {
    return values[position]
  }
  
  public func index(after i: Set<SV>.Index) -> Set<SV>.Index {
    return values.index(after: i)
  }
  
  public var isEmpty: Bool {
    return values.isEmpty
  }
  
  public var count: Int {
    return values.count
  }

}

/// Allow to express symbolic vector set as an array which is converted into a set.
extension SVS: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = SV
  public init(arrayLiteral elements: SV...) {
    self.values = Set(elements)
  }
}

extension SVS: CustomStringConvertible {
  public var description: String {
    if values.isEmpty {
      return "{}"
    }
    var res: String = "{\n"
    for sv in values.sorted(by: {$0.value.inc.leq($1.value.inc)}) {
      res.append(" \(sv),\n")
    }
    res.removeLast(2)
    res.append("\n}")
    return res
  }
  
}
