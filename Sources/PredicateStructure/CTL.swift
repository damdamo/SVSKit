indirect enum CTL<PlaceType, TransitionType>: Hashable where PlaceType: Place, PlaceType.Content == Int, TransitionType: Transition {
  
  // Basic case
  case ap(TransitionType)
  case after(TransitionType)
  // Boolean logic
  case `true`
  case and(CTL, CTL)
  case not(CTL)
  // CTL operators
  case EX(CTL)
  case EF(CTL)
  case EG(CTL)
  case EU(CTL, CTL)
  case AX(CTL)
  case AF(CTL)
  case AG(CTL)
  case AU(CTL, CTL)
}

//protocol CTLSemantics {
//  // To think about more constraints to add
//  associatedtype T: Hashable
//
//  func eval(_ formula: CTL) -> T
//}
