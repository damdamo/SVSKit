/// A Symbolic vector (SV) is a symbolic structure to represent set of markings.
/// In a formal way, SV is a couple (a,b) ∈ SV, such that a,b ∈ Set<Marking>
/// A marking that is accepted by such a symbolic vector must be included in all markings of "a" and not included in all markings of "b".
/// e.g.: ({(0,2)}, {(4,5)}).
/// (0,4), (2, 42), (42, 4) are valid markings, because (0,2) is included but not (4,5)
/// On the other hand, (0,1), (4,5), (4,42), (42,42) are not valid.
/// This representation allows to model a potential infinite set of markings in a finite way.
/// However, for the sake of finite representations and to compute them, we use the Petri net capacity on places to bound them.
public struct SV {

  public typealias PlaceType = String
  public typealias TransitionType = String
  
  /// The couple that represents the symbolic vector
  public let value: (inc: Marking, exc: Set<Marking>)
  /// The related Petri net
  private static var netStatic: PetriNet? = nil
  
  public var net: PetriNet {
    return SV.netStatic!
  }
  
  public var zeroSV: SV {
    return SV(value: emptyValue)
  }
    
  public var emptyValue: (inc: Marking, exc: Set<Marking>) {
    return (net.zeroMarking(), [net.zeroMarking()])
  }
  
  private init(value: (inc: Marking, exc: Set<Marking>)) {
    self.value = value
  }
  
  public init(value: (inc: Marking, exc: Set<Marking>), net: PetriNet) {
    SV.netStatic = net
    self.value = value
  }
  
  public init(value: (inc: Set<Marking>, exc: Set<Marking>), net: PetriNet) {
    SV.netStatic = net

    // If `inc` is an empty set, we replace it by the zero marking, containing 0 for all places
    // It corresponds to the marking accepting all markings.
    if value.inc.isEmpty {
      let couple = (net.zeroMarking(), value.exc)
      self.value = couple
    } else {
      self.value = (Marking.convMax(markings: value.inc, net: net), value.exc)
    }
  }
  
  public func isEmpty() -> Bool {
    for qb in value.exc {
      if qb <= self.value.inc {
        return true
      }
      
    }
    return false
  }
  
  /// Compute the negation of a symbolic vector, which is a symbolic vector set
  /// - Returns: Returns the negation of the symbolic vector
  public func not() -> SVS {
    if self.isEmpty() {
      return [SV(value: (net.zeroMarking(), []))]
    }
    
    var svs: Set<SV> = []
    svs.insert(SV(value: (net.zeroMarking(), [self.value.inc])))
    for el in value.exc {
      svs.insert(SV(value: (el, [])))
    }
    return SVS(values: svs)
  }
  
  // nes: Normalise excluding set
  public func nes() -> SV {
    var excludingSet: Set<Marking> = []
    var markingTemp: Marking
    let qa = self.value.inc
    
    for qb in self.value.exc {
      markingTemp = Marking.convMax(markings: [qa, qb], net: net)
      excludingSet.insert(markingTemp)
    }
    return SV(value: (self.value.inc, excludingSet))
  }
  
  // mes: minimum excluding set
  public func mes() -> SV {
    if self.value == emptyValue {
      return self
    }
    let (qa, b) = self.nes().value
    let newExcludingMarkings = b.filter({(qb) -> Bool in
      !b.contains(where: {($0 != qb && $0 <= qb)})
    })

    // The result is the subtraction between the original markings and thus that are already included
    return SV(value: (qa, newExcludingMarkings))
  }
  
  /// Returns the canonical form of a symbolic vector. Let suppose (a,b) in SV
  /// By canonical form, we mean reducing a in a singleton, removing all possible inclusions in b, and no marking in b included in a.
  /// In addition, when a value of a place in a marking "a" is greater than one of "b", the value of "b" marking is changed to the value of "a".
  /// - Returns: The canonical form of the symbolic vector.
  public func canonised() -> SV {
    if self.isEmpty() {
      // In (a,b) ∈ SV, if a marking in b is included in a, it returns the empty symbolic vector
      return SV(value: emptyValue)
    }
    
    return SV(value: (self.value.inc, self.value.exc)).mes()
  }
  
