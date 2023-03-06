/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
///   TODO: Replace all 'let ps = PredicateStructure(ps: .empty, net: net)' by a true structure for SPS to avoid this horrible trick
public indirect enum CTL {
    
  // Basic case
  case deadlock
  case ap(String)
  case after(String)
  // Boolean logic
  case `true`
  case and(CTL, CTL)
  case or(CTL, CTL)
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
  
  public func eval(net: PetriNet) -> SPS {
    switch self {
    case .ap(let t):
      if net.transitions.contains(t) {
        return [
          PS(value: ([net.inputMarkingForATransition(transition: t)], []), net: net)
        ]
      } else {
        fatalError("Unknown transition")
      }
    case .after(let t):
      if net.transitions.contains(t) {
        return [
          PS(value:  ([], [net.outputMarkingForATransition(transition: t)]), net: net)
        ]
      } else {
        fatalError("Unknown transition")
      }
    case .true:
      var dicEmptyMarking: [String: Int] = [:]
      for place in net.places {
        dicEmptyMarking[place] = 0
      }
      return [
        PS(value: ([Marking(dicEmptyMarking, net: net)], []), net: net)
      ]
    case .and(let ctl1, let ctl2):
      return ctl1.eval(net: net).intersection(ctl2.eval(net: net))
    case .or(let ctl1, let ctl2):
      return ctl1.eval(net: net).union(ctl2.eval(net: net))
    case .not(let ctl1):
      return ctl1.eval(net: net).not()
    case .deadlock:
      if let tFirst = net.transitions.first {
        var translated : CTL = .ap(tFirst)
        for transition in net.transitions.subtracting([tFirst]) {
          translated = .or(translated, .ap(transition))
        }
        translated = .not(translated)
        return translated.eval(net: net)
      }
      return []
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

  func evalEF(net: PetriNet) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      print(res.count)
      print(res)
      resTemp = res
      res = res.union(res.revert()).simplified()
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalAF(net: PetriNet) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde()))
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalEG(net: PetriNet) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde()))
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalAG(net: PetriNet) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revertTilde())
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalEU(ctl: CTL, net: PetriNet) -> SPS {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(phi.intersection(res.revert()))
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalAU(ctl: CTL, net: PetriNet) -> SPS {
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

// Specific case of CTL where a marking is given
extension CTL {
  public func eval(marking: Marking, net: PetriNet) -> Bool {
    switch self {
    case .ap(let t):
      if net.transitions.contains(t) {
        return
          PS(value: ([net.inputMarkingForATransition(transition: t)], []), net: net).contains(marking: marking)
      } else {
        fatalError("Unknown transition")
      }
    case .after(let t):
      if net.transitions.contains(t) {
        return PS(value:  ([], [net.outputMarkingForATransition(transition: t)]), net: net).contains(marking: marking)
      } else {
        fatalError("Unknown transition")
      }
    case .true:
      return true
    case .and(let ctl1, let ctl2):
      return ctl1.eval(marking: marking, net: net) && (ctl2.eval(marking: marking, net: net))
    case .or(let ctl1, let ctl2):
      return ctl1.eval(marking: marking, net: net) || (ctl2.eval(marking: marking, net: net))
    case .not(let ctl1):
      return ctl1.eval(net: net).not().contains(marking: marking)
    case .deadlock:
      if let tFirst = net.transitions.first {
        var translated : CTL = .ap(tFirst)
        for transition in net.transitions.subtracting([tFirst]) {
          translated = .or(translated, .ap(transition))
        }
        translated = .not(translated)
        return translated.eval(net: net).contains(marking: marking)
      }
      return true
    case .EX(let ctl1):
      return ctl1.eval(net: net).revert().contains(marking: marking)
    case .AX(let ctl1):
      return ctl1.eval(net: net).revertTilde().contains(marking: marking)
    case .EF(let ctl1):
      return ctl1.evalEF(marking: marking, net: net)
    case .AF(let ctl1):
      return ctl1.evalAF(marking: marking, net: net)
    case .EG(let ctl1):
      return ctl1.evalEG(marking: marking, net: net)
    case .AG(let ctl1):
      return ctl1.evalAG(marking: marking, net: net)
    case .EU(let ctl1, let ctl2):
      return ctl1.evalEU(ctl: ctl2, marking: marking, net: net)
    case .AU(let ctl1, let ctl2):
      return ctl1.evalAU(ctl: ctl2, marking: marking, net: net)
    }
    
  }

  func evalEF(marking: Marking, net: PetriNet) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      print(res.count)
      print(res)
      resTemp = res
      res = res.union(res.revert()).simplified()
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAF(marking: Marking, net: PetriNet) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde()))
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalEG(marking: Marking, net: PetriNet) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if !res.contains(marking: marking) {
        return false
      }
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde()))
    } while !resTemp.isIncluded(res)
    return res.contains(marking: marking)
  }
  
  func evalAG(marking: Marking, net: PetriNet) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if !res.contains(marking: marking) {
        return false
      }
      resTemp = res
      res = res.intersection(res.revertTilde())
    } while !resTemp.isIncluded(res)
    return res.contains(marking: marking)
  }
  
  func evalEU(ctl: CTL, marking: Marking, net: PetriNet) -> Bool {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(phi.intersection(res.revert()))
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAU(ctl: CTL, marking: Marking, net: PetriNet) -> Bool {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde())))
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
}
