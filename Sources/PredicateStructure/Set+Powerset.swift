extension Set {
  public var powerset: Set<Set<Element>> {
    guard count > 0 else {
        return [[]]
    }

    let head = self.first!
    // tail contains the whole array BUT the first element
    let tail = self.subtracting([head])

    // computing the tail's powerset
    let withoutHead = tail.powerset

    // mergin the head with the tail's powerset
//    let withHead: Set<Set<Element>> = withoutHead.map({$0.union([head])})
    var withHead: Set<Set<Element>> = []
    for el in withoutHead {
      withHead.insert(el.union([head]))
    }
    
    // returning the tail's powerset and the just computed withHead array
    return withHead.union(withoutHead)
  }
}