  /// Compute all the markings represented by the symbolic representation of a symbolic vector.
  /// - Returns: The set of all possible markings, also known as the state space.
  public func underlyingMarkings() -> Set<Marking> {
    let canonizedSV = self.canonised()
    var placeSetValues: [PlaceType: Set<Int>] = [:]
    var res: Set<[PlaceType: Int]> = []
    var resTemp = res
    var lowerBound: Int
    var upperBound: Int
    var am: Marking
    
    if canonizedSV.value == emptyValue {
      return []
    }
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    let can = canonizedSV.value
    am = can.inc
    for place in net.places {
      lowerBound = am[place]!
      upperBound = net.capacity[place]!
      for i in lowerBound ..< upperBound+1 {
        if let _ = placeSetValues[place] {
          placeSetValues[place]!.insert(i)
        } else {
          placeSetValues[place] = [i]
        }
      }
    }
    
    // Using the previous constructed dictionnary, it applies a combinatory to connect each value of each place with the other ones.
    while !placeSetValues.isEmpty {
      if let (place, values) = placeSetValues.first {
        resTemp = []
        if res.isEmpty {
          for value in values {
            res.insert([place: value])
          }
        } else {
          for value in values {
            for el in res {
              resTemp.insert(el.merging([place: value], uniquingKeysWith: {(old: Int, new: Int) -> Int in
                return new
              }))
            }
            res = resTemp
          }
        }
        placeSetValues.removeValue(forKey: place)
      }
    }
    
    // Convert all dictionnaries into markings
    var markingSet: Set<Marking> = Set(res.map({(el: [PlaceType: Int]) -> Marking in
      Marking(el, net: net)
    }))
    
    for mb in canonizedSV.value.exc {
      for marking in markingSet {
        if mb <= marking {
          markingSet.remove(marking)
        }
      }
    }
    
    return markingSet
  }
  
  
  /// Encode a marking into a symbolic vector. This symbolic vector encodes a singe marking.
  /// - Parameter marking: The marking to encode
  /// - Returns: The symbolic vector that represents the marking
  public func encodeMarking(_ marking: Marking) -> SV {
    var bMarkings: Set<Marking> = []
    var markingTemp = marking
    for place in net.places {
      markingTemp[place]! += 1
      bMarkings.insert(markingTemp)
      markingTemp = marking
    }
    return SV(value: (marking, bMarkings))
  }
  
  /// Encode a set of markings into a symbolic vector set.
  /// - Parameter markingSet: The marking set to encode
  /// - Returns: A symbolic vector set that encodes the set of markings
  public func encodeMarkingSet(_ markingSet: Set<Marking>) -> SVS {
    var svs: Set<SV> = []
    for marking in markingSet {
      svs.insert(encodeMarking(marking))
    }
    return SVS(values: svs).simplified()
  }
  
