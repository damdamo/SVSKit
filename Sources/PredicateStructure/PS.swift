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
  public let value: (inc: Set<Marking>, exc: Set<Marking>)?
  /// The related Petri net
  public let net: PetriNet
  
  public init(value: (inc: Set<Marking>, exc: Set<Marking>)?, net: PetriNet) {
    self.value = value
    self.net = net
  }
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  public func not() -> SPS {
    if let p = value {
      var sps: Set<PS> = []
      for el in p.inc {
        // .ps([], [el])
        sps.insert(PS(value: ([], [el]) , net: net))
      }
      for el in p.exc {
        sps.insert(PS(value: ([el], []) , net: net))
      }
      return SPS(values: sps)
    }
    
    var dicMarking: [PlaceType: Int] = [:]
    for place in net.places {
      dicMarking[place] = 0
    }
    return [PS(value: ([Marking(dicMarking, net: net)], []), net: net)]
  }
  
  /// convMax, for convergence maximal, is a function to compute a singleton containing a marking where each value is the maximum of all places for a given place.
  /// This is the convergent point such as all marking of markings are included in this convergent marking.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the maximum between all markings.
  public static func convMax(markings: Set<Marking>, net: PetriNet) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    var dicMarking: [PlaceType: Int] = [:]
    for marking in markings {
      for place in net.places {
        if let m = dicMarking[place] {
          if m < marking[place]! {
            dicMarking[place] = marking[place]
          }
        } else {
          dicMarking[place] = marking[place]
        }
      }
    }
    return [Marking(dicMarking, net: net)]
  }
  
  /// convMin, for convergence minimal, is a function to compute a singleton containing a marking where each value is the minimum of all places for a given place.
  /// This is the convergent point such as the convergent marking is included in all the other markings.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the minimum between all markings.
  public static func convMin(markings: Set<Marking>, net: PetriNet) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    var dicMarking: [PlaceType: Int] = [:]
    for marking in markings {
      for place in net.places {
        if let m = dicMarking[place] {
          if marking[place]! < m {
            dicMarking[place] = marking[place]
          }
        } else {
          dicMarking[place] = marking[place]
        }
      }
    }
    return [Marking(dicMarking, net: net)]
  }
  
  /// minSet for minimum set is a function that removes all markings that could be redundant, i.e. a marking that is already included in another one.
  /// It would mean that the greater marking is already contained in lower one. Thus, we keep only the lowest marking when some of them are included in each other.
  /// - Parameter markings: The marking set
  /// - Returns: The minimal set of markings with no inclusion between all of them.
  public func minSet(markings: Set<Marking>) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    // Extract markings that are included in other ones
    var invalidMarkings: Set<Marking> = []
    for marking1 in markings {
      for marking2 in markings {
        if marking1 != marking2 {
          if marking2 <= marking1 {
            invalidMarkings.insert(marking1)
            break
          }
        }
      }
    }
    
    // The result is the subtraction between the original markings and thus that are already included
    return markings.subtracting(invalidMarkings)
  }
  
  /// Returns the canonical form of a predicate structure. Let suppose (a,b) in PS
  /// By canonical form, we mean reducing a in a singleton, removing all possible inclusions in b, and no marking in b included in a.
  /// In addition, when a value of a place in a marking "a" is greater than one of "b", the value of "b" marking is changed to the value of "a".
  /// - Returns: The canonical form of the predicate structure.
  public func canonised() -> PS {
    if let p = value {
      let canInclude = PS.convMax(markings: p.inc, net: net)
            
      if let markingInclude = canInclude.first {
        // In (a,b) ∈ PS, if a marking in b is included in a, it returns empty
        for marking in p.exc {
          if marking <= markingInclude {
            return PS(value: nil, net: net)
          }
        }
                
        // In ({q},b) ∈ PS, forall q_b in b, if q(p) >= q_b(p) => q_b(p) = q(p)
        var canExclude: Set<Marking> = []
        var markingTemp: Marking
        for marking in p.exc {
          markingTemp = marking
          for place in net.places {
            if markingTemp[place]! < markingInclude[place]! {
              markingTemp[place] = markingInclude[place]
            }
          }
          canExclude.insert(markingTemp)
        }
        // This is important to apply the minSet operation after the normalisation with include marking
        // Marking could become comparable with the previous step, and then be removed by minSet.
        canExclude = minSet(markings: canExclude)
        if canInclude.isEmpty && canExclude.isEmpty {
          return PS(value: nil, net: net)
        }
        return PS(value: (canInclude, canExclude), net: net)
      }
      return PS(value: ([], minSet(markings: p.exc)), net: net)
    }
    
    return PS(value: nil, net: net)
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
    
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    if let can = canonizedPS.value {
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
    } else {
      return []
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
    
    for mb in canonizedPS.value!.exc {
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
    
    return PS(value: ([marking], bMarkings), net: net)
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
  
  /// Product between a predicate structure and a set of predicate structures: ps * {ps1, ..., psn} = (ps ∩ ps1) ∪ ... ∪ (ps ∩ psn)
  /// - Parameters:
  ///   - sps: The set of predicate structures
  /// - Returns: The product between both parameters
  func distribute(sps: SPS) -> SPS {
    if let first = sps.first {
      if let _ = self.value {
        var rest = sps.values
        rest.remove(first)
        if rest == [] {
          return SPS(values: [self]).intersection([first])
        }
        return SPS(values: [self]).intersection([first]).union(self.distribute(sps: SPS(values: rest)))
      }
      return []
    }
    return [self]
  }
  
  
  /// Try to merge two predicate structures if there are comparable.
  /// The principle is similar to intervals, where the goal is to reunified intervals if they can be merged.
  /// Otherwise, nothing is changed.
  /// - Parameters:
  ///   - ps: The second predicate structure
  /// - Returns: The result of the merged. If this is not possible, returns the original predicate structures.
  public func merge(_ ps: PS) -> SPS {
    var ps1Temp = self
    var ps2Temp = ps
    
    if let p1 = self.value, let p2 = ps.value {
      if let am = p1.inc.first, let cm = p2.inc.first  {
        if p1.inc.count > 1 || p1.exc.count > 1 || p2.inc.count > 1 || p2.exc.count > 1 {
          return [self, ps]
        }
        if !(am <= cm) {
          ps1Temp = ps
          ps2Temp = self
        }
      }
    } else {
      if self.value == nil {
        return [ps]
      }
      return [self]
    }
    
    let a = ps1Temp.value!.inc
    let b = ps1Temp.value!.exc
    let c = ps2Temp.value!.inc
    let d = ps2Temp.value!.exc
    
    if let am = a.first, let cm = c.first {
      if let bm = b.first {
        if cm <= bm && am <= cm {
          if let dm = d.first {
            if bm <= dm {
              return [PS(value: (a,d), net: net)]
            }
            return [PS(value: (a,b), net: net)]
          }
          return [PS(value: (a,d), net: net)]
        }
      } else {
        if am <= cm {
          if let dm = d.first {
            if am <= dm {
              return [PS(value: (a,b), net: net)]
            }
            return [self, ps]
          }
          return [PS(value: (a,b), net: net)]
        }
        return [self, ps]
      }
    }
    
    return [self, ps]
  }
  
  /// Compute the inverse of the fire operation for a given transition. It takes into account the current predicate structure where it consumes tokens for post arcs and produces new ones for pre arcs.
  /// - Parameter transition: The given transition
  /// - Returns: A new predicate structure where the revert operation has been applied.
  public func revert(transition: String) -> PS? {
    if let p = value {
      var aTemp: Set<Marking> = []
      var bTemp: Set<Marking> = []
      
      if p.inc == [] {
        aTemp = [net.inputMarkingForATransition(transition: transition)]
      } else {
        for marking in p.inc {
          if let rev = net.revert(marking: marking, transition: transition) {
            aTemp.insert(rev)
          } else {
            return nil
          }
        }
      }
      if p.exc == [] {
        bTemp = []
      } else {
        for marking in p.exc {
          if let rev = net.revert(marking: marking, transition: transition) {
            bTemp.insert(rev)
          }
        }
      }
      return PS(value: (aTemp, bTemp), net: net)
    }
    
    return PS(value: nil, net: net)
  }
  
  /// General revert operation where all transitions are applied
  /// - Returns: A set of predicate structures resulting from the union of the revert operation on each transition on the current predicate structure.
  public func revert() -> SPS {
    var res: Set<PS> = []
    for transition in net.transitions {
      if let rev = self.revert(transition: transition) {
        res.insert(rev)
      }
    }
    return SPS(values: res)
  }
  
  /// Apply the intersection between two predicate structures
  /// - Parameters:
  ///   - ps: The second predicate structure to intersect
  ///   - isCanonical: A boolean to specifiy if each predicate structure is canonised during the process.
  /// - Returns: The result of the intersection
  public func intersection(_ ps: PS, isCanonical: Bool = true) -> PS {
    if let p1 = self.value, let p2 = ps.value {
      if isCanonical {
        return PS(value: (p1.inc.union(p2.inc), p1.exc.union(p2.exc)), net: self.net).canonised()
      }
      return PS(value: (p1.inc.union(p2.inc), p1.exc.union(p2.exc)), net: self.net)
    }
    return PS(value: nil, net: self.net)
  }
  
  /// To know if a marking belongs to a predicate structure
  /// - Parameter marking: The marking to check if it belongs to the ps
  /// - Returns: True if the marking belongs, false otherwise
  public func contains(marking: Marking) -> Bool {
    if let value = self.value {
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
    return false
  }
  
  /// The evaluation of the CTL operation AX for a specific predicate structure, without using the rewriting into ¬EX¬
  /// The idea behind AX is to give marking such as the next step, we get a specific predicate structure.
  /// For instance, if we think in term of transitions, it would mean to be sure that at the next step, a given transition may be always fireable.
  /// However, it does not mean that this transition will be always fired !
  /// To compute it, the revert function is also computed, but for each set of transitions in the power set of transitions, we have to ensure that the other transitions cannot be fired.
  /// The goal is to take the same path to have the potential to fire the same transition afterwards.
  /// For instance, let assume Transition = {t0, t1, t2}, powerset(Transition) = {{t0}, {t1}, {t2}, {t0, t1}, {t0, t2}, {t1, t2}, {t0, t1, t2}} (We remove the empty solution {})
  /// For each set in the powerset, we apply the intersection between the transition. For {t0,t1}, we get: rev(t0).intersection(rev(t1))
  /// Finally, on the rest of the transitions (here Transition \ {t0,t1} = {t2}), we use the intersection with the negation of the other transitions.
  /// - Returns: A set of predicate structures that contains the result of the revertTilde.
  public func revertTilde() -> SPS {
    if let _ = self.value {
      var res: SPS = []
      var resTemp: SPS = []
      var revPS: [String: PS] = [:]
      var revTransitionsPS: [Set<String>: PS] = [:]
      
      for t in net.transitions {
        if let rev = self.revert(transition: t) {
          if let _ = rev.value {
            revPS[t] = rev
          }
        }
      }
      
      let validTransitions = Set(revPS.keys)
      let powersetT = validTransitions.powerset.filter({$0 != []})
      
      for transitions in powersetT {
        for transition in transitions {
          if let rev = revPS[transition] {
            if let ps = revTransitionsPS[transitions] {
              revTransitionsPS[transitions] = ps.intersection(rev)
            } else {
              revTransitionsPS[transitions] = rev
            }
          }
        }
      }
            
      for transitions in powersetT {
        if let rev = revTransitionsPS[transitions] {
          resTemp = SPS(values: [rev])
          for transition in validTransitions.subtracting(transitions) {
            let psToIntersect = PS(value: ([net.inputMarkingForATransition(transition: transition)], []), net: net)
            resTemp = resTemp.intersection(psToIntersect.not())
          }
          res = res.union(resTemp)
        }
      }
      return res
    }
    return []
  }
  
  /// Subtract two PS, by removing all markings for the right PS into the left PS
  /// - Parameter ps: The ps to subtract
  /// - Returns: A sps containing no value of ps
  public func subtract(_ ps: PS) -> SPS {
    if self == ps || self.value == nil {
      return []
    } else if ps.value == nil {
      return SPS(values: [self])
    }
    
    let intersect = self.intersection(ps)
    if intersect.value == nil  {
      return [self]
    }
    
    let a = self.value!.inc
    let b = self.value!.exc
    let c = intersect.value!.inc
    let d = intersect.value!.exc
    
    var res: Set<PS> = []

    // If c == [], the start of the new predicate structures depends on d
    if c != [] {
      let ps1 = PS(value: (a, c.union(b)), net: net).canonised()
      res = res.union(SPS(values: [ps1]))
    }
    
    for marking in d {
      let ps = PS(value: ([marking],b), net: net).canonised()
      res.insert(ps)
    }
    res.remove(PS(value: nil, net: net))
    return SPS(values: res)
  }
  
  /// Subtract a ps with a set of predicate structures, by recursively applying the subtraction on the new elements.
  /// - Parameter sps: The set of predicate structures to subtract
  /// - Returns: A set of predicate structures where all elements of sps have been removed from ps
  public func subtract(_ sps: SPS) -> SPS {
    var res: SPS = [self]
    var spsTemp: SPS
    for ps in sps {
      spsTemp = []
      for psTemp in res {
        spsTemp = spsTemp.union(psTemp.subtract(ps))
      }
      res = spsTemp
    }
    return res
  }

}

extension PS: Hashable {
  public static func == (lhs: PS, rhs: PS) -> Bool {
    return lhs.value?.inc == rhs.value?.inc && lhs.value?.exc == rhs.value?.exc
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(value?.inc)
    hasher.combine(value?.exc)
  }
}

extension PS {
  
  public func isIncluded (_ ps: PS) -> Bool {
    
    if self == ps {
      return true
    }
    
    if let p1 = self.value, let p2 = ps.value {
      // (Ø, _) ⊆ (_, _)
      if p1.inc.isEmpty {
        // (Ø, _) ⊆ ({}, _)
        if !p2.inc.isEmpty {
          return false
        }
      }
      else {
        for m1 in p1.inc {
          for m2 in p2.inc {
            if !(m2 <= m1) {
              return false
            }
          }
        }
      }
      
      // (Ø, _) ⊆ (_, _)
      if p1.exc.isEmpty {
        // // (Ø, _) ⊆ (_, {_})
        if !p2.exc.isEmpty {
          return false
        }
      } else {
        for m1 in p1.exc {
          for m2 in p2.exc {
            if !(m1 <= m2) {
              return false
            }
          }
        }
      }
      return true
    }
    return false
  }
  
}

extension PS: CustomStringConvertible {
  public var description: String {
    if let p = value {
      return "(\(p.inc), \(p.exc))"
    }
    return "∅"
  }
}
