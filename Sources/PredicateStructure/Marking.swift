/// A marking of a Hero net.
///
/// A marking is a mapping that associates the places of a Hero net to the tokens they contain.
///
/// An algebra is defined over markings if the type used to represent the tokens associated with
/// each place (i.e. `PlaceType`) allows it. More specifically, markings are comparable if tokens
/// are too, and even conform to `AdditiveArithmetic` if tokens do to.
///
/// The following example illustrates how to perform arithmetic operations of markings:
///
///     let m0: Marking<P> = [.p0: ["1", "2"], .p1: ["4"]]
///     let m1: Marking<P> = [.p0: ["1", "3"], .p1: ["6"]]
///     print(m0 + m1)
///     // Prints "[.p0: ["1", "1", "2", "3"], .p1: ["4", "6"]]"
///
public struct Marking {
  
  /// The total map that backs this marking.
  var storage: [String: Int]
  let net: PetriNet

  /// Initializes a marking.
  ///
  /// - Parameters:
  ///   - mapping: A total map representing this marking.
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
  
  public subscript(place: String) -> Int? {
    get { return storage[place] }
    set { storage[place] = newValue }
  }
  
//  public var empty: Marking

}

//extension Marking: ExpressibleByDictionaryLiteral {
//
//  public init(dictionaryLiteral elements: (PlaceType, Int)...) {
//    let mapping = Dictionary(uniqueKeysWithValues: elements)
//    self.storage = TotalMap(mapping)
//  }
//
//}

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
//    guard lhs.places == rhs.places else {
//      fatalError("Both Petri nets used for the comparison are not the same")
//    }
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

//extension Marking: AdditiveArithmetic where Int: AdditiveArithmetic {
//
////  /// Initializes a marking with a dictionary, associating `Int.zero` for unassigned
////  /// places.
////  ///
////  /// - Parameters:
////  ///   - mapping: A dictionary representing this marking.
////  ///
////  /// The following example illustrates the use of this initializer:
////  ///
////  ///     let marking = Marking<P>([.p0: ["42", "1337"], .p1 ["12", "15"])
////  ///
////  public init(partial mapping: [PlaceType: Int]) {
////    self.storage = TotalMap(partial: mapping, defaultValue: .zero)
////  }
////
//  /// A marking in which all places are associated with `Int.zero`.
//  public static var zero: Marking {
//    return Marking { _ in Int.zero }
//  }
//
//  public static func + (lhs: Marking, rhs: Marking) -> Marking {
//    let newStorage = { key in lhs.storage[key] + rhs.storage[key] }
//    return Marking(storage: newStorage, petrinet: lhs.petrinet)
//  }
//
//  public static func += (lhs: inout Marking, rhs: Marking) {
//    for place in PlaceType.allCases {
//      lhs[place] += rhs[place]
//    }
//  }
//
//  public static func - (lhs: Marking, rhs: Marking) -> Marking {
//    return Marking { place in lhs[place] - rhs[place] }
//  }
//
//  public static func -= (lhs: inout Marking, rhs: Marking) {
//    for place in PlaceType.allCases {
//      lhs[place] -= rhs[place]
//    }
//  }
//
//}

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
