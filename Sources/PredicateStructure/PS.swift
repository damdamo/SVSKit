/// A Predicate structure (PS) is a symbolic structure to represent set of markings.
/// In a formal way, PS is a couple (a,b) ∈ PS, such as a,b ∈ Set<Marking>
/// A marking that is accepted by such a predicate structure must be included in all markings of "a" and not included in all markings of "b".
/// e.g.: ({(0,2)}, {(4,5)}).
/// (0,4), (2, 42), (42, 4) are valid markings, because (0,2) is included but not (4,5)
/// On the other hand, (0,1), (4,5), (4,42), (42,42) are not valid.
/// This representation allows to model a potential infinite set of markings in a finite way.
/// However, for the sake of finite representations and to compute them, we use the Petri net capacity on places to bound them.
public struct PS {

  public typealias SPS = Set<PS>
  public typealias PlaceType = String
  public typealias TransitionType = String
  
//  public enum PS: Hashable {
//    case empty
//    case ps(Set<Marking>, Set<Marking>)
//  }
  
  let ps: (inc: Set<Marking>, exc: Set<Marking>)?
  let petrinet: PetriNet
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  func not() -> SPS {
    if let p = ps {
      var sps: SPS = []
      for el in p.inc {
        // .ps([], [el])
        sps.insert(PS(ps: ([], [el]) , petrinet: petrinet))
      }
      for el in p.exc {
        sps.insert(PS(ps: ([el], []) , petrinet: petrinet))
      }
      return sps
    }
    
    var dicMarking: [PlaceType: Int] = [:]
    for place in petrinet.places {
      dicMarking[place] = 0
    }
    return [PS(ps: ([Marking(storage: dicMarking, petrinet: petrinet)], []), petrinet: petrinet)]
  }
  