  /// Try to merge two symbolic vectors if they are mergeable.
  /// The principle is similar to intervals, where the goal is to reunified intervals if they can be merged.
  /// Otherwise, nothing is changed.
  /// - Parameters:
  ///   - sv: The second symbolic vector
  /// - Returns: The result of the merged. If this is not possible, returns the original symbolic vectors.
  public func merge(_ sv: SV, mergeablePreviouslyComputed: Bool = false) -> SVS {
    if !mergeablePreviouslyComputed {
      if !self.mergeable(sv) {
        return [self, sv]
      }
    }

    var (qa, b) = self.value
    var (qc, d) = sv.value
    
    if qc <= qa {
      let temp = (qa, b)
      (qa, b) = (qc, d)
      (qc, d) = temp
    }
    
    var comparableMarkings: Set<Marking> = []
    var incomparableMarkings: Set<Marking> = []
    var convMaxMarkingSet: Set<Marking> = []
    
    for qb in b {
      if qc <= qb {
        comparableMarkings.insert(qb)
      } else {
        incomparableMarkings.insert(qb)
        convMaxMarkingSet.insert(qb)
      }
    }
    
    for marking in incomparableMarkings {
      let convMax = Marking.convMax(markings: [marking, qc], net: net)
      d.remove(convMax)
    }
    
    for qb in comparableMarkings {
      for qd in d {
        convMaxMarkingSet.insert(Marking.convMax(markings: [qb,qd], net: net))
      }
    }
    
    let newSV = SV(value: (qa, convMaxMarkingSet)).mes()
    return SVS(values: [newSV])
  }
  
  
  /// Determine whether two symbolic vectors are mergable
  /// - Parameter sv: The second symbolic vector
  /// - Returns: True if they are, false otherwise
  public func mergeable(_ sv: SV) -> Bool {
        
    // Be careful: We can avoid to use nes() because functions returns always canonical symbolic vectors
    var (qa, b) = self.value
    var (qc, d) = sv.value
    
    if qc <= qa {
      let temp = (qa, b)
      (qa, b) = (qc, d)
      (qc, d) = temp
    }

    if qa <= qc {
      for qb in b {
        if !(qc <= qb) {
          let convMax = Marking.convMax(markings: [qb,qc], net: net)
          if !d.contains(where: {$0 <= convMax}) {
            return false
          }
        }
      }
      return true
    }
    
    return false
  }
  
  
  /// Compute the potential part that could be moved from one symbolic vector to the other.
  /// This common part is mergeable on both symbolic vectors. This operation is different from the intersection ! In this context, intersection could be empty but the sharing part not.
  /// - Parameter sv: The second symbolic vector
  /// - Returns: The common part that could be merged on both symbolic vectors
  public func sharingPart(sv: SV) -> SV {
    var (qa,b) = self.value
    var (qc,d) = sv.value
    
    if !qa.leq(qc) {
      let temp = (qa, b)
      (qa, b) = (qc, d)
      (qc, d) = temp
    }
    
    let qMax = Marking.convMax(markings: [qa,qc], net: sv.net)
    var markingToAdd: Set<Marking> = []
    
    for qb in b {
      if !(qc <= qb) {
          // Small optimisation to finish as soon as possible if the result is the empty sv
          if qb <= qMax {
            return zeroSV
          }
          markingToAdd.insert(qb)
      }
    }
    
    return SV(value: (qMax, d.union(markingToAdd))).canonised()
  }
  
  func shareable(sv: SV) -> Bool {
    var (qa,b) = self.value
    var (qc,d) = sv.value
    
    if !qa.leq(qc) {
      let temp = (qa, b)
      (qa, b) = (qc, d)
      (qc, d) = temp
    }
    
    let qMax = Marking.convMax(markings: [qa,qc], net: sv.net)
    
    for qb in b {
        if qb <= qMax && qb != qMax {
          return false
        }
    }
    
    for qd in d {
        if qd <= qMax {
          return false
        }
    }
    
    return true
  }
  
  /// Compute the inverse of the fire operation for a given transition. It takes into account the current symbolic vector where it consumes tokens for post arcs and produces new ones for pre arcs.
  /// - Parameter transition: The given transition
  /// - Returns: A new symbolic vector where the revert operation has been applied.
  public func revert(transition: String) -> SV? {
    if self.value == emptyValue {
      return self
    }
    
    if let qaTemp = net.revert(marking: value.inc, transition: transition) {
      var bTemp: Set<Marking> = []
      
      if value.exc == [] {
        bTemp = []
      } else {
        for marking in value.exc {
          if let rev = net.revert(marking: marking, transition: transition) {
            bTemp.insert(rev)
          }
        }
      }
      return SV(value: (qaTemp, bTemp))
    }
    return nil
  }
  
  /// General revert operation where all transitions are applied
  /// - Returns: A symbolic vector set resulting from the union of the revert operation on each transition on the current symbolic vector.
  public func revert(canonicityLevel: CanonicityLevel) -> SVS {
    
//    if let res = Memoization.memoizationRevertTable[self] {
//      return res
//    }
    
    var res: SVS = []
    for transition in net.transitions {
      if let rev = self.revert(transition: transition)?.canonised() {
        if !rev.isEmpty() {
          res = res.add(rev, canonicityLevel: canonicityLevel)
        }
      }
    }
    
//    Memoization.memoizationRevertTable[self] = res
    
    return res
  }
  
  /// Apply the intersection between two symbolic vectors
  /// - Parameters:
  ///   - sv: The second symbolic vector to intersect
  ///   - isCanonical: A boolean to specifiy if each symbolic vector is canonised during the process.
  /// - Returns: The result of the intersection
  public func intersection(_ sv: SV, isCanonical: Bool) -> SV {
    
    if self.isEmpty() {
      return self
    } else if sv.isEmpty() {
      return sv
    }
    
    let convMax = Marking.convMax(markings: [self.value.inc, sv.value.inc], net: net)
    
    if isCanonical {
      return SV(value: (convMax, self.value.exc.union(sv.value.exc))).canonised()
    }
    
    return SV(value: (convMax, self.value.exc.union(sv.value.exc)))
  }
  
