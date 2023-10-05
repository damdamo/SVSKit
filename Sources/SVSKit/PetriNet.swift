/// A Petri net.
///
/// `PetriNet` is a class where places and transitions are represented by String.
/// Petri net instances are created by providing:
/// - Set of places (set of strings)
/// - Set of transitions (set of strings)
/// - List of arcs
/// - (Optional) A capacity dictionnary, to denote the maximum number of tokens for each place
///
/// Example of a Petri net: (Visual and code representation)
///          t0
///        -> ▭
///  p0  /
///  o -
///      \
///        -> ▭ -> o <-> ▭
///           t1   p1   t2
///
///  ```let net = PetriNet(
///       places: ["p0", "p1"],
///       transitions: ["t0", "t1", "t2"],
///       arcs: .pre(from: "p0", to: "t0", labeled: 1),
///       .pre(from: "p0", to: "t1", labeled: 1),
///       .post(from: "t1", to: "p1", labeled: 1),
///       .pre(from: "p1", to: "t2", labeled: 1),
///       .post(from: "t2", to: "p1", labeled: 1),
///       capacity: ["p0": 10, "p1": 10]
///      )```
///
/// Petri net instances only represent the structual part of the corresponding model, meaning that
/// markings should be stored externally. They can however be used to compute the marking resulting
/// from the firing of a particular transition, using the method `fire(transition:from:)`. The
/// following example illustrates this method's usage:
///
///     if let marking = net.fire(transition: "t1", from: Marking(["p0": 1, "p1": 0], net: net)) {
///       print(marking)
///     }
///     // Prints: ["p0": 0, "p1": 1]
///
public class PetriNet
{

  public typealias ArcLabel = Int
  public typealias PlaceType = String
  public typealias TransitionType = String

  /// The description of an arc.
  public struct ArcDescription {

    /// The place to which the arc is connected.
    fileprivate let place: PlaceType

    /// The transition to which the arc is connected.
    fileprivate let transition: TransitionType

    /// The arc's label.
    fileprivate let label: ArcLabel

    /// The arc's direction.
    fileprivate let isPre: Bool

    private init(place: PlaceType, transition: TransitionType, label: ArcLabel, isPre: Bool) {
      self.place = place
      self.transition = transition
      self.label = label
      self.isPre = isPre
    }

    /// Creates the description of a precondition arc.
    ///
    /// - Parameters:
    ///   - place: The place from which the arc comes.
    ///   - transition: The transition to which the arc goes.
    ///   - label: The arc's label.
    public static func pre(
      from place: PlaceType,
      to transition: TransitionType,
      labeled label: ArcLabel)
      -> ArcDescription
    {
      return ArcDescription(place: place, transition: transition, label: label, isPre: true)
    }

    /// Creates the description of a postcondition arc.
    ///
    /// - Parameters:
    ///   - transition: The transition from which the arc comes.
    ///   - place: The place to which the arc goes.
    ///   - label: The arc's label.
    public static func post(
      from transition: TransitionType,
      to place: PlaceType,
      labeled label: ArcLabel)
      -> ArcDescription
    {
      return ArcDescription(place: place, transition: transition, label: label, isPre: false)
    }

  }

  /// Places of the net
  public let places: Set<PlaceType>
  /// Transitions of the net
  public let transitions: Set<TransitionType>
  /// This net's input matrix.
  public let input: [TransitionType: [PlaceType: ArcLabel]]
  /// This net's output matrix.
  public let output: [TransitionType: [PlaceType: ArcLabel]]
  /// The maximum number of tokens inside a place
  public let capacity: [PlaceType: Int]
  /// Computed property to compute the power set of a set of transitions
  public var powersetT: Set<Set<TransitionType>> {
    transitions.powerset
  }

