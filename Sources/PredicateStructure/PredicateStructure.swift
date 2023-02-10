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
  
  public static func == (lhs: PS<PlaceType>, rhs: PS<PlaceType>) -> Bool {
    return lhs.include == rhs.include && lhs.exclude == rhs.exclude
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.include)
    hasher.combine(self.exclude)
  }
}