  /// To know if a marking belongs to a symbolic vector
  /// - Parameter marking: The marking to check if it belongs to the sv
  /// - Returns: True if the marking belongs, false otherwise
  public func contains(marking: Marking) -> Bool {
    if self.value == emptyValue {
      return false
    }
    
    let qa = self.value.inc
    if !(marking >= qa) {
      return false
    }
    
    for qb in value.exc {
      if marking >= qb {
        return false
      }
    }
    return true
  }
  
  
  /// Subtract two SV, by removing all markings for the right SV into the left SV
  /// - Parameters:
  ///   - sv: The sv to subtract
  ///   - canonicityLevel: The level of canonicity
  /// - Returns: A svs containing no value of sv
  public func subtract(_ sv: SV, canonicityLevel: CanonicityLevel) -> SVS {
    if self == sv || self.isEmpty() {
      return []
    } else if sv.isEmpty() {
      return SVS(values: [self])
    }

    if self.intersection(sv, isCanonical: false).isEmpty() {
      return SVS(values: [self])
    }

    let qa = self.value.inc
    let b = self.value.exc

    // Important to normalise the right symbolic vector
    // We want to move some constraints of the right marking into the left marking.
    // If we do not normalise it, it means that we could remove values that we should not.
    // For more information, look at the thesis document (operation nes).
    var nesSV = sv
    if canonicityLevel == .none {
      nesSV = nesSV.nes()
    }
    let qc = nesSV.value.inc
    let d = nesSV.value.exc
    var res: Set<SV> = []
    let newSV = SV(value: (qa, b.union([qc])))
    if !newSV.isEmpty() {
      res.insert(newSV.mes())
    }

    var markingSetConstrained: Set<Marking> = b
    for qd in d.sorted(by: {$0.leq($1)}) {
      let newQa = Marking.convMax(markings: [qa, qd], net: net)
      let newSV = SV(value: (newQa, markingSetConstrained))
      if !newSV.isEmpty() {
        markingSetConstrained.insert(qd)
        res.insert(newSV.mes())
      }
    }
    return SVS(values: res)
  }
  
  /// Subtract a sv with a symbolic vector set, by recursively applying the subtraction on the new elements.
  /// - Parameters:
  ///   - svs: The symbolic vector set to subtract
  ///   - canonicityLevel: The level of canonicity
  /// - Returns: A symbolic vector set where all elements of svs have been removed from sv
  public func subtract(_ svs: SVS, canonicityLevel: CanonicityLevel) -> SVS {
    if canonicityLevel == .none {
      var res: Set<SV> = [self]
      var svsTemp: Set<SV>
      for sv in svs {
        svsTemp = []
        for svTemp in res {
          svsTemp = svsTemp.union(svTemp.subtract(sv, canonicityLevel: canonicityLevel).values)
        }
        res = svsTemp
      }
      return SVS(values: res)
    }
    var svsValues = svs.values
    let svp = svsValues.removeFirst()
    return self.subtract(svp, canonicityLevel: canonicityLevel).subtract(SVS(values: svsValues), canonicityLevel: canonicityLevel)
  }
  
  /// Is a symbolic vector included in another one ?
  /// - Parameter sv: The symbolic vector to check if self is contained
  /// - Returns: True if it is contained, false otherwise.
  public func isIncluded(_ sv: SV) -> Bool {
    return self.subtract(sv, canonicityLevel: .none) == []
  }
  
  /// Count the number of markings that composes the symbolic vector.
  /// - Returns: Marking number of a symbolic vector
  public func countMarking() -> Int {
    if self.value == emptyValue {
      return 0
    }
    return 1 + value.exc.count
  }

}

extension SV: Hashable {
  public static func == (lhs: SV, rhs: SV) -> Bool {
    return lhs.value.inc == rhs.value.inc && lhs.value.exc == rhs.value.exc
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value.inc)
    hasher.combine(value.exc)
  }
}

extension SV: CustomStringConvertible {
  public var description: String {
    if value == emptyValue {
      return "∅"
    }
    return "(\(value.inc), \(value.exc.sorted(by: {$0.leq($1)})))"
  }
}
