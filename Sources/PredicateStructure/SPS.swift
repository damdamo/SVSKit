/// Set of predicate structures (SPS) are a set of PS that contains specific functions
/// Some of them are different from the usual set operations, such as intersection.
struct SPS {
  
  let values: Set<PS>
  
  /// Apply the union between two sets of predicate structures. Almost the same as set union, except we remove the predicate structure empty if there is one.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the union is applied
  /// - Returns: The result of the union.
  func union(_ sps: SPS) -> SPS {
    if self.isEmpty {
      return sps
    } else if sps.isEmpty{
      return self
    }
    let ps = self.values.first!
    var union = self.values.union(sps.values)
    if union.contains(PS(ps: nil, net: ps.net)) {
      union.remove(PS(ps: nil, net: ps.net))
    }
    return SPS(values: union)
  }
  
  /// Apply the intersection between two sets of predicate structures.
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the intersection is applied
  ///   - isCanonical: An option to decide whether the application simplifies each new predicate structure into its canonical form. The intersection can create contradiction that leads to empty predicate structure or simplification. It is true by default, but it can be changed as false.
  /// - Returns: The result of the intersection.
  func intersection(_ sps: SPS, isCanonical: Bool = true) -> SPS {
    var res: Set<PS> = []
    var temp: PS
    for ps1 in self {
      for ps2 in sps {
        if let p1 = ps1.ps, let p2 = ps2.ps {
          let intersectRaw = PS(ps: (p1.inc.union(p2.inc), p1.exc.union(p2.exc)), net: ps1.net)
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

    return SPS(values: res)
  }
  
  
  /// Compute the negation of a set of predicate structures. This is the result of a combination of all elements inside a predicate structure with each element of the other predicate structures. E.g.: notSPS({([q1], [q2]), ([q3], [q4]), ([q5], [q6])}) = {([],[q1,q3,q5]), ([q6],[q1,q3]), ([q4],[q1,q5]), ([q4,q6],[q1]), ([q2],[q3,q5]), ([q2, q6],[q3]), ([q2, q4],[q5]), ([q2, q4,q6],[])}
  /// - Returns: The negation of a set of predicate structures
  func not() -> SPS {
    if self.isEmpty {
      return self
    }
    var res = SPS(values: [])
    if let first = self.first {
      let negSPS = first.not()
      var spsWithoutFirst = self.values
      spsWithoutFirst.remove(first)
      let rTemp = SPS(values: spsWithoutFirst).not()
      for ps in negSPS {
        res = res.union(ps.distribute(sps: rTemp))
      }
    }
    return res
  }
  
  
  /// Is the current set of predicate structures is included in another one ?
  /// - Parameters:
  ///   - sps: The right set of predicate structures
  /// - Returns: True if it is included, false otherwise
  func isIncluded(_ sps: SPS) -> Bool {
    if sps == [] {
      if self == [] {
        return true
      }
      return false
    }
    return self.intersection(sps.not()) == []
  }
  
  /// Are two sets of predicate structures equivalent ?
  /// - Parameters:
  ///   - sps: The set of predicate structures on which the equivalence is checked
  /// - Returns: True is they are equivalentm false otherwise
  func isEquiv(_ sps: SPS) -> Bool {
    return self.isIncluded(sps) && sps.isIncluded(self)
  }
  
  
  /// Is a predicate structutre is included/contained in a sps ?
  /// - Parameters:
  ///   - ps: The predicate structure to check
  /// - Returns: A boolean that returns true if the predicate structure is included, false otherwise
  func contains(ps: PS) -> Bool {
    return SPS(values: [ps]).isIncluded(self)
  }
  
  
  /// Compute the revert function on all markings of each predicate structures
  /// - Returns: A new set of predicate structures after the revert application
  func revert() -> SPS {
    var res: SPS = []
    for ps in self {
      res = res.union(ps.revert())
    }
    return res
  }
  
  /// An extension of the revert function that represents AX in CTL logic.
  /// - Returns: A new set of predicate structures
  func revertTilde() -> SPS {
    return (self.not()).revert().not()
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
  func simplified() -> SPS {
    
    if self.isEmpty {
      return self
    }
    
    var mergedSPS: Set<PS> = []
    var mergedTemp: SPS = []
    var spsTemp: Set<PS> = []
    var psFirst: PS
    var psFirstTemp: PS
    
    for ps in self {
      spsTemp.insert(ps.canonised())
    }
    
    if spsTemp == [] {
      return []
    }
        
    while !spsTemp.isEmpty {
      psFirst = spsTemp.first!
      psFirstTemp = psFirst
      spsTemp.remove(psFirst)
      if let p1 = psFirst.ps {
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
                    mergedTemp = psFirstTemp.merge(PS(ps: (c, d), net: psFirst.net))
                    if mergedTemp.count == 1 {
                      psFirstTemp = psFirstTemp.merge(PS(ps: (c, d), net: psFirst.net)).first!
                      spsTemp.remove(PS(ps: (c, d), net: psFirst.net))
                      spsTemp.insert(psFirstTemp)
                    }
                  }
                } else {
                  if let am = a.first, let cm = c.first, let dm = d.first {
                    if am <= dm && cm <= am {
                      mergedTemp = psFirstTemp.merge(PS(ps: (c, d), net: psFirst.net))
                      if mergedTemp.count == 1 {
                        psFirstTemp = psFirstTemp.merge(PS(ps: (c, d), net: psFirst.net)).first!
                        spsTemp.remove(PS(ps: (c, d), net: psFirst.net))
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
    
    var reducedSPS: Set<PS> = []
    
    for ps in mergedSPS {
      if !SPS(values: [ps]).isIncluded(SPS(values: mergedSPS.filter({!($0 == ps)}))) {
        reducedSPS.insert(ps)
      }
    }
    return SPS(values: reducedSPS)
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
  func makeIterator() -> Set<PS>.Iterator {
      return values.makeIterator()
  }
}

/// Allow to get the first element of a collection.
extension SPS: Collection {
  var startIndex: Set<PS>.Index {
    return values.startIndex
  }
  
  var endIndex: Set<PS>.Index {
    return values.endIndex
  }
  
  subscript(position: Set<PS>.Index) -> PS {
    return values[position]
  }
  
  func index(after i: Set<PS>.Index) -> Set<PS>.Index {
    return values.index(after: i)
  }
  
  var isEmpty: Bool {
    return values.isEmpty
  }
  
  var count: Int {
    return values.count
  }

}

/// Allow to express a set of PS as an array which is converted into a set.
extension SPS: ExpressibleByArrayLiteral {
  typealias ArrayLiteralElement = PS
  init(arrayLiteral elements: PS...) {
    self.values = Set(elements)
  }
}
