/// A marking of a Petri net.
///
/// A marking is a mapping that associates the places of a Petri net to the tokens they contain.
///
/// The following example illustrates how to define markings:
///
///     let net = Petrinet(
///       places: ["p0", "p1"],
///       ...
///     )
///     let m0 = Marking(["p0": 1, "p1": 4], net: net)
///
public struct Marking {
  
  /// The total map that backs this marking.
  public var storage: [String: Int]
  /// The net related to the marking
  public let net: PetriNet

  /// Initializes a marking.
  ///
  /// - Parameters:
  ///   - storage: A mapping representing this marking.
  ///   - net: The related Petri net
  public init(_ storage: [String: Int], net: PetriNet) {
    var places: Set<String> = []
    for (place, _) in storage {
      places.insert(place)
    }
    precondition(places == net.places, "Places between the marking and the Petri net do not match.")
    
    self.storage = storage
    self.net = net
  }

  /// A collection containing just the places of the marking.
  public var places: Set<String> {
    return net.places
  }
  
  /// Allows to  get or set a value of a marking the same way as a dictionnary
  /// e.g.: marking["p0"] / marking["p0"] = 2
  public subscript(place: String) -> Int? {
    get { return storage[place] }
    set { storage[place] = newValue }
  }
  

}

extension Marking: Equatable {
  public static func == (lhs: Marking, rhs: Marking) -> Bool {
    lhs.storage == rhs.storage
  }
}

extension Marking: Hashable {
  public func hash(into hasher: inout Hasher) {
      hasher.combine(storage)
  }
}

extension Marking: Comparable {

  public static func < (lhs: Marking, rhs: Marking) -> Bool {
    for place in lhs.places {
      guard lhs.storage[place]! < rhs.storage[place]! else {
        return false
      }
    }
    return true
  }
  
  public static func > (lhs: Marking, rhs: Marking) -> Bool {
    for place in lhs.places {
      guard lhs.storage[place]! > rhs.storage[place]! else {
        return false
      }
    }
    return true
  }
  
  public static func <= (lhs: Marking, rhs: Marking) -> Bool {
    for place in lhs.places {
      guard lhs.storage[place]! <= rhs.storage[place]! else {
        return false
      }
    }
    return true
  }
  
  public static func >= (lhs: Marking, rhs: Marking) -> Bool {
    for place in lhs.places {
      guard lhs.storage[place]! >= rhs.storage[place]! else {
        return false
      }
    }
    return true
  }
  
}

extension Marking: CustomStringConvertible {

  public var description: String {
    if self.storage.isEmpty {
      return "[]"
    }
    
    var res = "["
    for (place, values) in storage {
      res.append("\(place): \(values), ")
    }
    res.removeLast()
    res.removeLast()
    res.append(contentsOf: "]")
    return res
  }

}
