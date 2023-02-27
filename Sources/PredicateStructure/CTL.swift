/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
///   TODO: Replace all 'let ps = PredicateStructure(ps: .empty, petrinet: petrinet)' by a true structure for SPS to avoid this horrible trick
indirect enum CTL {
  
  typealias SPS = Set<PS>
  typealias PN = PetriNet
  typealias PlaceType = String
  typealias TransitionType = String
  
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
    let ps = PS(ps: nil, petrinet: petrinet)
    switch self {
    case .ap(let t):
      return [
        PS(ps: ([petrinet.inputMarkingForATransition(transition: t)], []), petrinet: petrinet)
      ]
    case .after(let t):
      return [
        PS(ps:  ([], [petrinet.outputMarkingForATransition(transition: t)]), petrinet: petrinet)
      ]
    case .true:
      var dicEmptyMarking: [PlaceType: Int] = [:]
      for place in petrinet.places {
        dicEmptyMarking[place] = 0
      }
      return [
        PS(ps: ([Marking(storage: dicEmptyMarking, petrinet: petrinet)], []), petrinet: petrinet)
      ]
    case .and(let ctl1, let ctl2):
      return ps.intersection(sps1: ctl1.eval(petrinet: petrinet), sps2: ctl2.eval(petrinet: petrinet))
    case .not(let ctl1):
      return ps.notSPS(sps: ctl1.eval(petrinet: petrinet))
    case .EX(let ctl1):
      return ps.revert(sps: ctl1.eval(petrinet: petrinet))
    case .AX(let ctl1):
      return ps.revertTilde(sps: ctl1.eval(petrinet: petrinet))
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
    let ps = PS(ps: nil, petrinet: petrinet)
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.union(sps1: res, sps2: ps.revert(sps: res))
    } while !ps.isIncluded(sps1: res, sps2: resTemp)
    return res
  }
  
  func evalAF(petrinet: PN) -> SPS {
    let ps = PS(ps: nil, petrinet: petrinet)
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.union(
        sps1: res,
        sps2: ps.intersection(
          sps1: ps.revert(sps: res),
          sps2: ps.revertTilde(sps: res)
        )
      )
    } while !ps.isIncluded(sps1: res, sps2: resTemp)
    return res
  }
  
  func evalEG(petrinet: PN) -> SPS {
    let ps = PS(ps: nil, petrinet: petrinet)
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.intersection(
        sps1: res,
        sps2: ps.union(
          sps1: ps.revert(sps: res),
          sps2: ps.revertTilde(sps: res)
        )
      )
    } while !ps.isIncluded(sps1: resTemp, sps2: res)
    return res
  }
  
  func evalAG(petrinet: PN) -> SPS {
    let ps = PS(ps: nil, petrinet: petrinet)
    var res = self.eval(petrinet: petrinet)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.intersection(sps1: res, sps2: ps.revertTilde(sps: res))
    } while !ps.isIncluded(sps1: resTemp, sps2: res)
    return res
  }
  
  func evalEU(ctl: CTL, petrinet: PN) -> SPS {
    let ps = PS(ps: nil, petrinet: petrinet)
    let phi = self.eval(petrinet: petrinet)
    var res = ctl.eval(petrinet: petrinet)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.union(
        sps1: res,
        sps2: ps.intersection(
          sps1: phi,
          sps2: ps.revert(sps: res)
        )
      )
    } while !ps.isIncluded(sps1: res, sps2: resTemp)
    return res
  }
  
  func evalAU(ctl: CTL, petrinet: PN) -> SPS {
    let ps = PS(ps: nil, petrinet: petrinet)
    let phi = self.eval(petrinet: petrinet)
    var res = ctl.eval(petrinet: petrinet)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.union(
        sps1: res,
        sps2: ps.intersection(
          sps1: phi,
          sps2: ps.intersection(
            sps1: ps.revert(sps: res),
            sps2: ps.revertTilde(sps: res))
        )
      )
    } while !ps.isIncluded(sps1: res, sps2: resTemp)
    return res
  }

}
