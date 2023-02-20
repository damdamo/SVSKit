public struct PSF<PlaceType, TransitionType> where PlaceType: Place, PlaceType.Content == Int, TransitionType: Transition {

  typealias SPS = Set<PS<PlaceType, TransitionType>>

  let sps: SPS
  let petrinet: PetriNet<PlaceType, TransitionType>

  func eval(ctl: CTL<PlaceType, TransitionType>) -> SPS {
    switch ctl {
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
      return PS.intersection(sps1: eval(ctl: ctl1), sps2: eval(ctl: ctl2))
    case .not(let ctl1):
      return PS.notSPS(sps: eval(ctl: ctl1))
    case .EX(let ctl1):
      return PS.revert(sps: eval(ctl: ctl1), petrinet: petrinet)
    case .AX(let ctl1):
      return PS.revertTilde(sps: eval(ctl: ctl1), petrinet: petrinet)
    case .EF(let ctl1):
      return evalEF(ctl: ctl1)
    case .AF(let ctl1):
      return evalAF(ctl: ctl1)
    case .EG(let ctl1):
      return evalEG(ctl: ctl1)
    case .AG(let ctl1):
      return evalAG(ctl: ctl1)
    case .EU(let ctl1, let ctl2):
      return evalEU(ctl1: ctl1, ctl2: ctl2)
    case .AU(let ctl1, let ctl2):
      return evalAU(ctl1: ctl1, ctl2: ctl2)
    }
    
  }

  func evalEF(ctl: CTL<PlaceType, TransitionType>) -> SPS {
    var res = eval(ctl: ctl)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.union(sps1: res, sps2: PS.revert(sps: res, petrinet: petrinet))
    }
    return res
  }
  
  func evalAF(ctl: CTL<PlaceType, TransitionType>) -> SPS {
    var res = eval(ctl: ctl)
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
  
  func evalEG(ctl: CTL<PlaceType, TransitionType>) -> SPS {
    var res = eval(ctl: ctl)
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
  
  func evalAG(ctl: CTL<PlaceType, TransitionType>) -> SPS {
    var res = eval(ctl: ctl)
    var resTemp: SPS = []
    while !PS.equiv(sps1: res, sps2: resTemp) {
      resTemp = res
      res = PS.intersection(sps1: res, sps2: PS.revertTilde(sps: res, petrinet: petrinet))
    }
    return res
  }
  
  func evalEU(ctl1: CTL<PlaceType, TransitionType>, ctl2: CTL<PlaceType, TransitionType>) -> SPS {
    let phi = eval(ctl: ctl1)
    var res = eval(ctl: ctl2)
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
  
  func evalAU(ctl1: CTL<PlaceType, TransitionType>, ctl2: CTL<PlaceType, TransitionType>) -> SPS {
    let phi = eval(ctl: ctl1)
    var res = eval(ctl: ctl2)
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
