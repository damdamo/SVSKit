/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
///   TODO: Replace all 'let ps = PredicateStructure(ps: .empty, net: net)' by a true structure for SPS to avoid this horrible trick
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
  
  func eval(net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    switch self {
    case .ap(let t):
      return [
        PS(ps: ([net.inputMarkingForATransition(transition: t)], []), net: net)
      ]
    case .after(let t):
      return [
        PS(ps:  ([], [net.outputMarkingForATransition(transition: t)]), net: net)
      ]
    case .true:
      var dicEmptyMarking: [PlaceType: Int] = [:]
      for place in net.places {
        dicEmptyMarking[place] = 0
      }
      return [
        PS(ps: ([Marking(dicEmptyMarking, net: net)], []), net: net)
      ]
    case .and(let ctl1, let ctl2):
      return ps.intersection(sps1: ctl1.eval(net: net), sps2: ctl2.eval(net: net))
    case .not(let ctl1):
      return ps.not(sps: ctl1.eval(net: net))
    case .EX(let ctl1):
      return ps.revert(sps: ctl1.eval(net: net))
    case .AX(let ctl1):
      return ps.revertTilde(sps: ctl1.eval(net: net))
    case .EF(let ctl1):
      return ctl1.evalEF(net: net)
    case .AF(let ctl1):
      return ctl1.evalAF(net: net)
    case .EG(let ctl1):
      return ctl1.evalEG(net: net)
    case .AG(let ctl1):
      return ctl1.evalAG(net: net)
    case .EU(let ctl1, let ctl2):
      return ctl1.evalEU(ctl: ctl2, net: net)
    case .AU(let ctl1, let ctl2):
      return ctl1.evalAU(ctl: ctl2, net: net)
    }
    
  }

  func evalEF(net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    var res = self.eval(net: net)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.union(sps1: res, sps2: ps.revert(sps: res))
    } while !ps.isIncluded(sps1: res, sps2: resTemp)
    return res
  }
  
  func evalAF(net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    var res = self.eval(net: net)
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
  
  func evalEG(net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    var res = self.eval(net: net)
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
  
  func evalAG(net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    var res = self.eval(net: net)
    var resTemp: SPS = []
    repeat {
      resTemp = res
      res = ps.intersection(sps1: res, sps2: ps.revertTilde(sps: res))
    } while !ps.isIncluded(sps1: resTemp, sps2: res)
    return res
  }
  
  func evalEU(ctl: CTL, net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
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
  
  func evalAU(ctl: CTL, net: PN) -> SPS {
    let ps = PS(ps: nil, net: net)
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
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
