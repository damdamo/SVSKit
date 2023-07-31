/// A Predicate structure (PS) is a symbolic structure to represent set of markings.
/// In a formal way, PS is a couple (a,b) ∈ PS, such as a,b ∈ Set<Marking>
/// A marking that is accepted by such a predicate structure must be included in all markings of "a" and not included in all markings of "b".
/// e.g.: ({(0,2)}, {(4,5)}).
/// (0,4), (2, 42), (42, 4) are valid markings, because (0,2) is included but not (4,5)
/// On the other hand, (0,1), (4,5), (4,42), (42,42) are not valid.
/// This representation allows to model a potential infinite set of markings in a finite way.
/// However, for the sake of finite representations and to compute them, we use the Petri net capacity on places to bound them.
public struct PS {

  public typealias PlaceType = String
  public typealias TransitionType = String
  
  /// The couple that represents the predicate structure
  public let value: (inc: Marking, exc: Set<Marking>)
  /// The related Petri net
  private static var netStatic: PetriNet? = nil
  
  public var net: PetriNet {
    return PS.netStatic!
  }
    
  public var emptyValue: (inc: Marking, exc: Set<Marking>) {
    return (net.zeroMarking(), [net.zeroMarking()])
  }
  
  private init(value: (inc: Marking, exc: Set<Marking>)) {
    self.value = value
  }
  
  public init(value: (inc: Marking, exc: Set<Marking>), net: PetriNet) {
    PS.netStatic = net
    self.value = value
  }
  
