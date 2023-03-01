//import DDKit
//
///// A Predicate structure (PS) is a symbolic structure to represent set of markings.
///// In a formal way, PS is a couple (a,b) ∈ PS, such as a,b ∈ Set<Marking>
///// A marking that is accepted by such a predicate structure must be included in all markings of "a" and not included in all markings of "b".
///// e.g.: ({(0,2)}, {(4,5)}).
///// (0,4), (2, 42), (42, 4) are valid markings, because (0,2) is included but not (4,5)
///// On the other hand, (0,1), (4,5), (4,42), (42,42) are not valid.
///// This representation allows to model a potential infinite set of markings in a finite way.
///// However, for the sake of finite representations and to compute them, we use the Petri net capacity on places to bound them.
//public struct PSDD<PlaceType, TransitionType>: Hashable where PlaceType: Place & Comparable, PlaceType.Content == Int, TransitionType: Transition {
//  
//  typealias SPS = Set<MFDD<PlaceType, Int>>
//  
//  
//}