  /// Initializes a Petri net with a sequence describing its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A sequence containing the descriptions of the Petri net's arcs.
  public init(places: Set<PlaceType>, transitions: Set<TransitionType>, arcs: [ArcDescription], capacity: [PlaceType: Int] = [:]) {
    
    self.places = places
    self.transitions = transitions
    var pre: [TransitionType: [PlaceType: ArcLabel]] = [:]
    var post: [TransitionType: [PlaceType: ArcLabel]] = [:]

    for arc in arcs {
      if arc.isPre {
        PetriNet.add(arc: arc, to: &pre)
      } else {
        PetriNet.add(arc: arc, to: &post)
      }
    }
    
    for (transition, dicPlaceToArc) in pre {
      precondition(transitions.contains(transition), "All transitions have not been declared in transitions")
      for (place, _) in dicPlaceToArc {
        precondition(places.contains(place), "All places have not been declared in places")
      }
    }
    
    self.input = pre
    self.output = post
    if capacity == [:] {
      var newCap: [PlaceType: Int] = [:]
      for place in places {
        newCap[place] = 1
      }
      self.capacity = newCap
    } else {
      precondition(Set(capacity.keys) == places, "The capacity do not match the required places")
      self.capacity = capacity
    }
  }
  
  init(places: Set<PlaceType>, transitions: Set<TransitionType>, input: [TransitionType: [PlaceType: ArcLabel]], output: [TransitionType: [PlaceType: ArcLabel]], capacity: [PlaceType: Int] = [:]) {
    self.places = places
    self.transitions = transitions
    self.input = input
    self.output = output
    self.capacity = capacity
  }

  /// Initializes a Petri net with descriptions of its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A variadic argument representing the descriptions of the Petri net's arcs.
  public convenience init(places: Set<PlaceType>, transitions: Set<TransitionType>, arcs: ArcDescription..., capacity: [PlaceType: Int] = [:]) {
    let newArcs: [ArcDescription] = arcs
    self.init(
      places: places,
      transitions: transitions,
      arcs: newArcs,
      capacity: capacity)
  }
  

  /// Computes the marking resulting from the firing of the given transition, from the given
  /// marking, assuming the former is fireable.
  /// If the number of tokens in a place would be greater than the capacity of the place, it returns nil.
  /// - Parameters:
  ///   - transition: The transition to fire.
  ///   - marking: The marking from which the given transition should be fired.
  /// - Returns:
  ///   The marking that results from the firing of the given transition if it is fireable, or
  ///   `nil` otherwise.
  public func fire(transition: TransitionType, from marking: Marking)
    -> Marking?
  {
    var newMarking = marking

    let pre = input[transition]
    let post = output[transition]

    for place in places {
      if let n = pre?[place] {
        guard marking[place]! >= n
          else { return nil }
        newMarking[place]! -= n
      }

      if let n = post?[place] {
        newMarking[place]! += n
        // If the marking generates a number of tokens greater than the capacity, we return nil
        if newMarking[place]! > capacity[place]! {
          return nil
        }
      }
    }

    return newMarking
  }

  /// Internal helper to process preconditions and postconditions.
  private static func add(
    arc: ArcDescription,
    to matrix: inout [TransitionType: [PlaceType: ArcLabel]])
  {
    if var column = matrix[arc.transition] {
      precondition(column[arc.place] == nil, "duplicate arc declaration")
      column[arc.place] = arc.label
      matrix[arc.transition] = column
    } else {
      matrix[arc.transition] = [arc.place: arc.label]
    }
  }

}

extension PetriNet {
  
  
  /// Compute the inverse of the firing function. It takes the marking and the transition, and it adds tokens in the pre places and removes token in the post places.
  /// - Parameters:
  ///   - marking: The marking
  ///   - transition: The transition
  /// - Returns: The new marking after the revert firing.
  public func revert(marking: Marking, transition: TransitionType) -> Marking? {
    var markingRes = marking
    for place in places {
      if let pre = input[transition]?[place] {
        if let post = output[transition]?[place] {
          if marking[place]! <= post {
            markingRes[place] = pre
          } else {
            markingRes[place] = marking[place]! + pre - post
          }
        } else {
          markingRes[place] = marking[place]! + pre
        }
        if marking[place]! > capacity[place]! || markingRes[place]! > capacity[place]! {
          return nil
        }
      } else {
        if let post = output[transition]?[place] {
          if marking[place]! <= post {
            markingRes[place] = 0
          } else {
            markingRes[place] = marking[place]! - post
          }
        }
      }
    }
    return markingRes
  }
  
  /// Apply the revert function for all transitions
  /// - Parameter marking: The marking
  /// - Returns: A set of markings that contains each new marking for each transition
  public func revert(marking: Marking) -> Set<Marking> {
    var res: Set<Marking> = []
    for transition in transitions {
      if let rev = revert(marking: marking, transition: transition) {
        res.insert(rev)
      }
    }
    return res
  }
  
