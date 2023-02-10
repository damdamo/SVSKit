public enum PS<PlaceType>: Hashable where PlaceType: Place, PlaceType.Content == Int {

  typealias SPS = Set<PS<PlaceType>>
  // Predicate structure: (Include set, Exclude set)
//  let include: Set<Marking<PlaceType>>
//  let exclude: Set<Marking<PlaceType>>
  
  case empty
  case ps(Set<Marking<PlaceType>>, Set<Marking<PlaceType>>)

//  public init(include: Set<Marking<PlaceType>>, exclude: Set<Marking<PlaceType>>) {
//    guard include != [] && exclude != [] else {
//      fatalError("Cannot have a predicate structure of the form (∅,∅)")
//    }
//    self.include = include
//    self.exclude = exclude
//  }
  
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
        return .ps(canInclude, canExclude)
      }
      return .ps([], preCanExclude)
    }
  }
  
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
