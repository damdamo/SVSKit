/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
public indirect enum CTL {
    
  // Basic case
  case deadlock
  case isFireable(String)
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
  
  /// Evaluate a CTL formula to find all markings that satisfy it.
  /// - Parameters:
  ///   - net: The current Petri net
  ///   - rewrited: An option to specify how to compute the function revertTilde. If it is true, we rewrite revertTilde as `not revert not`. When it is false, we use a specific function to compute it. False by default.
  ///   - simplified: An option to specify if there simplified function must be used or not. True by default.
  /// - Returns: A set of predicate structures that symbolically represents all markings that satisfy the CTL formula.
  public func eval(net: PetriNet, rewrited: Bool = false, simplified: Bool = true) -> SPS {
    var res: SPS
    switch self {
    case .isFireable(let t):
      if net.transitions.contains(t) {
        res = [
          PS(value: ([net.inputMarkingForATransition(transition: t)], []), net: net)
        ]
      } else {
        fatalError("Unknown transition")
      }
    case .after(let t):
      if net.transitions.contains(t) {
        res = [
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
      res = [
        PS(value: ([Marking(dicEmptyMarking, net: net)], []), net: net)
      ]
    case .and(let ctl1, let ctl2):
      res = ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).intersection(ctl2.eval(net: net, rewrited: rewrited, simplified: simplified))
    case .or(let ctl1, let ctl2):
      res = ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).union(ctl2.eval(net: net, rewrited: rewrited, simplified: simplified))
    case .not(let ctl1):
      res = ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).not()
    case .deadlock:
      res = SPS.deadlock(net: net)
    case .EX(let ctl1):
      res = ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).revert()
    case .AX(let ctl1):
      res = ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).revertTilde(rewrited: rewrited)
    case .EF(let ctl1):
      res = ctl1.evalEF(net: net, simplified: simplified)
    case .AF(let ctl1):
      res = ctl1.evalAF(net: net, rewrited: rewrited, simplified: simplified)
    case .EG(let ctl1):
      res = ctl1.evalEG(net: net, rewrited: rewrited, simplified: simplified)
    case .AG(let ctl1):
      res = ctl1.evalAG(net: net, rewrited: rewrited, simplified: simplified)
    case .EU(let ctl1, let ctl2):
      res = ctl1.evalEU(ctl: ctl2, net: net, simplified: simplified)
    case .AU(let ctl1, let ctl2):
      res = ctl1.evalAU(ctl: ctl2, net: net, rewrited: rewrited, simplified: simplified)
    }
    
    if simplified {
      return res.simplified()
    }
    return res
  }
  
  func evalEF(net: PetriNet, simplified: Bool) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert())
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalAF(net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde(rewrited: rewrited)))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalEG(net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde(rewrited: rewrited)))
      if simplified {
        res = res.simplified()
      }
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalAG(net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.intersection(res.revertTilde(rewrited: rewrited))
      if simplified {
        res = res.simplified()
      }
    } while !resTemp.isIncluded(res)
    return res
  }
  
  func evalEU(ctl: CTL, net: PetriNet, simplified: Bool) -> SPS {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(phi.intersection(res.revert()))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res
  }
  
  func evalAU(ctl: CTL, net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde(rewrited: rewrited))))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res
  }

}

