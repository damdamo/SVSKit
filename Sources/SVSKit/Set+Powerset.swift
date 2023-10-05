extension Set {
  /// Returns the powerset of a set
  public var powerset: Set<Set<Element>> {
    guard count > 0 else {
        return [[]]
    }

    let head = self.first!
    let tail = self.subtracting([head])

    let withoutHead = tail.powerset

    var withHead: Set<Set<Element>> = []
    for el in withoutHead {
      withHead.insert(el.union([head]))
    }
    
    return withHead.union(withoutHead)
  }
}
