/// Set of predicate structures (SPS) are a set of PS that contains specific functions
/// Some of them are different from the usual set operations, such as intersection.
public struct SPS {
  
  /// The set of predicate structures
  public let values: Set<PS>
  
  public init(values: Set<PS>) {
    self.values = values
  }
  
  /// Apply the union between two sets of predicate structures. Almost the same as set union, except we remove the predicate structure empty if there is one.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the union is applied
  /// - Returns: The result of the union.
  public func union(_ sps: SPS) -> SPS {
    if self.isEmpty {
      return sps
    } else if sps.isEmpty{
      return self
    }
    let ps = self.values.first!
    var union = self.values.union(sps.values)
    if union.contains(PS(value: nil, net: ps.net)) {
      union.remove(PS(value: nil, net: ps.net))
    }
    return SPS(values: union)
  }
  
  /// Apply the intersection between two sets of predicate structures.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the intersection is applied
  ///   - isCanonical: An option to decide whether the application simplifies each new predicate structure into its canonical form. The intersection can create contradiction that leads to empty predicate structure or simplification. It is true by default, but it can be changed as false.
  /// - Returns: The result of the intersection.
  public func intersection(_ sps: SPS, isCanonical: Bool = true) -> SPS {
    var res: Set<PS> = []
    for ps1 in self {
      for ps2 in sps {
        let intersect = ps1.intersection(ps2, isCanonical: isCanonical)
        if let _ = intersect.value {
          res.insert(intersect)
        }
      }
    }

    return SPS(values: res)
  }
  
  
  /// Compute the negation of a set of predicate structures. This is the result of a combination of all elements inside a predicate structure with each element of the other predicate structures. E.g.: notSPS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Returns: The negation of a set of predicate structures
  public func not() -> SPS {
    if self.isEmpty {
      return self
    }
    var res = SPS(values: [])
    if let firstPs = self.first {
      let negSPS = firstPs.not()
      var spsWithoutFirst = self.values
      spsWithoutFirst.remove(firstPs)
      let rTemp = SPS(values: spsWithoutFirst).not()
      for ps in negSPS {
        res = res.union(ps.distribute(sps: rTemp))
      }
    }
    return res
  }
  
  /// Compute all of the underlying markings for a set of predicate structures.
  /// - Returns: All the markings encoded by a set of predicate structures
  public func underlyingMarkings() -> Set<Marking> {
    var markings: Set<Marking> = []
    for ps in self.values {
      markings = markings.union(ps.underlyingMarkings())
    }
    return markings
  }
  
  
  /// Is the current set of predicate structures is included in another one ?
  /// - Parameters:
  ///   - sps: The right set of predicate structures
  /// - Returns: True if it is included, false otherwise
  public func isIncluded(_ sps: SPS) -> Bool {
    if sps == [] {
      if self == [] {
        return true
      }
      return false
    }
    var spsToDiff: SPS
    var spsToDiffTemp: SPS = []
    let emptyPS = PS(value: nil, net: sps.values.first!.net)
    for ps1 in self {
      spsToDiff = []
      spsToDiffTemp = []
      for ps2 in sps {
        if ps1.intersection(ps2) != emptyPS {
          spsToDiffTemp = []
          for psNot in ps2.not() {
            spsToDiffTemp = spsToDiffTemp.union(psNot.distribute(sps: spsToDiff))
          }
          spsToDiff = spsToDiffTemp
          // If ps1 is already included in spsToDiff, there is no need to continue to apply the intersection on other elements. We can go to check the rest of self.
          if SPS(values: [ps1]).intersection(spsToDiff) == [] {
            break
          }
        }
      }
      // If ps1 is not included in spsToDiff when all elements have been added, this means there is at least one ps not included in sps, and thus it is false.
      if !(SPS(values: [ps1]).intersection(spsToDiff) == []) {
        return false
      }
    }
    return true
  }
  
  /// Are two sets of predicate structures equivalent ?
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the equivalence is checked
  /// - Returns: True is they are equivalentm false otherwise
  public func isEquiv(_ sps: SPS) -> Bool {
    return self.isIncluded(sps) && sps.isIncluded(self)
  }
  
  
  /// Is a predicate structutre is included/contained in a sps ?
  /// - Parameters:
  ///   - ps: The predicate structure to check
  /// - Returns: A boolean that returns true if the predicate structure is included, false otherwise
  public func contains(ps: PS) -> Bool {
    return SPS(values: [ps]).isIncluded(self)
  }
  
