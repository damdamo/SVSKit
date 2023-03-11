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
  
  public let value: (inc: Set<Marking>, exc: Set<Marking>)?
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
  public func convMax(markings: Set<Marking>) -> Set<Marking> {
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
  public func convMin(markings: Set<Marking>) -> Set<Marking> {
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
      let canInclude = convMax(markings: p.inc)
      let preCanExclude = minSet(markings: p.exc)
            
      if let markingInclude = canInclude.first {
        // In (a,b) ∈ PS, if a marking in b is included in a, it returns empty
        for marking in preCanExclude {
          if marking <= markingInclude {
            return PS(value: nil, net: net)
          }
        }
        
        // In ({q},b) ∈ PS, forall q_b in b, if q(p) >= q_b(p) => q_b(p) = q(p)
        var canExclude: Set<Marking> = []
        var markingTemp: Marking
        for marking in preCanExclude {
          markingTemp = marking
          for place in net.places {
            if markingTemp[place]! < markingInclude[place]! {
              markingTemp[place] = markingInclude[place]
            }
          }
          canExclude.insert(markingTemp)
        }
        if canInclude.isEmpty && canExclude.isEmpty {
          return PS(value: nil, net: net)
        }
        return PS(value: (canInclude, canExclude), net: net)
      }
      return PS(value: ([], preCanExclude), net: net)
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
    
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    if let can = canonizedPS.value {
      if let am = can.inc.first {
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
      if let p = value {
        let ps1 = PS(value: p, net: net)
        var rest = sps.values
        rest.remove(first)
        if rest == [] {
          return SPS(values: [ps1]).intersection([first])
        }
        return SPS(values: [ps1]).intersection([first]).union(ps1.distribute(sps: SPS(values: rest)))
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
  
  public func revert() -> SPS {
    var res: Set<PS> = []
    for transition in net.transitions {
      if let rev = self.revert(transition: transition) {
        res.insert(rev)
      }
    }
    return SPS(values: res)
  }
  
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

extension PS: CustomStringConvertible {
  public var description: String {
    if let p = value {
      return "(\(p.inc), \(p.exc))"
    }
    return "∅"
  }
}

extension PS {
  
  public func isIncluded (_ ps: PS) -> Bool {
    
    if self == ps {
      return true
    }
    
    if let p1 = self.value, let p2 = ps.value {
      for m1 in p1.inc {
        for m2 in p2.inc {
          if !(m2 <= m1) {
            return false
          }
        }
      }
      for m1 in p1.exc {
        for m2 in p2.exc {
          if !(m1 <= m2) {
            return false
          }
        }
      }
      return true
    }
    return false
  }
  
}

extension PS {
  
  func revertTildeBis() -> SPS {
    if let _ = self.value {
      var res: SPS = []
      var resTemp: SPS = []
      var revPS: [String: PS] = [:]
      var revSPS: [Set<String>: SPS] = [:]
      
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
            if let sps = revSPS[transitions] {
              revSPS[transitions] = sps.intersection(SPS(values: [rev]))
            } else {
              revSPS[transitions] = SPS(values: [rev])
            }
          }
        }
      }
            
      for transitions in powersetT {
        if let rev = revSPS[transitions] {
          resTemp = rev
          for transition in validTransitions.subtracting(transitions) {
            if !(SPS(values: [revPS[transition]!]).isIncluded(revSPS[transitions]!)) {
              let psToIntersect = PS(value: ([net.inputMarkingForATransition(transition: transition)], []), net: net)
              resTemp = resTemp.intersection(psToIntersect.not())
            }
          }
          res = res.union(resTemp)
        }
      }
      
      return res
    }

    return []
  }
  
//  func revertTildeBis() -> SPS {
//    if let _ = self.value {
//      var res: SPS = []
//      var resTemp: SPS = []
//      var setMarking: Set<Marking> = []
//      var revDic: [String: PS] = [:]
//
//      for t in net.transitions {
//        if let rev = self.revert(transition: t) {
//          if let _ = rev.value {
//            revDic[t] = rev
//          }
//        }
//      }
//
//      for t1 in revDic.keys {
//        if let rev = revDic[t1] {
//          let convRev1 = self.convMax(markings: revDic[t1]!.value!.inc).first!
//          setMarking.insert(convRev1)
//          resTemp = [rev]
//          for t2 in revDic.keys {
//            if t1 != t2 {
//              if !(revDic[t1]!.isIncluded(revDic[t2]!)) {
//                let psToIntersect = PS(value: ([net.inputMarkingForATransition(transition: t2)], []), net: net)
//                resTemp = resTemp.intersection(psToIntersect.not())
//              }
//            }
//          }
//          res = res.union(resTemp)
//        }
//      }
//
//      let singleton = self.convMax(markings: setMarking)
//      if singleton.first!.storage.allSatisfy({$0.value <= net.capacity[$0.key]!}) {
//        let spsMax = SPS(values: [PS(value: (singleton, []), net: net)])
//        res = res.union(spsMax)
//      }
//      return res
//    }
//
//    return []
//  }
  
}