  /// Apply the revert on a set of markings.
  /// - Parameter markings: The set of markings
  /// - Returns: The new sets of markings, which is a union of all revert firing for each marking.
  public func revert(markings: Set<Marking>) -> Set<Marking> {
    var res: Set<Marking> = []
    for marking in markings {
      res = res.union(revert(marking: marking))
    }
    return res
  }
  
  /// Return a marking that contains the minimum amount of tokens in each required place to allow a transition to be fired.
  func inputMarkingForATransition(transition: TransitionType) -> Marking {
    var dicMarking: [PlaceType: Int] = [:]
    for place in places {
      if let v = input[transition]?[place] {
        dicMarking[place] = v
      } else {
        dicMarking[place] = 0
      }
    }
    return Marking(dicMarking, net: self)
  }
  
  /// Return a marking that contains the exact amount of tokens after a firing of a transition
  func outputMarkingForATransition(transition: TransitionType) -> Marking {
    var dicMarking: [PlaceType: Int] = [:]
    for place in places {
      if let v = output[transition]![place] {
        dicMarking[place] = v
      } else {
        dicMarking[place] = 0
      }
    }
    return Marking(dicMarking, net: self)
  }
  
  /// Create the marking containing 0 token in each place
  /// - Returns: A marking where each place is associated to 0.
  public func zeroMarking() -> Marking {
    var dicMarking: [PlaceType: Int] = [:]
    for place in places {
      dicMarking[place] = 0
    }
    return Marking(dicMarking, net: self)
  }
  
}