  public func contains(marking: Marking) -> Bool {
    for ps in values {
      if ps.contains(marking: marking) {
        return true
      }
    }
    return false
  }
  
  
  /// Compute the revert function on all markings of each predicate structures
  /// - Returns: A new set of predicate structures after the revert application
  public func revert() -> SPS {
    var res: SPS = []
    for ps in self {
      res = res.union(ps.revert())
    }
    return res
  }
  
  /// An extension of the revert function that represents AX in CTL logic.
  /// - Returns: A new set of predicate structures
  public func revertTilde(rewrited: Bool) -> SPS {
    if rewrited {
      return (self.not()).revert().not()
    }
    if self.values.isEmpty {
      return []
    }

    var res: SPS = []
    for ps in self {
      res = res.union(ps.revertTilde())
    }
    return res.union(SPS.deadlock(net: self.first!.net))
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
  public func simplified(complete: Bool = false) -> SPS {
    
    if self.isEmpty {
      return self
    }
    
    var mergedSet: Set<PS> = []
    var setTemp1: Set<PS> = []
    var setTemp2: Set<PS> = []
    var spsTemp: SPS = []
    var psFirst: PS
    var psFirstTemp: PS
    var b: Bool
    
    for ps in self {
      let can = ps.canonised()
      if let _ = can.value {
        setTemp1.insert(can)
      }
    }
    
    if setTemp1 == [] {
      return []
    }
    
    while !setTemp1.isEmpty {
      b = true
      let firstPS = setTemp1.first!
      setTemp1.remove(firstPS)
      for ps in setTemp1 {
        if ps.isIncluded(firstPS) {
          setTemp1.remove(ps)
        } else if firstPS.isIncluded(ps) {
          b = false
          break
        }
      }
      if b {
        setTemp2.insert(firstPS)
      }
    }
        
    while !setTemp2.isEmpty {
      psFirst = setTemp2.first!
      psFirstTemp = psFirst
      setTemp2.remove(psFirst)
      for ps in setTemp2 {
        spsTemp = psFirst.merge(ps)
        if spsTemp.count == 1 {
          psFirstTemp = spsTemp.first!
          setTemp2.remove(ps)
          setTemp2.insert(psFirstTemp)
          break
        }
      }
      if psFirst == psFirstTemp {
        mergedSet.insert(psFirstTemp)
      }
    }
      
    if complete {
      var reducedSPS: Set<PS> = mergedSet
      
      for ps in mergedSet {
        if SPS(values: [ps]).isIncluded(SPS(values: reducedSPS.filter({!($0 == ps)}))) {
          reducedSPS.remove(ps)
        }
      }
      return SPS(values: reducedSPS)
    }
    
    return SPS(values: mergedSet)
  }
  
  /// Create a set of predicate structures to represent all markings such as no transition are fireable.
  /// - Parameter net: The Petri net
  /// - Returns: The corresponding set of predicate structures
  public static func deadlock(net: PetriNet) -> SPS {
    var markings: Set<Marking> = []
    for transition in net.transitions {
      markings.insert(net.inputMarkingForATransition(transition: transition))
    }
    return SPS(values: [PS(value: ([], markings), net: net)])
  }
  
}

/// Allow the comparison between SPS.
extension SPS: Hashable {
  public static func == (lhs: SPS, rhs: SPS) -> Bool {
    return lhs.values == rhs.values
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(values)
  }
}

/// Allow to use for .. in .. .
extension SPS: Sequence {
  public func makeIterator() -> Set<PS>.Iterator {
      return values.makeIterator()
  }
}

/// Allow to get the first element of a collection.
extension SPS: Collection {
  public var startIndex: Set<PS>.Index {
    return values.startIndex
  }
  
  public var endIndex: Set<PS>.Index {
    return values.endIndex
  }
  
  public subscript(position: Set<PS>.Index) -> PS {
    return values[position]
  }
  
  public func index(after i: Set<PS>.Index) -> Set<PS>.Index {
    return values.index(after: i)
  }
  
  public var isEmpty: Bool {
    return values.isEmpty
  }
  
  public var count: Int {
    return values.count
  }

}

/// Allow to express a set of PS as an array which is converted into a set.
extension SPS: ExpressibleByArrayLiteral {
  public typealias ArrayLiteralElement = PS
  public init(arrayLiteral elements: PS...) {
    self.values = Set(elements)
  }
}

extension SPS: CustomStringConvertible {
  public var description: String {
    if values.isEmpty {
      return "{}"
    }
    var res: String = "{\n"
    for ps in values {
      res.append(" \(ps),\n")
    }
    res.removeLast(2)
    res.append("\n}")
    return res
  }
  
}
