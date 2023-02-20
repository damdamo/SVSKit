/// A Petri net.
///
/// `PetriNet` is a generic type, accepting two types representing the set of places and the set
/// of transitions that structurally compose the model. Both should conform to `CaseIterable`,
/// which guarantees that the set of places (resp. transitions) is bounded, and known statically.
/// The following example illustrates how to declare the places and transition of a simple Petri
/// net representing an on/off switch:
///
///     enum P: Place {
///       typealias Content = Int
///       case on, off
///     }
///
///     enum T: Transition {
///       case switchOn, switchOff
///     }
///
/// Petri net instances are created by providing the list of the preconditions and postconditions
/// that compose them. These should be provided in the form of arc descriptions (i.e. instances of
/// `ArcDescription`) and fed directly to the Petri net's initializer. The following example shows
/// how to create an instance of the on/off switch:
///
///
///     let model = PetriNet<P, T>(
///       .pre(from: .on, to: .switchOff),
///       .post(from: .switchOff, to: .off),
///       .pre(from: .off, to: .switchOn),
///       .post(from: .switchOn, to: .on),
///     )
///
/// Petri net instances only represent the structual part of the corresponding model, meaning that
/// markings should be stored externally. They can however be used to compute the marking resulting
/// from the firing of a particular transition, using the method `fire(transition:from:)`. The
/// following example illustrates this method's usage:
///
///     if let marking = model.fire(.switchOn, from: [.on: 0, .off: 1]) {
///       print(marking)
///     }
///     // Prints "[.on: 1, .off: 0]"
///
public struct PetriNet<PlaceType, TransitionType>
where PlaceType: Place, PlaceType.Content == Int, TransitionType: Transition
{

  public typealias ArcLabel = Int

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

  /// This net's input matrix.
  public let input: [TransitionType: [PlaceType: ArcLabel]]

  /// This net's output matrix.
  public let output: [TransitionType: [PlaceType: ArcLabel]]

  /// Initializes a Petri net with a sequence describing its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A sequence containing the descriptions of the Petri net's arcs.
  public init<Arcs>(_ arcs: Arcs) where Arcs: Sequence, Arcs.Element == ArcDescription {
    var pre: [TransitionType: [PlaceType: ArcLabel]] = [:]
    var post: [TransitionType: [PlaceType: ArcLabel]] = [:]

    for arc in arcs {
      if arc.isPre {
        PetriNet.add(arc: arc, to: &pre)
      } else {
        PetriNet.add(arc: arc, to: &post)
      }
    }

    self.input = pre
    self.output = post
  }

  /// Initializes a Petri net with descriptions of its preconditions and postconditions.
  ///
  /// - Parameters:
  ///   - arcs: A variadic argument representing the descriptions of the Petri net's arcs.
  public init(_ arcs: ArcDescription...) {
    self.init(arcs)
  }

  /// Computes the marking resulting from the firing of the given transition, from the given
  /// marking, assuming the former is fireable.
  ///
  /// - Parameters:
  ///   - transition: The transition to fire.
  ///   - marking: The marking from which the given transition should be fired.
  /// - Returns:
  ///   The marking that results from the firing of the given transition if it is fireable, or
  ///   `nil` otherwise.
  public func fire(transition: TransitionType, from marking: Marking<PlaceType>)
    -> Marking<PlaceType>?
  {
    var newMarking = marking

    let pre = input[transition]
    let post = output[transition]

    for place in PlaceType.allCases {
      if let n = pre?[place] {
        guard marking[place] >= n
          else { return nil }
        newMarking[place] -= n
      }

      if let n = post?[place] {
        newMarking[place] += n
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
  public func revert(marking: Marking<PlaceType>, transition: TransitionType) -> Marking<PlaceType> {
    var markingRes = marking
    for place in PlaceType.allCases {
      if let pre = input[transition]?[place] {
        if let post = output[transition]?[place] {
          if marking[place] <= post {
            print(pre)
            markingRes[place] = pre
          } else {
            markingRes[place] = marking[place] + pre - post
          }
        } else {
          markingRes[place] = marking[place] + pre
        }
      } else {
        if let post = output[transition]?[place] {
          if marking[place] <= post {
            markingRes[place] = 0
          } else {
            markingRes[place] = marking[place] - post
          }
        }
      }
    }
    return markingRes
  }
  
  /// Apply the revert function for all transitions
  /// - Parameter marking: The marking
  /// - Returns: A set of markings that contains each new marking for each transition
  func revert(marking: Marking<PlaceType>) -> Set<Marking<PlaceType>> {
    var res: Set<Marking<PlaceType>> = []
    for transition in TransitionType.allCases {
      res.insert(revert(marking: marking, transition: transition))
    }
    return res
  }
  
  /// Apply the revert on a set of markings.
  /// - Parameter markings: The set of markings
  /// - Returns: The new sets of markings, which is a union of all revert firing for each marking.
  func revert(markings: Set<Marking<PlaceType>>) -> Set<Marking<PlaceType>> {
    var res: Set<Marking<PlaceType>> = []
    for marking in markings {
      res = res.union(revert(marking: marking))
    }
    return res
  }
  
  func inputMarkingForATransition(transition: TransitionType) -> Marking<PlaceType> {
    var dicMarking: [PlaceType: Int] = [:]
    for place in PlaceType.allCases {
      if let v = input[transition]![place] {
        dicMarking[place] = v
      } else {
        dicMarking[place] = 0
      }
    }
    return Marking(dicMarking)
  }
  
  func outputMarkingForATransition(transition: TransitionType) -> Marking<PlaceType> {
    var dicMarking: [PlaceType: Int] = [:]
    for place in PlaceType.allCases {
      if let v = output[transition]![place] {
        dicMarking[place] = v
      } else {
        dicMarking[place] = 0
      }
    }
    return Marking(dicMarking)
  }
  
}

/// A place in a Petri net.
public protocol Place: CaseIterable, Hashable {

  associatedtype Content: Hashable

}

/// A transition in a Petri net.
public protocol Transition: CaseIterable, Hashable {}
