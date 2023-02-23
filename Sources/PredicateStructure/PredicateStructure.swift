public enum PS<PlaceType, TransitionType>: Hashable where PlaceType: Place, PlaceType.Content == Int, TransitionType: Transition {

  typealias SPS = Set<PS<PlaceType, TransitionType>>
  
  case empty
  case ps(Set<Marking<PlaceType>>, Set<Marking<PlaceType>>)
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  func notPS() -> SPS {
    switch self {
    case .empty:
      var dicMarking: [PlaceType: Int] = [:]
      for place in PlaceType.allCases {
        dicMarking[place] = 0
      }
      return [.ps([Marking(dicMarking)], [])]
    case .ps(let inc, let exc):
      var sps: SPS = []
      for el in inc {
        sps.insert(.ps([], [el]))
      }
      for el in exc {
        sps.insert(.ps([el], []))
      }
      return sps
    }
  }
  
  /// convMax, for convergence maximal, is a function to compute a singleton containing a marking where each value is the maximum of all places for a given place.
  /// This is the convergent point such as all marking of markings are included in this convergent marking.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the maximum between all markings.
  static func convMax(markings: Set<Marking<PlaceType>>) -> Set<Marking<PlaceType>> {
    if markings.isEmpty {
      return []
    }
    
    var markingDic: [PlaceType: Int] = [:]
    for marking in markings {
      for place in PlaceType.allCases {
        if let m = markingDic[place] {
          if m < marking[place] {
            markingDic[place] = marking[place]
          }
        } else {
          markingDic[place] = marking[place]
        }
      }
    }
    return [Marking(markingDic)]
  }
  
  /// convMin, for convergence minimal, is a function to compute a singleton containing a marking where each value is the minimum of all places for a given place.
  /// This is the convergent point such as the convergent marking is included in all the other markings.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the minimum between all markings.
  static func convMin(markings: Set<Marking<PlaceType>>) -> Set<Marking<PlaceType>> {
    if markings.isEmpty {
      return []
    }
    
    var markingDic: [PlaceType: Int] = [:]
    for marking in markings {
      for place in PlaceType.allCases {
        if let m = markingDic[place] {
          if  marking[place] < m {
            markingDic[place] = marking[place]
          }
        } else {
          markingDic[place] = marking[place]
        }
      }
    }
    return [Marking(markingDic)]
  }
  
  /// minSet for minimum set is a function that removes all markings that could be redundant, i.e. a marking that is already included in another one.
  /// It would mean that the greater marking is already contained in lower one. Thus, we keep only the lowest marking when some of them are included in each other.
  /// - Parameter markings: The marking set
  /// - Returns: The minimal set of markings with no inclusion between all of them.
  static func minSet(markings: Set<Marking<PlaceType>>) -> Set<Marking<PlaceType>> {
    if markings.isEmpty {
      return []
    }
    
    // Extract markings that are included in other ones
    var invalidMarkings: Set<Marking<PlaceType>> = []
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
  func canPS() -> PS {
    switch self {
    case .empty:
      return .empty
    case .ps(let inc, let exc):
      let canInclude = PS.convMax(markings: inc)
      let preCanExclude = PS.minSet(markings: exc)
            
      if let markingInclude = canInclude.first {
        // In (a,b) ∈ PS, if a marking in b is included in a, it returns empty
        for marking in preCanExclude {
          if marking <= markingInclude {
            return .empty
          }
        }
        
        // In ({q},b) ∈ PS, forall q_b in b, if q(p) >= q_b(p) => q_b(p) = q(p)
        var canExclude: Set<Marking<PlaceType>> = []
        var markingTemp: Marking<PlaceType>
        for marking in preCanExclude {
          markingTemp = marking
          for place in PlaceType.allCases {
            if markingTemp[place] < markingInclude[place] {
              markingTemp[place] = markingInclude[place]
            }
          }
          canExclude.insert(markingTemp)
        }
        if canInclude.isEmpty && canExclude.isEmpty {
          return .empty
        }
        return .ps(canInclude, canExclude)
      }
      return .ps([], preCanExclude)
    }
  }
  
  /// Compute all the markings represented by the symbolic representation of a predicate structure.
  /// - Parameter petrinet: The model to use
  /// - Returns: The set of all possible markings, also known as the state space.
  func underlyingMarkings(petrinet: PetriNet<PlaceType, TransitionType>) -> Set<Marking<PlaceType>> {
    let canonizedPS = self.canPS()
    var placeSetValues: [PlaceType: Set<Int>] = [:]
    var res: Set<[PlaceType: Int]> = []
    var resTemp = res
    var lowerBound: Int
    var upperBound: Int
    
    // Create a dictionnary where the key is the place and whose values is a set of all possibles integers that can be taken
    switch canonizedPS {
    case .empty:
      return []
    case .ps(let a, _):
      if let am = a.first {
        for place in PlaceType.allCases {
          lowerBound = am[place]
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
    var markingSet: Set<Marking<PlaceType>> = Set(res.map({(el: [PlaceType: Int]) -> Marking<PlaceType> in
      Marking<PlaceType>(el)
    }))
    
    switch canonizedPS {
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
  static func encodeMarking(_ marking: Marking<PlaceType>) -> PS {
    var bMarkings: Set<Marking<PlaceType>> = []
    var markingTemp = marking
    for place in PlaceType.allCases {
      markingTemp[place] += 1
      bMarkings.insert(markingTemp)
      markingTemp = marking
    }
    
    return .ps([marking], bMarkings)
  }
  
  /// Encode a set of markings into a set of predicate structures.
  /// - Parameter markingSet: The marking set to encode
  /// - Returns: A set of predicate structures that encodes the set of markings
  static func encodeMarkingSet(_ markingSet: Set<Marking<PlaceType>>) -> SPS {
    var sps: SPS = []
    for marking in markingSet {
      sps.insert(encodeMarking(marking))
    }
    return PS.simplifiedSPS(sps: sps)
  }

  
}

// Functions that takes SPS as input
extension PS {
  
  /// Apply the union between two sets of predicate structures. Almost the same as set union, except we remove the predicate structure empty if there is one.
  /// - Parameters:
  ///   - s1: The first set of predicate structures
  ///   - s2: The first set of predicate structures
  /// - Returns: The result of the union.
  static func union(sps1: SPS, sps2: SPS) -> SPS {
    var union = sps1.union(sps2)
    if union.contains(.empty) {
      union.remove(.empty)
    }
    return union
  }
  
  /// Apply the intersection between two sets of predicate structures.
  /// - Parameters:
  ///   - s1: The first set of predicate structures
  ///   - s2: The second set of predicate structures
  ///   - isCanonical: An option to decide whether the application simplifies each new predicate structure into its canonical form. The intersection can create contradiction that leads to empty predicate structure or simplification. It is true by default, but it can be changed as false.
  /// - Returns: The result of the intersection.
  static func intersection(sps1: SPS, sps2: SPS, isCanonical: Bool = true) -> SPS {
    var res: SPS = []
    var temp: PS
    for ps1 in sps1 {
      for ps2 in sps2 {
        switch (ps1, ps2) {
        case (.empty, _):
          break
        case (_, .empty):
          break
        case (.ps(let inc1, let exc1), .ps(let inc2, let exc2)):
          if isCanonical {
            temp = PS.ps(inc1.union(inc2), exc1.union(exc2)).canPS()
            switch temp {
            case .empty:
              break
            default:
              res.insert(
                (PS.ps(inc1.union(inc2), exc1.union(exc2))).canPS()
              )
            }
          } else {
            res.insert(
              .ps(inc1.union(inc2), exc1.union(exc2))
            )
          }
        }
      }
    }
    return res
  }
  
  
  /// Compute the negation of a set of predicate structures. This is the result of a combination of all elements inside a predicate structure with each element of the other predicate structures. E.g.: notSPS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Parameter sps: The set of predicate structures
  /// - Returns: The negation of the set of predicate structures
  static func notSPS(sps: SPS) -> SPS {
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
  static func distribute(ps: PS, sps: SPS) -> SPS {
    if let first = sps.first {
      switch ps {
      case .empty:
        return []
      case let ps:
        var rest = sps
        rest.remove(first)
        if rest == [] {
          return intersection(sps1: [ps], sps2: [first])
        }
        return intersection(sps1: [ps], sps2: [first]).union(distribute(ps: ps, sps: rest))
      }
    }
    return [ps]
  }
  
  
  /// Is the left set of predicate structures included in the right one ?
  /// - Parameters:
  ///   - s1: The left set of predicate structures
  ///   - s2: The right set of predicate structures
  /// - Returns: True if it is included, false otherwise
  static func isIncluded(sps1: SPS, sps2: SPS) -> Bool {
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
  static func equiv(sps1: SPS, sps2: SPS) -> Bool {
    return isIncluded(sps1: sps1, sps2: sps2) && isIncluded(sps1: sps2, sps2: sps1)
  }
  
  static func isIn(ps: PS, sps: SPS) -> Bool {
    return isIncluded(sps1: [ps], sps2: sps)
  }
  
  static func revert(ps: PS, transition: TransitionType, petrinet: PetriNet<PlaceType, TransitionType>) -> PS? {
    switch ps {
    case .empty:
      return .empty
    case .ps(let a, let b):
      var aTemp: Set<Marking<PlaceType>> = []
      var bTemp: Set<Marking<PlaceType>> = []
      
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
      return .ps(aTemp, bTemp)
    }

  }
  
  static func revert(ps: PS, petrinet: PetriNet<PlaceType, TransitionType>) -> SPS {
    var res: SPS = []
    for transition in TransitionType.allCases {
      if let rev = revert(ps: ps, transition: transition, petrinet: petrinet) {
        res.insert(rev)
      }
    }
    return res
  }
  
  static func revert(sps: SPS, petrinet: PetriNet<PlaceType, TransitionType>) -> SPS {
    var res: SPS = []
    for ps in sps {
      res = res.union(revert(ps: ps, petrinet: petrinet))
    }
    return res
  }
  
  static func revertTilde(sps: SPS, petrinet: PetriNet<PlaceType, TransitionType>) -> SPS {
    return notSPS(sps: PS.revert(sps: PS.notSPS(sps: sps), petrinet: petrinet))
  }
  
  
  /// Try to merge two predicate structures if there are comparable.
  /// The principle is similar to intervals, where the goal is to reunified intervals if they can be merged.
  /// Otherwise, nothing is changed.
  /// - Parameters:
  ///   - ps1: The first predicate structure
  ///   - ps2: The second predicate structure
  /// - Returns: The result of the merged. If this is not possible, returns the original predicate structures.
  static func merge(ps1: PS, ps2: PS) -> SPS {
    var ps1Temp = ps1
    var ps2Temp = ps2
    
    switch (ps1, ps2) {
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
    
    switch (ps1Temp, ps2Temp) {
    case (.ps(let a, let b), .ps(let c, let d)):
      if let am = a.first, let cm = c.first {
        if let bm = b.first {
          if cm <= bm && am <= cm {
            if let dm = d.first {
              if bm <= dm {
                return [.ps(a,d)]
              }
              return [.ps(a,b)]
            }
            return [.ps(a,d)]
          }
        }
        if am <= cm {
          return [.ps(a,b)]
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
  static func simplifiedSPS(sps: SPS) -> SPS {
    var mergedSPS: SPS = []
    var mergedTemp: SPS = []
    var spsTemp: SPS = []
    var psFirst: PS = .empty
    var psFirstTemp: PS = .empty
    
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
      switch psFirst {
      case .ps(let a, let b):
        if b.count <= 1 {
          for ps in spsTemp {
            switch ps {
            case .ps(let c, let d):
              if d.count <= 1 {
                if let am = a.first, let bm = b.first, let cm = c.first {
                  if cm <= bm && am <= cm {
                    mergedTemp = merge(ps1: psFirstTemp, ps2: .ps(c, d))
                    if mergedTemp.count == 1 {
                      psFirstTemp = merge(ps1: psFirstTemp, ps2: .ps(c, d)).first!
                      spsTemp.remove(.ps(c, d))
                      spsTemp.insert(psFirstTemp)
                    }
                  }
                } else {
                  if let am = a.first, let cm = c.first, let dm = d.first {
                    if am <= dm && cm <= am {
                      mergedTemp = merge(ps1: psFirstTemp, ps2: .ps(c, d))
                      if mergedTemp.count == 1 {
                        psFirstTemp = merge(ps1: psFirstTemp, ps2: .ps(c, d)).first!
                        spsTemp.remove(.ps(c, d))
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
      if !PS.isIncluded(sps1: [ps], sps2: mergedSPS.filter({!($0 == ps)})) {
        reducedSPS.insert(ps)
      }
    }
    return reducedSPS
  }
  
}

extension PS: CustomStringConvertible {
  public var description: String {
    switch self {
    case .empty:
      return "∅"
    case .ps(let inc, let exc):
      return "(\(inc), \(exc)) \n"
    }
  }
}
