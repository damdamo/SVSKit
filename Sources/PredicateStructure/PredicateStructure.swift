public struct PS<PlaceType>: Hashable where PlaceType: Place, PlaceType.Content == Int {

  typealias SPS = Set<PS<PlaceType>>
  // Predicate structure: (Include set, Exclude set)
  let include: Set<Marking<PlaceType>>
  let exclude: Set<Marking<PlaceType>>

  public init(include: Set<Marking<PlaceType>>, exclude: Set<Marking<PlaceType>>) {
    guard include != [] && exclude != [] else {
      fatalError("Cannot have a predicate structure of the form (∅,∅)")
    }
    self.include = include
    self.exclude = exclude
  }
  
  func notPS() -> SPS {
    var sps: SPS = []
    for el in include {
      sps.insert(PS(include: [], exclude: [el]))
    }
    for el in exclude {
      sps.insert(PS(include: [el], exclude: []))
    }
    return sps
  }
  
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
  
  func canPS() -> PS {
    let canInclude = PS.convMax(markings: include)
    let preCanExclude = PS.minSet(markings: exclude)
    
    if let markingInclude = canInclude.first {
//      for marking in exclude {
//        if marking <= markingInclude {
//          return
//        }
//      }
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
      return PS(include: canInclude, exclude: canExclude)
    }
    
    return PS(include: [], exclude: preCanExclude)
    
  }
  
  public static func == (lhs: PS<PlaceType>, rhs: PS<PlaceType>) -> Bool {
    return lhs.include == rhs.include && lhs.exclude == rhs.exclude
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.include)
    hasher.combine(self.exclude)
  }
}

extension PS: CustomStringConvertible {
  public var description: String {
    return "(\(include), \(exclude))"
  }
}
