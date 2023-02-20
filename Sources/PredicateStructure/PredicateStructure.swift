public enum PS<PlaceType, TransitionType>: Hashable where PlaceType: Place, PlaceType.Content == Int, TransitionType: Transition {

  typealias SPS = Set<PS<PlaceType, TransitionType>>
  
  case empty
  case ps(Set<Marking<PlaceType>>, Set<Marking<PlaceType>>)
  
  /// Compute the negation of a predicate structure, which is a set of predicate structures
  /// - Returns: Returns the negation of the predicate structure
  func notPS() -> SPS {
    switch self {
    case .empty:
      return []
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
          if marking2 < marking1 {
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
  
  static func revert(ps: PS, transition: TransitionType, petrinet: PetriNet<PlaceType, TransitionType>) -> PS {
    switch ps {
    case .empty:
      return .empty
    case .ps(let a, let b):
      var aTemp: Set<Marking<PlaceType>> = []
      var bTemp: Set<Marking<PlaceType>> = []
      
      if a == [] {
        aTemp = [Marking(petrinet.input[transition]!)]
      } else {
        for marking in a {
          aTemp.insert(petrinet.revert(marking: marking, transition: transition))
        }
      }
      if b == [] {
        bTemp = []
      } else {
        for marking in b {
          bTemp.insert(petrinet.revert(marking: marking, transition: transition))
        }
      }
      return .ps(aTemp, bTemp)
    }

  }
  
  static func revert(ps: PS, petrinet: PetriNet<PlaceType, TransitionType>) -> SPS {
    var res: SPS = []
    for transition in TransitionType.allCases {
      res.insert(revert(ps: ps, transition: transition, petrinet: petrinet))
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
  
  // Old version of notSPS
  //  static func notSPS(sps: SPS) -> SPS {
  //    if sps.isEmpty {
  //      return []
  //    }
  //    if let first = sps.first {
  //      var rest = sps
  //      rest.remove(first)
  //      return notSPSRec(ps: first, sps: rest)
  //    }
  //    return []
  //  }
  //
  //  static func notSPSRec(ps: PS, sps: SPS) -> SPS {
  //    var res: SPS = []
  //    switch ps {
  //    case .empty:
  //      fatalError("Not possible")
  //    case .ps([], []):
  //      break
  //    case .ps(let inc, []):
  //      let negSPS = notSPS(sps: sps)
  //      for marking in inc {
  //        res = res.union(distribute(ps: .ps([], [marking]), sps: negSPS))
  //      }
  //    case .ps([], let exc):
  //      let negSPS = notSPS(sps: sps)
  //      for marking in exc {
  //        res = res.union(distribute(ps: .ps([marking], []), sps: negSPS))
  //      }
  //    case .ps(let inc, let exc):
  //      if let firstInc = inc.first {
  //        var restInc = inc
  //        restInc.remove(firstInc)
  //        res = distribute(ps: .ps([], [firstInc]), sps: notSPS(sps: sps)).union(notSPS(sps: union(s1: [.ps(restInc, exc)], s2: sps)))
  //      }
  //    }
  //    return res
  //  }

  
}

extension PS: CustomStringConvertible {
  public var description: String {
    switch self {
    case .empty:
      return "∅"
    case .ps(let inc, let exc):
      return "(\(inc), \(exc))"
    }
  }
}
