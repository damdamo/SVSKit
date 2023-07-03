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
  public let value: (inc: Set<Marking>, exc: Set<Marking>)
  /// The related Petri net
  private static var netStatic: PetriNet? = nil
  
  public var net: PetriNet {
    return PS.netStatic!
  }
    
  public var emptyValue: (inc: Set<Marking>, exc: Set<Marking>) {
    return ([net.zeroMarking()],[net.zeroMarking()])
  }
  
  private init(value: (inc: Set<Marking>, exc: Set<Marking>)) {
    if value.inc.isEmpty {
      let couple = (Set([PS.netStatic!.zeroMarking()]), value.exc)
      self.value = couple
    } else {
      self.value = value
    }
  }
  
  public init(value: (inc: Set<Marking>, exc: Set<Marking>), net: PetriNet) {
    PS.netStatic = net
    // If `inc` is an empty set, we replace it by the zero marking, containing 0 for all places
    // It corresponds to the marking accepting all markings.
    if value.inc.isEmpty {
      let couple = (Set([net.zeroMarking()]), value.exc)
      self.value = couple
    } else {
      self.value = value
    }
    
  }
  
  public func isEmpty() -> Bool {
    for qb in value.exc {
      if qb == net.zeroMarking() {
        return true
      }
      for qa in value.inc {
        if qb <= qa {
          return true
        }
      }
    }
    return false
  }
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  public func not() -> SPS {
    if self.isEmpty() {
      return [PS(value: ([net.zeroMarking()], []))]
    }
    
    var sps: Set<PS> = []
    for el in value.inc {
      // .ps([], [el])
      sps.insert(PS(value: ([net.zeroMarking()], [el])))
    }
    for el in value.exc {
      sps.insert(PS(value: ([el], [])))
    }
    return SPS(values: sps)
  }
  
  // nes: Normalise excluding set
  public func nes() -> PS {
    var excludingSet: Set<Marking> = []
    var markingTemp: Marking
    
    for qb in self.value.exc {
      markingTemp = qb
      for qa in self.value.inc {
        markingTemp = Marking.convMax(markings: [qa, markingTemp], net: net).first!
      }
      excludingSet.insert(markingTemp)
    }
    
    return PS(value: (self.value.inc, excludingSet))
  }
  
  // mes: minimum excluding set
  public func mes() -> PS {
    if self.value == emptyValue {
      return self
    }
    
    let ps = self.nes()
    // Extract markings that are included in other ones
    var invalidMarkings: Set<Marking> = []
    for marking1 in ps.value.exc {
      for marking2 in ps.value.exc {
        if marking1 != marking2 {
          if marking2 <= marking1 {
            invalidMarkings.insert(marking1)
            break
          }
        }
      }
    }
    
    let newExcludingMarkings = ps.value.exc.subtracting(invalidMarkings)
    // The result is the subtraction between the original markings and thus that are already included
    return PS(value: (ps.value.inc, newExcludingMarkings))
  }
  
  /// Returns the canonical form of a predicate structure. Let suppose (a,b) in PS
  /// By canonical form, we mean reducing a in a singleton, removing all possible inclusions in b, and no marking in b included in a.
  /// In addition, when a value of a place in a marking "a" is greater than one of "b", the value of "b" marking is changed to the value of "a".
  /// - Returns: The canonical form of the predicate structure.
  public func canonised() -> PS {
    let convInclude = Marking.convMax(markings: value.inc, net: net)
    let mesPS = PS(value: (convInclude, self.value.exc)).mes()
    if mesPS.isEmpty() {
      // In (a,b) ∈ PS, if a marking in b is included in a, it returns the empty predicate structure
      return PS(value: emptyValue)
    }
    return mesPS
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
    if let _ = can.inc.first {
      am = can.inc.first!
    } else {
      am = net.zeroMarking()
    }
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
    
    return PS(value: ([marking], bMarkings))
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
  public func merge(_ ps: PS) -> SPS {

    if self.isIncluded(ps) {
      return [ps]
    } else if ps.isIncluded(self) {
      return [self]
    }

    let nesPS1 = self.nes()
    let nesPS2 = ps.nes()

    let a = nesPS1.value.inc
    let b = nesPS1.value.exc
    let c = nesPS2.value.inc
    let d = nesPS2.value.exc
    let qa = Marking.convMax(markings: a, net: net).first!
    let qc = Marking.convMax(markings: c, net: net).first!

    if b.contains(qc) {
      let newPS = PS(value: (a, b.subtracting([qc]).union(d))).mes()
      if ps.isIncluded(newPS) {
        return [newPS]
      }
    } else if d.contains(qa) {
      let newPS = PS(value: (c, d.subtracting([qa]).union(b))).mes()
      if self.isIncluded(newPS) {
        return [newPS]
      }
    }

    return [self, ps]
  }
  
  public func mergeable(_ ps: PS) -> Bool {
    if self.merge(ps) == SPS(values: [self, ps]) {
        return false
    }
    return true
  }
  
  /// Compute the inverse of the fire operation for a given transition. It takes into account the current predicate structure where it consumes tokens for post arcs and produces new ones for pre arcs.
  /// - Parameter transition: The given transition
  /// - Returns: A new predicate structure where the revert operation has been applied.
  public func revert(transition: String) -> PS? {
    
    if self.value == emptyValue {
      return self
    }
    
    var aTemp: Set<Marking> = []
    var bTemp: Set<Marking> = []
    
    if value.inc == [] {
      aTemp = [net.inputMarkingForATransition(transition: transition)]
    } else {
      for marking in value.inc {
        if let rev = net.revert(marking: marking, transition: transition) {
          aTemp.insert(rev)
        } else {
          return nil
        }
      }
    }
    if value.exc == [] {
      bTemp = []
    } else {
      for marking in value.exc {
        if let rev = net.revert(marking: marking, transition: transition) {
          bTemp.insert(rev)
        }
      }
    }
    return PS(value: (aTemp, bTemp))
  }
  
  /// General revert operation where all transitions are applied
  /// - Returns: A set of predicate structures resulting from the union of the revert operation on each transition on the current predicate structure.
  public func revert(canonicityLevel: CanonicityLevel) -> SPS {
    var res: SPS = []
    for transition in net.transitions {
      if let rev = self.revert(transition: transition)?.canonised() {
        res = res.add(rev, canonicityLevel: canonicityLevel)
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
    
    if self.value == emptyValue {
      return self
    } else if ps.value == emptyValue {
      return ps
    }
    
    let convMax = Marking.convMax(markings: self.value.inc.union(ps.value.inc), net: net)
    
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
    
    for m in value.inc {
      if !(marking >= m) {
        return false
      }
    }
    for m in value.exc {
      if marking >= m {
        return false
      }
    }
    return true
  }
  
  
  /// Subtract two PS, by removing all markings for the right PS into the left PS
  /// - Parameter ps: The ps to subtract
  /// - Returns: A sps containing no value of ps
  public func subtract(_ ps: PS) -> SPS {
    if self == ps || self.isEmpty() {
      return []
    } else if ps.isEmpty() {
      return SPS(values: [self])
    }

    if self.intersection(ps, isCanonical: false).isEmpty() {
      return SPS(values: [self])
    }

    let a = self.value.inc
    let b = self.value.exc

    // Important to normalise the right predicate structure
    // We want to move some constraints of the right marking into the left marking.
    // If we do not normalise it, it means that we could remove values that we should not.
    // For more information, look at the thesis document (operation nes).
    let nesPS = ps.nes()
    let c = nesPS.value.inc
    let d = nesPS.value.exc

    var res: Set<PS> = []

    var ps1 = PS(value: (a, c.union(b))).canonised()

    res = res.union(SPS(values: [ps1]))

    for marking in d {
      var newA = a
      newA.insert(marking)
      ps1 = PS(value: (newA,b)).canonised()
      res.insert(ps1)
    }

    for ps in res {
      if ps.isEmpty() {
        res.remove(ps)
      }
    }

    return SPS(values: res)
  }
  
  /// Subtract a ps with a set of predicate structures, by recursively applying the subtraction on the new elements.
  /// - Parameter sps: The set of predicate structures to subtract
  /// - Returns: A set of predicate structures where all elements of sps have been removed from ps
  public func subtract(_ sps: SPS) -> SPS {
    var res: Set<PS> = [self]
    var spsTemp: Set<PS>
    for ps in sps {
      spsTemp = []
      for psTemp in res {
        spsTemp = spsTemp.union(psTemp.subtract(ps).values)
      }
      res = spsTemp
    }
    return SPS(values: res)
  }
  
  /// Is a predicate structure included in another one ?
  /// - Parameter ps: The predicate structure to check if self is contained
  /// - Returns: True if it is contained, false otherwise.
  public func isIncluded(_ ps: PS) -> Bool {
    return self.subtract(ps) == []
  }
  
  /// Count the number of markings that composes the predicate structure.
  /// - Returns: Marking number of a predicate structure
  public func countMarking() -> Int {
    if self.value == emptyValue {
      return 0
    }
    return value.inc.count + value.exc.count
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
    return "(\(value.inc), \(value.exc))"
  }
}