// Specific case of CTL where a marking is given
extension CTL {
  /// Evaluate a CTL formula for a given marking
  /// - Parameters:
  ///   - marking: The marking to check
  ///   - net: The current Petri net
  ///   - rewrited: An option to specify how to compute the function revertTilde. If it is true, we rewrite revertTilde as `not revert not`. When it is false, we use a specific function to compute it. False by default.
  ///   - simplified: An option to specify if there simplified function must be used or not. True by default.
  /// - Returns: True if the marking holds the CTL formula
  public func eval(marking: Marking, net: PetriNet, rewrited: Bool = false, simplified: Bool = true) -> Bool {
    switch self {
    case .isFireable(let t):
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
      return ctl1.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified) && (ctl2.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified))
    case .or(let ctl1, let ctl2):
      return ctl1.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified) || (ctl2.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified))
    case .not(let ctl1):
      return ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).not().contains(marking: marking)
    case .deadlock:
      return SPS.deadlock(net: net).contains(marking: marking)
    case .EX(let ctl1):
      return ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).revert().contains(marking: marking)
    case .AX(let ctl1):
      return ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).revertTilde(rewrited: rewrited).contains(marking: marking)
    case .EF(let ctl1):
      return ctl1.evalEF(marking: marking, net: net, simplified: simplified)
    case .AF(let ctl1):
      return ctl1.evalAF(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .EG(let ctl1):
      return ctl1.evalEG(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .AG(let ctl1):
      return ctl1.evalAG(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .EU(let ctl1, let ctl2):
      return ctl1.evalEU(ctl: ctl2, marking: marking, net: net, simplified: simplified)
    case .AU(let ctl1, let ctl2):
      return ctl1.evalAU(ctl: ctl2, marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    }
    
  }

  func evalEF(marking: Marking, net: PetriNet, simplified: Bool) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(res.revert())
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAF(marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(res.revert().intersection(res.revertTilde(rewrited: rewrited)))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalEG(marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if !res.contains(marking: marking) {
        return false
      }
      resTemp = res
      res = res.intersection(res.revert().union(res.revertTilde(rewrited: rewrited)))
      if simplified {
        res = res.simplified()
      }
    } while !resTemp.isIncluded(res)
    return res.contains(marking: marking)
  }
  
  func evalAG(marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    var res = self.eval(net: net)
    var resTemp: SPS
    repeat {
      if !res.contains(marking: marking) {
        return false
      }
      resTemp = res
      res = res.intersection(res.revertTilde(rewrited: rewrited))
      if simplified {
        res = res.simplified()
      }
    } while !resTemp.isIncluded(res)
    return res.contains(marking: marking)
  }
  
  func evalEU(ctl: CTL, marking: Marking, net: PetriNet, simplified: Bool) -> Bool {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(phi.intersection(res.revert()))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAU(ctl: CTL, marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    let phi = self.eval(net: net)
    var res = ctl.eval(net: net)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde(rewrited: rewrited))))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  /// Reduce a query using some rewriting on CTL formulas.
  /// - Returns: The reduced query
  public func queryReduction() -> CTL {
    switch self {
    case .not(_):
      return self.notReduction()
    case .and(let ctl1, let ctl2):
      return .and(ctl1.queryReduction(), ctl2.queryReduction())
    case .or(let ctl1, let ctl2):
      return .or(ctl1.queryReduction(), ctl2.queryReduction())
    case .EX(let ctl):
      return .EX(ctl.queryReduction())
    case .AX(let ctl):
      return .AX(ctl.queryReduction())
    case .EF(let ctl):
      return .EF(ctl.queryReduction())
    case .AF(let ctl):
      return .AF(ctl.queryReduction())
    case .EG(let ctl):
      return .EG(ctl.queryReduction())
    case .AG(let ctl):
      return .AG(ctl.queryReduction())
    case .EU(let ctl1, let ctl2):
      return .EU(ctl1.queryReduction(), ctl2.queryReduction())
    case .AU(let ctl1, let ctl2):
      return .AU(ctl1.queryReduction(), ctl2.queryReduction())
    default:
      return self
    }
  }
  
  public func notReduction() -> CTL {
    switch self {
    case .not(.AX(let ctl)):
      return .EX(.not(ctl)).queryReduction()
    case .not(.not(let ctl)):
      return ctl.queryReduction()
    case .not(let ctl):
      return .not(ctl.queryReduction())
    default:
      return self
    }
  }
  
}

extension CTL: CustomStringConvertible {
  public var description: String {
    var res: String = ""
    switch self {
    case .true:
      res = "true"
    case .isFireable(let s):
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
