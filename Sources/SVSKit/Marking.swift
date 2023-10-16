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
  
  /// <= and leq are different. <= is a comparable operator to know if a marking is included in another one. leq is a function to give an order to all markings, even if they are not comparable.
  public func leq(_ rhs: Marking) -> Bool {
    if self == rhs {
      return true
    }
    for (key, _) in self.storage.sorted(by: {$0.key < $1.key}) {
      if self[key]! < rhs[key]! {
        return true
      } else if rhs[key]! < self[key]! {
        return false
      }
    }
    return true
  }
  
  /// convMax, for convergence maximal, is a function to compute a singleton containing a marking where each value is the maximum of all places for a given place.
  /// This is the convergent point such as all marking of markings are included in this convergent marking.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the maximum between all markings.
  public static func convMax(markings: Set<Marking>, net: PetriNet) -> Marking {
    if markings.isEmpty {
      return net.zeroMarking()
    } else if markings.count == 1 {
      return markings.first!
    }
      
    var res = markings.first!
    
    for marking in markings.subtracting([res]) {
      for place in net.places {
        res[place] = max(marking[place]!, res[place]!)
      }
    }
    return res
  }
  
  /// convMin, for convergence minimal, is a function to compute a singleton containing a marking where each value is the minimum of all places for a given place.
  /// This is the convergent point such as the convergent marking is included in all the other markings.
  /// - Parameter markings: The marking set
  /// - Returns: The singleton that contains one marking where each place takes the minimum between all markings.
  public static func convMin(markings: Set<Marking>, net: PetriNet) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    var dicMarking: [String: Int] = [:]
    for marking in markings {
      for place in net.places {
        if let m = dicMarking[place] {
          if marking[place]! < m {
            dicMarking[place] = marking[place]
          }
        } else {
          dicMarking[place] = marking[place]
        }
      }
    }
    return [Marking(dicMarking, net: net)]
  }
  
  /// minSet for minimum set is a function that removes all markings that could be redundant, i.e. a marking that is already included in another one.
  /// It would mean that the greater marking is already contained in lower one. Thus, we keep only the lowest marking when some of them are included in each other.
  /// - Parameter markings: The marking set
  /// - Returns: The minimal set of markings with no inclusion between all of them.
  public static func minSet(markings: Set<Marking>) -> Set<Marking> {
    if markings.isEmpty {
      return []
    }
    
    // Extract markings that are included in other ones
    var invalidMarkings: Set<Marking> = []
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
  
  public static func numberOfCombinations(forLimits markingLimits: Marking) -> Int {
    let limits = markingLimits.storage.values.sorted()
    var totalCombinations = 1
    for limit in limits {
        totalCombinations *= (limit + 1)
    }
    return totalCombinations
  }
  
  public func minus(_ marking: Marking) -> Marking {
    let result = self.storage.merging(marking.storage) { $0 - $1 }
    return Marking(result, net: net)
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
  
  public static func comparable(m1: Marking, m2: Marking) -> Bool {
    return (m1 <= m2) || (m2 <= m1)
  }
  
}

extension Marking: CustomStringConvertible {

  public var description: String {
    if self.storage.isEmpty {
      return "[]"
    }
    
    var res = "["
    for (place, values) in storage.sorted(by: {$0.key < $1.key}) {
      res.append("\(place): \(values), ")
//      res.append("\(values), ")
    }
    res.removeLast()
    res.removeLast()
    res.append(contentsOf: "]")
    return res
  }

}
