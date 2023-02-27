/// A Predicate structure (PS) is a symbolic structure to represent set of markings.
/// In a formal way, PS is a couple (a,b) ∈ PS, such as a,b ∈ Set<Marking>
/// A marking that is accepted by such a predicate structure must be included in all markings of "a" and not included in all markings of "b".
/// e.g.: ({(0,2)}, {(4,5)}).
/// (0,4), (2, 42), (42, 4) are valid markings, because (0,2) is included but not (4,5)
/// On the other hand, (0,1), (4,5), (4,42), (42,42) are not valid.
/// This representation allows to model a potential infinite set of markings in a finite way.
/// However, for the sake of finite representations and to compute them, we use the Petri net capacity on places to bound them.
public struct PredicateStructure {

  public typealias SPS = Set<PredicateStructure>
  public typealias PlaceType = String
  public typealias TransitionType = String
  
  public enum PS: Hashable {
    case empty
    case ps(Set<Marking>, Set<Marking>)
  }
  
  let ps: PS
  let petrinet: PetriNet
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  func notPS() -> SPS {
    switch ps {
    case .empty:
      var dicMarking: [PlaceType: Int] = [:]
      for place in petrinet.places {
        dicMarking[place] = 0
      }
      return [PredicateStructure(ps: .ps([Marking(storage: dicMarking, petrinet: petrinet)], []), petrinet: petrinet)]
    case .ps(let inc, let exc):
      var sps: SPS = []
      for el in inc {
        sps.insert(PredicateStructure(ps: .ps([], [el]), petrinet: petrinet))
      }
      for el in exc {
        sps.insert(PredicateStructure(ps: .ps([el], []), petrinet: petrinet))
      }
      return sps
    }
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
  func canPS() -> PredicateStructure {
    switch ps {
    case .empty:
      return PredicateStructure(ps: .empty, petrinet: petrinet)
    case .ps(let inc, let exc):
      let canInclude = convMax(markings: inc)
      let preCanExclude = minSet(markings: exc)
            
      if let markingInclude = canInclude.first {
        // In (a,b) ∈ PS, if a marking in b is included in a, it returns empty
        for marking in preCanExclude {
          if marking <= markingInclude {
            return PredicateStructure(ps: .empty, petrinet: petrinet)
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
          return PredicateStructure(ps: .empty, petrinet: petrinet)
        }
        return PredicateStructure(ps: .ps(canInclude, canExclude), petrinet: petrinet)
      }
      return PredicateStructure(ps: .ps([], preCanExclude), petrinet: petrinet)
    }
  }
  
  /// Compute all the markings represented by the symbolic representation of a predicate structure.
  /// - Parameter petrinet: The model to use
  /// - Returns: The set of all possible markings, also known as the state space.
  func underlyingMarkings() -> Set<Marking> {
    let canonizedPS = self.canPS()
    var placeSetValues: [PlaceType: Set<Int>] = [:]
    var res: Set<[PlaceType: Int]> = []
    var resTemp = res
    var lowerBound: Int
    var upperBound: Int
    
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    switch canonizedPS.ps {
    case .empty:
      return []
    case .ps(let a, _):
      if let am = a.first {
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
    
    switch canonizedPS.ps {
    case .ps(_, let b):
      for mb in b {
        for marking in markingSet {
          if mb <= marking {
            markingSet.remove(marking)
          }
        }
      }
    case .empty:
      fatalError("Cannot be empty")
    }
    
    return markingSet
  }
  
  
  /// Encode a marking into a predicate structure. This predicate structure encodes a singe marking.
  /// - Parameter marking: The marking to encode
  /// - Returns: The predicate structure that represents the marking
  func encodeMarking(_ marking: Marking) -> PredicateStructure {
    var bMarkings: Set<Marking> = []
    var markingTemp = marking
    for place in petrinet.places {
      markingTemp[place]! += 1
      bMarkings.insert(markingTemp)
      markingTemp = marking
    }
    
    return PredicateStructure(ps: .ps([marking], bMarkings), petrinet: petrinet)
  }
  
  /// Encode a set of markings into a set of predicate structures.
  /// - Parameter markingSet: The marking set to encode
  /// - Returns: A set of predicate structures that encodes the set of markings
  func encodeMarkingSet(_ markingSet: Set<Marking>) -> SPS {
    var sps: SPS = []
    for marking in markingSet {
      sps.insert(encodeMarking(marking))
    }
    return simplifiedSPS(sps: sps)
  }

}

extension PredicateStructure: Hashable {
  public static func == (lhs: PredicateStructure, rhs: PredicateStructure) -> Bool {
    return lhs.ps == rhs.ps
  }
  
  public func hash(into hasher: inout Hasher) {
      hasher.combine(ps)
  }
}

// Functions that takes SPS as input
extension PredicateStructure {
  
  /// Apply the union between two sets of predicate structures. Almost the same as set union, except we remove the predicate structure empty if there is one.
  /// - Parameters:
  ///   - s1: The first set of predicate structures
  ///   - s2: The first set of predicate structures
  /// - Returns: The result of the union.
  func union(sps1: SPS, sps2: SPS) -> SPS {
    var union = sps1.union(sps2)
    if union.contains(PredicateStructure(ps: .empty, petrinet: petrinet)) {
      union.remove(PredicateStructure(ps: .empty, petrinet: petrinet))
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
    var temp: PredicateStructure
    for ps1 in sps1 {
      for ps2 in sps2 {
        switch (ps1.ps, ps2.ps) {
        case (.empty, _):
          break
        case (_, .empty):
          break
        case (.ps(let inc1, let exc1), .ps(let inc2, let exc2)):
          let intersectRaw = PredicateStructure(ps: PS.ps(inc1.union(inc2), exc1.union(exc2)), petrinet: petrinet)
          if isCanonical {
            temp = intersectRaw.canPS()
            switch temp.ps {
            case .empty:
              break
            default:
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
  func notSPS(sps: SPS) -> SPS {
    if sps.isEmpty {
      return []
    }
    var res: SPS = []
    if let first = sps.first {
      let negSPS = first.notPS()
      var spsWithoutFirst = sps
      spsWithoutFirst.remove(first)
      let rTemp = notSPS(sps: spsWithoutFirst)
      for ps in negSPS {
        res = union(sps1: res, sps2: distribute(ps: ps, sps: rTemp))
      }
    }
    return res
  }
    
  
  /// Product between a predicate structure and a set of predicate structures: ps * {ps1, ..., psn} = (ps ∩ ps1) ∪ ... ∪ (ps ∩ psn)
  /// - Parameters:
  ///   - ps: The predicate structure
  ///   - sps: The set of predicate structures
  /// - Returns: The product between both parameters
  func distribute(ps: PredicateStructure, sps: SPS) -> SPS {
    if let first = sps.first {
      switch ps.ps {
      case .empty:
        return []
      case let p:
        let ps1 = PredicateStructure(ps: p, petrinet: petrinet)
        var rest = sps
        rest.remove(first)
        if rest == [] {
          return intersection(sps1: [ps1], sps2: [first])
        }
        return intersection(sps1: [ps1], sps2: [first]).union(distribute(ps: ps1, sps: rest))
      }
    }
    return [ps]
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
    return intersection(sps1: sps1, sps2: notSPS(sps: sps2)) == []
  }
  
  /// Are two sets of predicate structures equivalent ?
  /// - Parameters:
  ///   - s1: First set of predicate structures
  ///   - s2: Second set of predicate structures
  /// - Returns: True is they are equivalentm false otherwise
  func equiv(sps1: SPS, sps2: SPS) -> Bool {
    return isIncluded(sps1: sps1, sps2: sps2) && isIncluded(sps1: sps2, sps2: sps1)
  }
  
  func isIn(ps: PredicateStructure, sps: SPS) -> Bool {
    return isIncluded(sps1: [ps], sps2: sps)
  }
  
  func revert(ps: PredicateStructure, transition: TransitionType) -> PredicateStructure? {
    switch ps.ps {
    case .empty:
      return PredicateStructure(ps: .empty, petrinet: petrinet)
    case .ps(let a, let b):
      var aTemp: Set<Marking> = []
      var bTemp: Set<Marking> = []
      
      if a == [] {
        aTemp = [petrinet.inputMarkingForATransition(transition: transition)]
      } else {
        for marking in a {
          if let rev = petrinet.revert(marking: marking, transition: transition) {
            aTemp.insert(rev)
          } else {
            return nil
          }
        }
      }
      if b == [] {
        bTemp = []
      } else {
        for marking in b {
          if let rev = petrinet.revert(marking: marking, transition: transition) {
            bTemp.insert(rev)
          }
        }
      }
      return PredicateStructure(ps: .ps(aTemp, bTemp), petrinet: petrinet)
    }

  }
  
  func revert(ps: PredicateStructure) -> SPS {
    var res: SPS = []
    for transition in petrinet.transitions {
      if let rev = revert(ps: ps, transition: transition) {
        res.insert(rev)
      }
    }
    return res
  }
  
  func revert(sps: SPS) -> SPS {
    var res: SPS = []
    for ps in sps {
      res = res.union(revert(ps: ps))
    }
    return res
  }
  
  func revertTilde(sps: SPS) -> SPS {
    return notSPS(sps: revert(sps: notSPS(sps: sps)))
  }
  
  
  /// Try to merge two predicate structures if there are comparable.
  /// The principle is similar to intervals, where the goal is to reunified intervals if they can be merged.
  /// Otherwise, nothing is changed.
  /// - Parameters:
  ///   - ps1: The first predicate structure
  ///   - ps2: The second predicate structure
  /// - Returns: The result of the merged. If this is not possible, returns the original predicate structures.
  func merge(ps1: PredicateStructure, ps2: PredicateStructure) -> SPS {
    var ps1Temp = ps1
    var ps2Temp = ps2
    
    switch (ps1.ps, ps2.ps) {
    case (.ps(let a, _), .ps(let c, _)):
      if let am = a.first, let cm = c.first  {
        if !(am <= cm) {
          ps1Temp = ps2
          ps2Temp = ps1
        }
      }
    default:
      return [ps1,ps2]
    }
    
    switch (ps1Temp.ps, ps2Temp.ps) {
    case (.ps(let a, let b), .ps(let c, let d)):
      if let am = a.first, let cm = c.first {
        if let bm = b.first {
          if cm <= bm && am <= cm {
            if let dm = d.first {
              if bm <= dm {
                return [.init(ps: .ps(a,d), petrinet: petrinet)]
              }
              return [.init(ps: .ps(a,b), petrinet: petrinet)]
            }
            return [.init(ps: .ps(a,d), petrinet: petrinet)]
          }
        }
        if am <= cm {
          return [.init(ps: .ps(a,b), petrinet: petrinet)]
        }
      }
    default:
      return [ps1,ps2]
    }
    return [ps1,ps2]
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
  func simplifiedSPS(sps: SPS) -> SPS {
    var mergedSPS: SPS = []
    var mergedTemp: SPS = []
    var spsTemp: SPS = []
    var psFirst: PredicateStructure = .init(ps: .empty, petrinet: petrinet)
    var psFirstTemp: PredicateStructure = .init(ps: .empty, petrinet: petrinet)
    
    for ps in sps {
      spsTemp.insert(ps.canPS())
    }
    
    if spsTemp == [] {
      return []
    }
        
    while !spsTemp.isEmpty {
      psFirst = spsTemp.first!
      psFirstTemp = psFirst
      spsTemp.remove(psFirst)
      switch psFirst.ps {
      case .ps(let a, let b):
        if b.count <= 1 {
          for ps in spsTemp {
            switch ps.ps {
            case .ps(let c, let d):
              if d.count <= 1 {
                if let am = a.first, let bm = b.first, let cm = c.first {
                  if cm <= bm && am <= cm {
                    mergedTemp = merge(ps1: psFirstTemp, ps2: .init(ps: .ps(c, d), petrinet: petrinet))
                    if mergedTemp.count == 1 {
                      psFirstTemp = merge(ps1: psFirstTemp, ps2: .init(ps: .ps(c, d), petrinet: petrinet)).first!
                      spsTemp.remove(.init(ps: .ps(c, d), petrinet: petrinet))
                      spsTemp.insert(psFirstTemp)
                    }
                  }
                } else {
                  if let am = a.first, let cm = c.first, let dm = d.first {
                    if am <= dm && cm <= am {
                      mergedTemp = merge(ps1: psFirstTemp, ps2: .init(ps: .ps(c, d), petrinet: petrinet))
                      if mergedTemp.count == 1 {
                        psFirstTemp = merge(ps1: psFirstTemp, ps2: .init(ps: .ps(c, d), petrinet: petrinet)).first!
                        spsTemp.remove(.init(ps: .ps(c, d), petrinet: petrinet))
                        spsTemp.insert(psFirstTemp)
                      }
                    }
                  }
                }
              }
            case .empty:
              break
            }
          }
        }
      case .empty:
        break
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

extension PredicateStructure: CustomStringConvertible {
  public var description: String {
    switch self.ps {
    case .empty:
      return "∅"
    case .ps(let inc, let exc):
      return "(\(inc), \(exc)) \n"
    }
  }
}
