/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
///   TODO: Replace all 'let ps = PredicateStructure(ps: .empty, net: net)' by a true structure for SPS to avoid this horrible trick
indirect enum CTL {
  
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
      return ctl1.eval(net: net).intersection(ctl2.eval(net: net))
    case .not(let ctl1):
      return ctl1.eval(net: net).not()
    case .EX(let ctl1):
      return ctl1.eval(net: net).revert()
    case .AX(let ctl1):
      return ctl1.eval(net: net).revertTilde()
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
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert())
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalAF(net: PN) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde()))
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalEG(net: PN) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde()))
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalAG(net: PN) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revertTilde())
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalEU(ctl: CTL, net: PN) -> SPS {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(phi.intersection(res.revert()))
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalAU(ctl: CTL, net: PN) -> SPS {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde())))
    } while !res.isIncluded(resTemp)
    return res
  }

}
