indirect enum CTL<PlaceType, TransitionType>: Hashable where PlaceType: Place, PlaceType.Content == Int, TransitionType: Transition {
  
  typealias SPS = Set<PS<PlaceType, TransitionType>>
  typealias PN = PetriNet<PlaceType, TransitionType>
  
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
  
  func eval(petrinet: PN) -> SPS {
    switch self {
    case .ap(let t):
      return [.ps([petrinet.inputMarkingForATransition(transition: t)], [])]
    case .after(let t):
      return [.ps([], [petrinet.outputMarkingForATransition(transition: t)])]
    case .true:
      var dicEmptyMarking: [PlaceType: Int] = [:]
      for place in PlaceType.allCases {
        dicEmptyMarking[place] = 0
      }
      return [.ps([Marking(dicEmptyMarking)], [])]
    case .and(let ctl1, let ctl2):
      return PS.intersection(sps1: ctl1.eval(petrinet: petrinet), sps2: ctl2.eval(petrinet: petrinet))
    case .not(let ctl1):
      return PS.notSPS(sps: ctl1.eval(petrinet: petrinet))
    case .EX(let ctl1):
      return PS.revert(sps: ctl1.eval(petrinet: petrinet), petrinet: petrinet)
    case .AX(let ctl1):
      return PS.revertTilde(sps: ctl1.eval(petrinet: petrinet), petrinet: petrinet)
    case .EF(let ctl1):
      return ctl1.evalEF(petrinet: petrinet)
    case .AF(let ctl1):
      return ctl1.evalAF(petrinet: petrinet)
    case .EG(let ctl1):
      return ctl1.evalEG(petrinet: petrinet)
    case .AG(let ctl1):
      return ctl1.evalAG(petrinet: petrinet)
    case .EU(let ctl1, let ctl2):
      return ctl1.evalEU(ctl: ctl2, petrinet: petrinet)
    case .AU(let ctl1, let ctl2):
      return ctl1.evalAU(ctl: ctl2, petrinet: petrinet)
    }
    
  }

  func evalEF(petrinet: PN) -> SPS {
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.union(sps1: res, sps2: PS.revert(sps: res, petrinet: petrinet))
    }
    return res
  }
  
  func evalAF(petrinet: PN) -> SPS {
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.union(
        sps1: res,
        sps2: PS.intersection(
          sps1: PS.revert(sps: res, petrinet: petrinet),
          sps2: PS.revertTilde(sps: res, petrinet: petrinet)
        )
      )
    }
    return res
  }
  
  func evalEG(petrinet: PN) -> SPS {
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.intersection(
        sps1: res,
        sps2: PS.union(
          sps1: PS.revert(sps: res, petrinet: petrinet),
          sps2: PS.revertTilde(sps: res, petrinet: petrinet)
        )
      )
    }
    return res
  }
  
  func evalAG(petrinet: PN) -> SPS {
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.intersection(sps1: res, sps2: PS.revertTilde(sps: res, petrinet: petrinet))
    }
    return res
  }
  
  func evalEU(ctl: CTL<PlaceType, TransitionType>, petrinet: PN) -> SPS {
    let phi = self.eval(petrinet: petrinet)
    var res = ctl.eval(petrinet: petrinet)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.union(
        sps1: res,
        sps2: PS.intersection(
          sps1: phi,
          sps2: PS.revert(sps: res, petrinet: petrinet)
        )
      )
    }
    return res
  }
  
  func evalAU(ctl: CTL<PlaceType, TransitionType>, petrinet: PN) -> SPS {
    let phi = self.eval(petrinet: petrinet)
    var res = ctl.eval(petrinet: petrinet)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.union(
        sps1: res,
        sps2: PS.intersection(
          sps1: phi,
          sps2: PS.intersection(
            sps1: PS.revert(sps: res, petrinet: petrinet),
            sps2: PS.revertTilde(sps: res, petrinet: petrinet))
        )
      )
    }
    return res
  }

}
