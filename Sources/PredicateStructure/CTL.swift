/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
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
  
  public func eval(net: PetriNet, rewrited: Bool = false) -> SPS {
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
      return SPS.deadlock(net: net)
    case .EX(let ctl1):
      return ctl1.eval(net: net).revert()
    case .AX(let ctl1):
      return ctl1.eval(net: net).revertTilde(rewrited: rewrited)
    case .EF(let ctl1):
      return ctl1.evalEF(net: net)
    case .AF(let ctl1):
      return ctl1.evalAF(net: net, rewrited: rewrited)
    case .EG(let ctl1):
      return ctl1.evalEG(net: net, rewrited: rewrited)
    case .AG(let ctl1):
      return ctl1.evalAG(net: net, rewrited: rewrited)
    case .EU(let ctl1, let ctl2):
      return ctl1.evalEU(ctl: ctl2, net: net)
    case .AU(let ctl1, let ctl2):
      return ctl1.evalAU(ctl: ctl2, net: net, rewrited: rewrited)
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
  
  func evalAF(net: PetriNet, rewrited: Bool = false) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde(rewrited: rewrited)))
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalEG(net: PetriNet, rewrited: Bool = false) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde(rewrited: rewrited)))
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalAG(net: PetriNet, rewrited: Bool = false) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revertTilde(rewrited: rewrited))
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
  
  func evalAU(ctl: CTL, net: PetriNet, rewrited: Bool = false) -> SPS {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde(rewrited: rewrited))))
    } while !res.isIncluded(resTemp)
    return res
  }

}

// Specific case of CTL where a marking is given
extension CTL {
  public func eval(marking: Marking, net: PetriNet, rewrited: Bool = false) -> Bool {
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
      return ctl1.eval(net: net).revertTilde(rewrited: rewrited).contains(marking: marking)
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
//      print(res.count)
//      print(res)
      resTemp = res
      res = res.union(res.revert()).simplified()
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAF(marking: Marking, net: PetriNet, rewrited: Bool = false) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde(rewrited: rewrited)))
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalEG(marking: Marking, net: PetriNet, rewrited: Bool = false) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if !res.contains(marking: marking) {
        return false
      }
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde(rewrited: rewrited)))
    } while !resTemp.isIncluded(res)
    return res.contains(marking: marking)
  }
  
  func evalAG(marking: Marking, net: PetriNet, rewrited: Bool = false) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if !res.contains(marking: marking) {
        return false
      }
      resTemp = res
      res = res.intersection(res.revertTilde(rewrited: rewrited))
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
  
  func evalAU(ctl: CTL, marking: Marking, net: PetriNet, rewrited: Bool = false) -> Bool {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde(rewrited: rewrited))))
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
}

extension CTL: CustomStringConvertible {
  public var description: String {
    var res: String = ""
    switch self {
    case .true:
      res = "true"
    case .ap(let s):
      res = s
    case .after(let s):
      res = "after(\(s))"
    case .deadlock:
      res = "deadlock"
    case .not(let ctl):
      res = "not(\(ctl))"
    case .and(let ctl1, let ctl2):
      res = "and(\(ctl1), \(ctl2))"
    case .or(let ctl1, let ctl2):
      res = "or(\(ctl1), \(ctl2))"
    case .EX(let ctl):
      res = "EX(\(ctl))"
    case .AX(let ctl):
      res = "AX(\(ctl))"
    case .EF(let ctl):
      res = "EF(\(ctl))"
    case .AF(let ctl):
      res = "AF(\(ctl))"
    case .EG(let ctl):
      res = "EG(\(ctl))"
    case .AG(let ctl):
      res = "AG(\(ctl))"
    case .EU(let ctl1, let ctl2):
      res = "E(\(ctl1) U \(ctl2))"
    case .AU(let ctl1, let ctl2):
      res = "E(\(ctl1) U \(ctl2))"
    }
    return res
  }
}