  /// convMax, for convergence maximal, is a function to compute a singleton containing a marking where each value is the maximum of all places for a given place.
  /// This is the convergent point such as all marking of markings are included in this convergent marking.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the maximum between all markings.
  func convMax(markings: Set<Marking>) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    var dicMarking: [PlaceType: Int] = [:]
    for marking in markings {
      for place in petrinet.places {
        if let m = dicMarking[place] {
          if m < marking[place]! {
            dicMarking[place] = marking[place]
          }
        } else {
          dicMarking[place] = marking[place]
        }
      }
    }
    return [Marking(storage: dicMarking, petrinet: petrinet)]
  }
  
  /// convMin, for convergence minimal, is a function to compute a singleton containing a marking where each value is the minimum of all places for a given place.
  /// This is the convergent point such as the convergent marking is included in all the other markings.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the minimum between all markings.
  func convMin(markings: Set<Marking>) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    var dicMarking: [PlaceType: Int] = [:]
    for marking in markings {
      for place in petrinet.places {
        if let m = dicMarking[place] {
          if marking[place]! < m {
            dicMarking[place] = marking[place]
          }
        } else {
          dicMarking[place] = marking[place]
        }
      }
    }
    return [Marking(storage: dicMarking, petrinet: petrinet)]
  }
  
  /// minSet for minimum set is a function that removes all markings that could be redundant, i.e. a marking that is already included in another one.
  /// It would mean that the greater marking is already contained in lower one. Thus, we keep only the lowest marking when some of them are included in each other.
  /// - Parameter markings: The marking set
  /// - Returns: The minimal set of markings with no inclusion between all of them.
  func minSet(markings: Set<Marking>) -> Set<Marking> {
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
  func canonised() -> PS {
    if let p = ps {
      let canInclude = convMax(markings: p.inc)
      let preCanExclude = minSet(markings: p.exc)
            
      if let markingInclude = canInclude.first {
        // In (a,b) ∈ PS, if a marking in b is included in a, it returns empty
        for marking in preCanExclude {
          if marking <= markingInclude {
            return PS(ps: nil, petrinet: petrinet)
          }
        }
        
        // In ({q},b) ∈ PS, forall q_b in b, if q(p) >= q_b(p) => q_b(p) = q(p)
        var canExclude: Set<Marking> = []
        var markingTemp: Marking
        for marking in preCanExclude {
          markingTemp = marking
          for place in petrinet.places {
            if markingTemp[place]! < markingInclude[place]! {
              markingTemp[place] = markingInclude[place]
            }
          }
          canExclude.insert(markingTemp)
        }
        if canInclude.isEmpty && canExclude.isEmpty {
          return PS(ps: nil, petrinet: petrinet)
        }
        return PS(ps: (canInclude, canExclude), petrinet: petrinet)
      }
      return PS(ps: ([], preCanExclude), petrinet: petrinet)
    }
    
    return PS(ps: nil, petrinet: petrinet)
  }
  
  /// Compute all the markings represented by the symbolic representation of a predicate structure.
  /// - Parameter petrinet: The model to use
  /// - Returns: The set of all possible markings, also known as the state space.
  func underlyingMarkings() -> Set<Marking> {
    let canonizedPS = self.canonised()
    var placeSetValues: [PlaceType: Set<Int>] = [:]
    var res: Set<[PlaceType: Int]> = []
    var resTemp = res
    var lowerBound: Int
    var upperBound: Int
    
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    if let can = canonizedPS.ps {
      if let am = can.inc.first {
        for place in petrinet.places {
          lowerBound = am[place]!
          upperBound = petrinet.capacity[place]!
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
      Marking(storage: el, petrinet: petrinet)
    }))
    
    for mb in canonizedPS.ps!.exc {
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
  func encodeMarking(_ marking: Marking) -> PS {
    var bMarkings: Set<Marking> = []
    var markingTemp = marking
    for place in petrinet.places {
      markingTemp[place]! += 1
      bMarkings.insert(markingTemp)
      markingTemp = marking
    }
    
    return PS(ps: ([marking], bMarkings), petrinet: petrinet)
  }
  
  /// Encode a set of markings into a set of predicate structures.
  /// - Parameter markingSet: The marking set to encode
  /// - Returns: A set of predicate structures that encodes the set of markings
  func encodeMarkingSet(_ markingSet: Set<Marking>) -> SPS {
    var sps: SPS = []
    for marking in markingSet {
      sps.insert(encodeMarking(marking))
    }
    return simplified(sps: sps)
  }

}

extension PS: Hashable {
  public static func == (lhs: PS, rhs: PS) -> Bool {
    return lhs.ps?.inc == rhs.ps?.inc && lhs.ps?.exc == rhs.ps?.exc
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ps?.inc)
    hasher.combine(ps?.exc)
  }
}

// Functions that takes SPS as input
extension PS {
  
  /// Apply the union between two sets of predicate structures. Almost the same as set union, except we remove the predicate structure empty if there is one.
  /// - Parameters:
  ///   - s1: The first set of predicate structures
  ///   - s2: The first set of predicate structures
  /// - Returns: The result of the union.
  func union(sps1: SPS, sps2: SPS) -> SPS {
    var union = sps1.union(sps2)
    if union.contains(PS(ps: nil, petrinet: petrinet)) {
      union.remove(PS(ps: nil, petrinet: petrinet))
    }
    return union
  }
  
  /// Apply the intersection between two sets of predicate structures.
  /// - Parameters:
  ///   - s1: The first set of predicate structures
  ///   - s2: The second set of predicate structures
  ///   - isCanonical: An option to decide whether the application simplifies each new predicate structure into its canonical form. The intersection can create contradiction that leads to empty predicate structure or simplification. It is true by default, but it can be changed as false.
  /// - Returns: The result of the intersection.
  func intersection(sps1: SPS, sps2: SPS, isCanonical: Bool = true) -> SPS {
    var res: SPS = []
    var temp: PS
    for ps1 in sps1 {
      for ps2 in sps2 {
        if let p1 = ps1.ps, let p2 = ps2.ps {
          let intersectRaw = PS(ps: (p1.inc.union(p2.inc), p1.exc.union(p2.exc)), petrinet: petrinet)
          if isCanonical {
            temp = intersectRaw.canonised()
            if let _ = temp.ps {
              res.insert(temp)
            }
          } else {
            res.insert(intersectRaw)
          }
        }
      }
    }

    return res
  }
  
  
  /// Compute the negation of a set of predicate structures. This is the result of a combination of all elements inside a predicate structure with each element of the other predicate structures. E.g.: notSPS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Parameter sps: The set of predicate structures
  /// - Returns: The negation of the set of predicate structures
  func not(sps: SPS) -> SPS {
    if sps.isEmpty {
      return []
    }
    var res: SPS = []
    if let first = sps.first {
      let negSPS = first.not()
      var spsWithoutFirst = sps
      spsWithoutFirst.remove(first)
      let rTemp = not(sps: spsWithoutFirst)
      for ps in negSPS {
        res = union(sps1: res, sps2: ps.distribute(sps: rTemp))
      }
    }
    return res
  }
    
  
  /// Product between a predicate structure and a set of predicate structures: ps * {ps1, ..., psn} = (ps ∩ ps1) ∪ ... ∪ (ps ∩ psn)
  /// - Parameters:
  ///   - ps: The predicate structure
  ///   - sps: The set of predicate structures
  /// - Returns: The product between both parameters
  func distribute(sps: SPS) -> SPS {
    if let first = sps.first {
      if let p = ps {
        let ps1 = PS(ps: p, petrinet: petrinet)
        var rest = sps
        rest.remove(first)
        if rest == [] {
          return intersection(sps1: [ps1], sps2: [first])
        }
        return intersection(sps1: [ps1], sps2: [first]).union(ps1.distribute(sps: rest))
      }
      return []
    }
    return [self]
  }
  
  
  /// Is the left set of predicate structures included in the right one ?
  /// - Parameters:
  ///   - s1: The left set of predicate structures
  ///   - s2: The right set of predicate structures
  /// - Returns: True if it is included, false otherwise
  func isIncluded(sps1: SPS, sps2: SPS) -> Bool {
    if sps2 == [] {
      if sps1 == [] {
        return true
      }
      return false
    }
    return intersection(sps1: sps1, sps2: not(sps: sps2)) == []
  }
  
  /// Are two sets of predicate structures equivalent ?
  /// - Parameters:
  ///   - s1: First set of predicate structures
  ///   - s2: Second set of predicate structures
  /// - Returns: True is they are equivalentm false otherwise
  func isEquiv(sps1: SPS, sps2: SPS) -> Bool {
    return isIncluded(sps1: sps1, sps2: sps2) && isIncluded(sps1: sps2, sps2: sps1)
  }
  
  func isIn(ps: PS, sps: SPS) -> Bool {
    return isIncluded(sps1: [ps], sps2: sps)
  }
  
  func revert(transition: TransitionType) -> PS? {
    if let p = ps {
      var aTemp: Set<Marking> = []
      var bTemp: Set<Marking> = []
      
      if p.inc == [] {
        aTemp = [petrinet.inputMarkingForATransition(transition: transition)]
      } else {
        for marking in p.inc {
          if let rev = petrinet.revert(marking: marking, transition: transition) {
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
          if let rev = petrinet.revert(marking: marking, transition: transition) {
            bTemp.insert(rev)
          }
        }
      }
      return PS(ps: (aTemp, bTemp), petrinet: petrinet)
    }
    
    return PS(ps: nil, petrinet: petrinet)
  }
  
  func revert() -> SPS {
    var res: SPS = []
    for transition in petrinet.transitions {
      if let rev = self.revert(transition: transition) {
        res.insert(rev)
      }
    }
    return res
  }
  
  func revert(sps: SPS) -> SPS {
    var res: SPS = []
    for ps in sps {
      res = res.union(ps.revert())
    }
    return res
  }
  
  func revertTilde(sps: SPS) -> SPS {
    return not(sps: revert(sps: not(sps: sps)))
  }
  
  
  /// Try to merge two predicate structures if there are comparable.
  /// The principle is similar to intervals, where the goal is to reunified intervals if they can be merged.
  /// Otherwise, nothing is changed.
  /// - Parameters:
  ///   - ps1: The first predicate structure
  ///   - ps2: The second predicate structure
  /// - Returns: The result of the merged. If this is not possible, returns the original predicate structures.
  func merge(_ ps: PS) -> SPS {
    var ps1Temp = self
    var ps2Temp = ps
    
    if let p1 = self.ps, let p2 = ps.ps {
      if let am = p1.inc.first, let cm = p2.inc.first  {
        if !(am <= cm) {
          ps1Temp = ps
          ps2Temp = self
        }
      }
    } else {
      if self.ps == nil {
        return [ps]
      }
      return [self]
    }
    
    let a = ps1Temp.ps!.inc
    let b = ps1Temp.ps!.exc
    let c = ps2Temp.ps!.inc
    let d = ps2Temp.ps!.exc
    
    if let am = a.first, let cm = c.first {
      if let bm = b.first {
        if cm <= bm && am <= cm {
          if let dm = d.first {
            if bm <= dm {
              return [PS(ps: (a,d), petrinet: petrinet)]
            }
            return [PS(ps: (a,b), petrinet: petrinet)]
          }
          return [PS(ps: (a,d), petrinet: petrinet)]
        }
      }
      if am <= cm {
        return [PS(ps: (a,b), petrinet: petrinet)]
      }
    }
    
    return [self, ps]
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
  func simplified(sps: SPS) -> SPS {
    var mergedSPS: SPS = []
    var mergedTemp: SPS = []
    var spsTemp: SPS = []
    var psFirst: PS = PS(ps: nil, petrinet: petrinet)
    var psFirstTemp = psFirst
    
    for ps in sps {
      spsTemp.insert(ps.canonised())
    }
    
    if spsTemp == [] {
      return []
    }
        
    while !spsTemp.isEmpty {
      psFirst = spsTemp.first!
      psFirstTemp = psFirst
      spsTemp.remove(psFirst)
      if let p1 = ps {
        let a = p1.inc
        let b = p1.exc
        if b.count <= 1 {
          for ps in spsTemp {
            if let p2 = ps.ps {
              let c = p2.inc
              let d = p2.exc
              if d.count <= 1 {
                if let am = a.first, let bm = b.first, let cm = c.first {
                  if cm <= bm && am <= cm {
                    mergedTemp = psFirstTemp.merge(PS(ps: (c, d), petrinet: petrinet))
                    if mergedTemp.count == 1 {
                      psFirstTemp = psFirstTemp.merge(PS(ps: (c, d), petrinet: petrinet)).first!
                      spsTemp.remove(PS(ps: (c, d), petrinet: petrinet))
                      spsTemp.insert(psFirstTemp)
                    }
                  }
                } else {
                  if let am = a.first, let cm = c.first, let dm = d.first {
                    if am <= dm && cm <= am {
                      mergedTemp = psFirstTemp.merge(PS(ps: (c, d), petrinet: petrinet))
                      if mergedTemp.count == 1 {
                        psFirstTemp = psFirstTemp.merge(PS(ps: (c, d), petrinet: petrinet)).first!
                        spsTemp.remove(PS(ps: (c, d), petrinet: petrinet))
                        spsTemp.insert(psFirstTemp)
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      mergedSPS.insert(psFirstTemp)
    }
    
    var reducedSPS: SPS = []
    
    for ps in mergedSPS {
      if !isIncluded(sps1: [ps], sps2: mergedSPS.filter({!($0 == ps)})) {
        reducedSPS.insert(ps)
      }
    }
    return reducedSPS
  }
  
}

extension PS: CustomStringConvertible {
  public var description: String {
    if let p = ps {
      return "(\(p.inc), \(p.exc)) \n"
    }
    return "∅"
  }
}