  public init(value: (inc: Set<Marking>, exc: Set<Marking>), net: PetriNet) {
    PS.netStatic = net

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
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  public func not() -> SPS {
    if self.isEmpty() {
      return [PS(value: (net.zeroMarking(), []))]
    }
    
    var sps: Set<PS> = []
    sps.insert(PS(value: (net.zeroMarking(), [self.value.inc])))
    for el in value.exc {
      sps.insert(PS(value: (el, [])))
    }
    return SPS(values: sps)
  }
  
  // nes: Normalise excluding set
  public func nes() -> PS {
    var excludingSet: Set<Marking> = []
    var markingTemp: Marking
    let qa = self.value.inc
    
    for qb in self.value.exc {
      markingTemp = Marking.convMax(markings: [qa, qb], net: net)
      excludingSet.insert(markingTemp)
    }
    
    return PS(value: (self.value.inc, excludingSet))
  }
  
  // mes: minimum excluding set
  public func mes() -> PS {
    if self.value == emptyValue {
      return self
    }

    let (qa, b) = self.nes().value
    
    let newExcludingMarkings = b.filter({(qb) -> Bool in
      !b.contains(where: {($0 != qb && $0 <= qb)})
    })

    // The result is the subtraction between the original markings and thus that are already included
    return PS(value: (qa, newExcludingMarkings))
  }
  
  /// Returns the canonical form of a predicate structure. Let suppose (a,b) in PS
  /// By canonical form, we mean reducing a in a singleton, removing all possible inclusions in b, and no marking in b included in a.
  /// In addition, when a value of a place in a marking "a" is greater than one of "b", the value of "b" marking is changed to the value of "a".
  /// - Returns: The canonical form of the predicate structure.
  public func canonised() -> PS {
    if self.isEmpty() {
      // In (a,b) ∈ PS, if a marking in b is included in a, it returns the empty predicate structure
      return PS(value: emptyValue)
    }
    
    return PS(value: (self.value.inc, self.value.exc)).mes()
  }
  
  /// Compute all the markings represented by the symbolic representation of a predicate structure.
  /// - Returns: The set of all possible markings, also known as the state space.
  public func underlyingMarkings() -> Set<Marking> {
    let canonizedPS = self.canonised()
    var placeSetValues: [PlaceType: Set<Int>] = [:]
    var res: Set<[PlaceType: Int]> = []
    var resTemp = res
    var lowerBound: Int
    var upperBound: Int
    var am: Marking
    
    if canonizedPS.value == emptyValue {
      return []
    }
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    let can = canonizedPS.value
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
    
    for mb in canonizedPS.value.exc {
      for marking in markingSet {
        if mb <= marking {
          markingSet.remove(marking)
        }
      }
    }
    
    return markingSet
  }
  
  
  /// Encode a marking into a predicate structure. This predicate structure encodes a singe marking.
  /// - Parameter marking: The marking to encode
  /// - Returns: The predicate structure that represents the marking
  public func encodeMarking(_ marking: Marking) -> PS {
    var bMarkings: Set<Marking> = []
    var markingTemp = marking
    for place in net.places {
      markingTemp[place]! += 1
      bMarkings.insert(markingTemp)
      markingTemp = marking
    }
    
    return PS(value: (marking, bMarkings))
  }
  
  /// Encode a set of markings into a set of predicate structures.
  /// - Parameter markingSet: The marking set to encode
  /// - Returns: A set of predicate structures that encodes the set of markings
  public func encodeMarkingSet(_ markingSet: Set<Marking>) -> SPS {
    var sps: Set<PS> = []
    for marking in markingSet {
      sps.insert(encodeMarking(marking))
    }
    return SPS(values: sps).simplified()
  }
  
  /// Try to merge two predicate structures if there are comparable.
  /// The principle is similar to intervals, where the goal is to reunified intervals if they can be merged.
  /// Otherwise, nothing is changed.
  /// - Parameters:
  ///   - ps: The second predicate structure
  /// - Returns: The result of the merged. If this is not possible, returns the original predicate structures.
  public func merge(_ ps: PS, mergeablePreviouslyComputed: Bool = false) -> SPS {
    
    if !mergeablePreviouslyComputed {
      if !self.mergeable(ps) {
        let intersect = self.intersection(ps, isCanonical: true)
        if !intersect.isEmpty() {
          if self.value.inc.leq(ps.value.inc) {
//            return ps.subtract(self, canonicityLevel: .full).add(self, canonicityLevel: .full)
            return SPS(values: ps.subtract(self, canonicityLevel: .full).values.union([self]))
          }
//          return self.subtract(ps, canonicityLevel: .full).add(ps, canonicityLevel: .full)
          return SPS(values: self.subtract(ps, canonicityLevel: .full).values.union([ps]))
        }
        return [self, ps]
      }
    }

    var (qa, b) = self.value
    var (qc, d) = ps.value
    
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
    
    let newPS = PS(value: (qa, convMaxMarkingSet)).mes()
    return SPS(values: [newPS])
  }
  
  public func mergeable(_ ps: PS) -> Bool {
        
    // Be careful: We can avoid to use nes() because functions returns always canonical predicate structures
    var (qa, b) = self.value
    var (qc, d) = ps.value
    
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
  
  public func sharingPart(ps: PS) -> PS {
    var (qa,b) = self.value
    var (qc,d) = ps.value
    
    if !qa.leq(qc) {
      let qaTemp = qa
      let bTemp = b
      qa = qc
      b = d
      qc = qaTemp
      d = bTemp
    }
    
    let qMax = Marking.convMax(markings: [qa,qc], net: ps.net)
    var markingToAdd: Set<Marking> = []
    
    for qb in b {
      if !(qc <= qb) {
        let convMax = Marking.convMax(markings: [qb,qc], net: ps.net)
        if !d.contains(where: {$0 <= convMax}) {
          markingToAdd.insert(qb)
        }
      }
    }
    
    return PS(value: (qMax, d.union(markingToAdd))).canonised()
  }
  
  /// Compute the inverse of the fire operation for a given transition. It takes into account the current predicate structure where it consumes tokens for post arcs and produces new ones for pre arcs.
  /// - Parameter transition: The given transition
  /// - Returns: A new predicate structure where the revert operation has been applied.
  public func revert(transition: String) -> PS? {
    
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
      return PS(value: (qaTemp, bTemp))
    }
    return nil
  }
  
  /// General revert operation where all transitions are applied
  /// - Returns: A set of predicate structures resulting from the union of the revert operation on each transition on the current predicate structure.
  public func revert(canonicityLevel: CanonicityLevel) -> SPS {
    var res: SPS = []
    for transition in net.transitions {
      if let rev = self.revert(transition: transition)?.canonised() {
        if !rev.isEmpty() {
          res = res.add(rev, canonicityLevel: canonicityLevel)
        }
      }
    }
    return res
  }
  
  /// Apply the intersection between two predicate structures
  /// - Parameters:
  ///   - ps: The second predicate structure to intersect
  ///   - isCanonical: A boolean to specifiy if each predicate structure is canonised during the process.
  /// - Returns: The result of the intersection
  public func intersection(_ ps: PS, isCanonical: Bool) -> PS {
    
    if self.isEmpty() {
      return self
    } else if ps.isEmpty() {
      return ps
    }
    
    let convMax = Marking.convMax(markings: [self.value.inc, ps.value.inc], net: net)
    
    if isCanonical {
      return PS(value: (convMax, self.value.exc.union(ps.value.exc))).canonised()
    }
    
    return PS(value: (convMax, self.value.exc.union(ps.value.exc)))
  }
  
  /// To know if a marking belongs to a predicate structure
  /// - Parameter marking: The marking to check if it belongs to the ps
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
  
  
  /// Subtract two PS, by removing all markings for the right PS into the left PS
  /// - Parameter ps: The ps to subtract
  /// - Returns: A sps containing no value of ps
  public func subtract(_ ps: PS, canonicityLevel: CanonicityLevel) -> SPS {
    if self == ps || self.isEmpty() {
      return []
    } else if ps.isEmpty() {
      return SPS(values: [self])
    }

    if self.intersection(ps, isCanonical: false).isEmpty() {
      return SPS(values: [self])
    }

    let qa = self.value.inc
    let b = self.value.exc

    // Important to normalise the right predicate structure
    // We want to move some constraints of the right marking into the left marking.
    // If we do not normalise it, it means that we could remove values that we should not.
    // For more information, look at the thesis document (operation nes).
    let nesPS = ps.nes()
    let qc = nesPS.value.inc
    let d = nesPS.value.exc

    if canonicityLevel == .none {
      var res: Set<PS> = []
      let newPS = PS(value: (qa, b.union([qc]))).mes()
      if !newPS.isEmpty() {
        res.insert(newPS)
      }
      for marking in d {
        let newQa = Marking.convMax(markings: [qa, marking], net: net)
        let newPS = PS(value: (newQa,b)).nes()
        if !newPS.isEmpty() {
          res.insert(newPS)
        }
      }
      return SPS(values: res)
    }
    
    var res: SPS = []

    let newPS = PS(value: (qa, b.union([qc]))).mes()
    if !newPS.isEmpty() {
      res = res.add(newPS, canonicityLevel: canonicityLevel)
    }
    
    var markingSetConstrained: Set<Marking> = b
    for marking in d.sorted(by: {$0.leq($1)}) {
      let newQa = Marking.convMax(markings: [qa, marking], net: net)
      let newPS = PS(value: (newQa, markingSetConstrained)).mes()
      if !newPS.isEmpty() {
        markingSetConstrained.insert(marking)
        res = res.add(newPS, canonicityLevel: canonicityLevel)
      }
    }
    return res

  }

  /// Subtract a ps with a set of predicate structures, by recursively applying the subtraction on the new elements.
  /// - Parameter sps: The set of predicate structures to subtract
  /// - Returns: A set of predicate structures where all elements of sps have been removed from ps
  public func subtract(_ sps: SPS, canonicityLevel: CanonicityLevel) -> SPS {
    
    if canonicityLevel == .none {
      var res: Set<PS> = [self]
      var spsTemp: Set<PS>
      for ps in sps {
        spsTemp = []
        for psTemp in res {
          spsTemp = spsTemp.union(psTemp.subtract(ps, canonicityLevel: canonicityLevel).values)
        }
        res = spsTemp
      }
      return SPS(values: res)
    }
    
    var res: SPS = [self]
    var spsTemp: SPS
    for ps in sps {
      spsTemp = []
      for psTemp in res {
        spsTemp = spsTemp.union(psTemp.subtract(ps, canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
      }
      res = spsTemp
    }
    return res
  }
  
  /// Is a predicate structure included in another one ?
  /// - Parameter ps: The predicate structure to check if self is contained
  /// - Returns: True if it is contained, false otherwise.
  public func isIncluded(_ ps: PS) -> Bool {
    return self.subtract(ps, canonicityLevel: .none) == []
  }
  
  /// Count the number of markings that composes the predicate structure.
  /// - Returns: Marking number of a predicate structure
  public func countMarking() -> Int {
    if self.value == emptyValue {
      return 0
    }
    return 1 + value.exc.count
  }

}

extension PS: Hashable {
  public static func == (lhs: PS, rhs: PS) -> Bool {
    return lhs.value.inc == rhs.value.inc && lhs.value.exc == rhs.value.exc
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value.inc)
    hasher.combine(value.exc)
  }
}

extension PS: CustomStringConvertible {
  public var description: String {
    if value == emptyValue {
      return "∅"
    }
    return "(\(value.inc), \(value.exc.sorted(by: {$0.leq($1)})))"
  }
}