//// All methods related to the structural reduction of a PN
//extension PetriNet {
//  
//  public func removePlace(place: PlaceType) -> PetriNet {
//    var newPlaces = places
//    newPlaces.remove(place)
//    var newTransitions = transitions
//    var newCapacity = capacity
//    newCapacity.removeValue(forKey: place)
//    var newInput = input
//    var newOutput = output
//    //[TransitionType: [PlaceType: ArcLabel]]
//    for transition in transitions {
//      if let dicPlaceToArcLabel = newInput[transition] {
//        if dicPlaceToArcLabel.keys.contains(place) {
//          newInput[transition]!.removeValue(forKey: place)
//          if newInput[transition]! == [:] {
//            newInput.removeValue(forKey: transition)
//          }
//        }
//      }
//      if let dicPlaceToArcLabel = newOutput[transition] {
//        if dicPlaceToArcLabel.keys.contains(place) {
//          newOutput[transition]!.removeValue(forKey: place)
//          if newOutput[transition]! == [:] {
//            newOutput.removeValue(forKey: transition)
//          }
//        }
//      }
//    }
//    return PetriNet(places: newPlaces, transitions: newTransitions, input: newInput, output: newOutput, capacity: newCapacity)
//  }
//
//  public func removeTransition(transition: TransitionType) -> PetriNet {
//    var potentialPlaceToRemove: Set<PlaceType> = []
//    var newTransitions = transitions
//    var newPlaces = places
//    var newCapacity = capacity
//    var newInput = input
//    var newOutput = output
//    //[TransitionType: [PlaceType: ArcLabel]]
//    
//    if let p = input[transition]?.keys {
//      potentialPlaceToRemove = potentialPlaceToRemove.union(p)
//    }
//    if let p = output[transition]?.keys {
//      potentialPlaceToRemove = potentialPlaceToRemove.union(p)
//    }
//    
//    newTransitions.remove(transition)
//    newInput.removeValue(forKey: transition)
//    newOutput.removeValue(forKey: transition)
//    
//    for t in newTransitions {
//      if potentialPlaceToRemove.isEmpty {
//        break
//      }
//      if let inputKeys = input[t]?.keys {
//        potentialPlaceToRemove = potentialPlaceToRemove.subtracting(inputKeys)
//      }
//      if let outputKeys = output[t]?.keys {
//        potentialPlaceToRemove = potentialPlaceToRemove.subtracting(outputKeys)
//      }
//    }
//    
//    print("Potential place to remove: \(potentialPlaceToRemove)")
//    for p in potentialPlaceToRemove {
//      newPlaces.remove(p)
//      newCapacity.removeValue(forKey: p)
//    }
//    
//    return PetriNet(places: newPlaces, transitions: newTransitions, input: newInput, output: newOutput, capacity: newCapacity)
//  }
//  
//  public func inputAndOutputTransitionsForAPlace(place: PlaceType) -> (inputTransitions: Set<TransitionType>, outputTransitions: Set<TransitionType>) {
//    var (inputTransitions, outputTransitions): (Set<TransitionType>, Set<TransitionType>) = ([],[])
//    for transition in transitions {
//      if let p = input[transition]?.keys {
//        if p.contains(place) {
//          inputTransitions.insert(transition)
//        }
//      }
//      if let p = output[transition]?.keys {
//        if p.contains(place) {
//          outputTransitions.insert(transition)
//        }
//      }
//    }
//    return (inputTransitions, outputTransitions)
//  }
//  
//  public func updateMarking(marking: Marking) -> Marking {
//    var newStorage = marking.storage
//    for (place, _) in newStorage {
//      if !places.contains(place) {
//        newStorage.removeValue(forKey: place)
//      }
//    }
//    return Marking(newStorage, net: self)
//  }
//  
//  public func structuralReduction(ctl: CTL) -> PetriNet {
//    
//    var newPn = self
//    let relatedPlaces = ctl.relatedPlaces()
//    
//    print("places: \(places)")
//    print("relatedPlaces: \(relatedPlaces)")
//    
//    for transition in newPn.transitions {
////      newPn = newPn.removalOfSeqTransition(transition: transition, relatedPlaces: relatedPlaces)
////      if newPn.transitions.contains(transition) {
////
////      }
//    }
//    
//    for place in newPn.places {
//      newPn = newPn.removalOfSeqPlace(place: place, relatedPlaces: relatedPlaces)
//      if newPn.places.contains(place) {
//        newPn = newPn.removalOfParallelPlace(place: place, relatedPlaces: relatedPlaces)
//      }
//    }
//    
//    var placesToRemove = places.subtracting(relatedPlaces)
//    
//    for transition in transitions {
//      if (input[transition] == [:] || input[transition] == nil) && (output[transition] == [:] || output[transition] == nil) {
//        newPn = newPn.removeTransition(transition: transition)
//      } else {
//        placesToRemove = placesToRemove.subtracting(input[transition]!.keys).subtracting(output[transition]!.keys)
//      }
//    }
//    
//    for place in placesToRemove {
//      newPn = newPn.removePlace(place: place)
//    }
//    
//    return newPn
//  }
//  
//  public func removalOfSeqTransition(transition: TransitionType, relatedPlaces: Set<PlaceType>) -> PetriNet {
//        
//    var newInput = input
//    var newOutput = output
//    
////    for transition in transitions {
//      // If we have at least one input and output
//      if let inputPlaceToLabel = input[transition], let outputPlaceToLabel = output[transition] {
//        // If none of the places are related to the ctl formula
//        if (Set(inputPlaceToLabel.keys).union(outputPlaceToLabel.keys)).intersection(relatedPlaces) == [] {
//          // If there exists only one input arc with a label one
//          if inputPlaceToLabel.count == 1 {
//            let (place, label) = inputPlaceToLabel.first!
//            if label == 1 {
//              var relatedTransitions: Set<TransitionType> = []
//              // We navigate into other transitions than the one of the loop
//              // We look for other transitions where P0 is their output
//              for otherTransition in transitions.subtracting([transition]) {
//                if let outputPlaces = output[otherTransition]?.keys {
//                  if outputPlaces.contains(place) {
//                    relatedTransitions.insert(otherTransition)
//                  }
//                }
//              }
//              for relatedTransition in relatedTransitions {
//                for placeOutput in outputPlaceToLabel.keys {
//                  let weightN = output[relatedTransition]![place]!
//                  let weightK = output[transition]![placeOutput]!
//                  var previousWeight = 0
//                  if let w = output[relatedTransition]![placeOutput] {
//                    previousWeight = w
//                  }
//                  newOutput[relatedTransition]![placeOutput] = weightN * weightK + previousWeight
//                }
//              }
//              var pn = PetriNet(places: places, transitions: transitions, input: newInput, output: newOutput, capacity: capacity)
//              
//              pn = pn.removePlace(place: place)
//              pn = pn.removeTransition(transition: transition)
//              return pn
//            }
//          }
//        }
//      }
//    return self
//  }
//  
//  public func removalOfSeqPlace(place: PlaceType, relatedPlaces: Set<PlaceType>) -> PetriNet {
//    if relatedPlaces.contains(place) {
//      return self
//    }
//    
//    // Looking for a transition with an output on "place" and an another transition with an input from "place"
//    for t1 in transitions {
//      if let outputPlaces = output[t1]?.keys {
//        if /*outputPlaces.count == 1 && */ outputPlaces.contains(place) {
//          for t2 in transitions.subtracting([t1]) {
//            if let inputPlaces = input[t2]?.keys {
//              if inputPlaces.count == 1 && inputPlaces.contains(place) {
//                let kw = output[t1]![place]!
//                let w = input[t2]![place]!
//                // If the output label arc is equal to k*w and the input label arc w, we can apply the reduction
//                if kw % w == 0 {
//                  if let t2OutputPlaces = output[t2]?.keys {
//                    var newOutput = output
//                    let k = kw / w
//                    for p1 in t2OutputPlaces {
//                      newOutput[t1]![p1] = newOutput[t2]![p1]! * k
//                    }
//                    var pn = PetriNet(places: places, transitions: transitions, input: input, output: newOutput, capacity: capacity)
//                    pn = pn.removePlace(place: place)
//                    pn = pn.removeTransition(transition: t2)
//                    return pn
//                  }
//                }
//              }
//            }
//          }
//        }
//      }
//    }
//    return self
//  }
//  
//  public func removalOfParallelPlace(place: PlaceType, relatedPlaces: Set<PlaceType>) -> PetriNet {
//    let (inputTransitions, outputTransitions) = inputAndOutputTransitionsForAPlace(place: place)
//    if inputTransitions.count == 1 && outputTransitions.count == 1 {
//      for p1 in places.subtracting([place]) {
//        // If we find another transition such that the input and output transition is the same as place
//        let (inputTransitionsForP1, outputTransitionsForP1) = inputAndOutputTransitionsForAPlace(place: p1)
//        if inputTransitions == inputTransitionsForP1 && outputTransitions == outputTransitionsForP1 {
//          let tOutput = outputTransitions.first!
//          let tInput = inputTransitions.first!
//          let labelOutput1 = output[tOutput]![place]!
//          let labelOutput2 = output[tOutput]![p1]!
//          let labelInput1 = input[tInput]![place]!
//          let labelInput2 = input[tInput]![p1]!
//          // If there exists a multiple k such that we can obtain the other label input and output
//          if labelOutput1 % labelOutput2 == 0 && labelInput1 % labelInput2 == 0 {
//            if labelOutput1 / labelOutput2 == labelInput1 / labelInput2 {
//              var pn = self
//              pn = pn.removePlace(place: place)
//              return pn
//            }
//          }
//        }
//      }
//    }
//    return self
//  }
//  
//  func removalOfParallelTransition() -> PetriNet {
//    return self
//  }
//  
//  func removalOfDeadTransition() -> PetriNet {
//    return self
//  }
//  
//  func removalOfRedundantPlace() -> PetriNet {
//    return self
//  }
//  
//  func removalOfRedundantTransition() -> PetriNet {
//    return self
//  }
//  
//  func removalOfCirclePattern() -> PetriNet {
//    return self
//  }
//}
//
//extension PetriNet: CustomStringConvertible {
//  public var description: String {
//    return """
//      Places: \(places.sorted())
//      Transitions: \(transitions.sorted())
//      Capacities: \(capacity.sorted(by: {$0.key <= $1.key}))
//      Input: \(input.sorted(by: {$0.key <= $1.key}))
//      Output: \(output.sorted(by: {$0.key <= $1.key}))
//    """
//  }
//  
//}
//
//extension PetriNet: Equatable {
//  public static func == (lhs: PetriNet, rhs: PetriNet) -> Bool {
//    return lhs.places == rhs.places
//    && lhs.transitions == rhs.transitions
//    && lhs.capacity == rhs.capacity
//    && lhs.input == rhs.input
//    && lhs.output == rhs.output
//  }
//  
//  
//}
