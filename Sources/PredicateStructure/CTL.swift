/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
public indirect enum CTL: Equatable {
    
  /// Enum that lists the accepted operators for a cardinality formula
  public enum Operator: CustomStringConvertible {
    case lt
    case leq
    // Other operators that could be implemented:
    // case gt
    // case geq
    // case eq
    // case neq
    public var description: String {
      switch self {
      case .lt:
        return "<"
      case .leq:
        return "≤"
      }
    }

  }
  
  /// Enum that lists the accepted expressions for a cardinality formula
  public indirect enum Expression: Equatable, CustomStringConvertible {
    case tokenCount(String)
    case value(Int)
    case add(Expression, Expression)
    case sub(Expression, Expression)
    case mul(Expression, Expression)
    public var description: String {
      switch self {
      case .tokenCount(let s):
        return "tokenCount(\(s))"
      case .value(let i):
        return i.description
      case .add(let e1, let e2):
        return "\(e1) + \(e2)"
      case .sub(let e1, let e2):
        return "\(e1) - \(e2)"
      case .mul(let e1, let e2):
        return "\(e1) * \(e2)"
      }
    }
  }
    
  // Basic case
  case deadlock
  case isFireable(String)
  case intExpr(e1: Expression, operator: Operator, e2: Expression)
  case after(String)
  // Boolean logic
  case `true`
  case `false`
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
    case .intExpr(e1: _, operator: _, e2: _):
      return evalCardinality(net: net)
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
      res = [
        PS(value: ([net.zeroMarking()], []), net: net)
      ]
    case .false:
      res = []
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
      res = ctl1.evalEF(net: net, rewrited: rewrited, simplified: simplified)
    case .AF(let ctl1):
      res = ctl1.evalAF(net: net, rewrited: rewrited, simplified: simplified)
    case .EG(let ctl1):
      res = ctl1.evalEG(net: net, rewrited: rewrited, simplified: simplified)
    case .AG(let ctl1):
      res = ctl1.evalAG(net: net, rewrited: rewrited, simplified: simplified)
    case .EU(let ctl1, let ctl2):
      res = ctl1.evalEU(ctl: ctl2, net: net, rewrited: rewrited, simplified: simplified)
    case .AU(let ctl1, let ctl2):
      res = ctl1.evalAU(ctl: ctl2, net: net, rewrited: rewrited, simplified: simplified)
    }
    
    if simplified {
      return res.simplified()
    }
    return res
  }
  
  /// Encode a cardinality formula into a SPS that represents all markings satisfying the condition.
  /// - Parameter net: The corresponding net
  /// - Returns: The resulting set of predicate structures
  func evalCardinality(net: PetriNet) -> SPS {
    switch self {
    case .intExpr(e1: .value(_), operator: _, e2: .value(_)):
      return CTL.true.eval(net: net)
    case .intExpr(e1: .tokenCount(_), operator: _, e2: .tokenCount(_)):
      fatalError("The tool does not manage a cardinality comparison between places")
    case .intExpr(e1: let e1, operator: .leq, e2: let e2):
      return CTL.evalLeq(e1: e1, e2: e2, net: net)
    case .intExpr(e1: let e1, operator: .lt, e2: let e2):
      return CTL.evalLt(e1: e1, e2: e2, net: net)
    default:
      fatalError("This is not possible")
    }
  }
  
  /// Evaluate a "less than or equal to" expression and it creates the equivalent set of predicate structures which satisfies the condition.
  ///  e.g.: `p1 ≤ 2`, `3 ≤ p2`
  /// - Parameters:
  ///   - e1: First expression
  ///   - e2: Second expression
  ///   - net: The corresponding Petri net
  /// - Returns: The set of predicate structures that encodes all markings that satisfy the condition
  static func evalLeq(e1: Expression, e2: Expression, net: PetriNet) -> SPS {
    var marking = net.zeroMarking()
    switch (e1, e2) {
    // i <= p
    case (.value(let i), .tokenCount(let p)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i
      return [PS(value: ([marking],[]), net: net)]
    // p <= i
    case (.tokenCount(let p), .value(let i)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i+1
      return [PS(value: ([],[marking]), net: net)]
    default:
      fatalError("Operators are not managed yet. They cannot be evaluated")
    }
  }
  
  /// Evaluate a "less than expression and it creates the equivalent set of predicate structures which satisfies the condition.
  ///  e.g.: `p1 < 2`, `3 < p2`
  /// - Parameters:
  ///   - e1: First expression
  ///   - e2: Second expression
  ///   - net: The corresponding Petri net
  /// - Returns: The set of predicate structures that encodes all markings that satisfy the condition
  static func evalLt(e1: Expression, e2: Expression, net: PetriNet) -> SPS {
    var marking = net.zeroMarking()
    switch (e1, e2) {
    // i < p
    case (.value(let i), .tokenCount(let p)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i+1
      return [PS(value: ([marking],[]), net: net)]
    // p < i
    case (.tokenCount(let p), .value(let i)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i
      return [PS(value: ([],[marking]), net: net)]
    default:
      fatalError("Operators are not managed yet. They cannot be evaluated")
    }
  }
  
  
  
  func evalEF(net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    var resTemp: SPS
    repeat {
      resTemp = res
      res = res.union(res.revert())
      if simplified {
        res = res.simplified()
      }
    } while !SPS(values: Set(res.filter({!resTemp.contains($0)}))).isIncluded(resTemp)
    return res
  }
  
  func evalAF(net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
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
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
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
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
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
  
  func evalEU(ctl: CTL, net: PetriNet, rewrited: Bool, simplified: Bool) -> SPS {
    let phi = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    var res = ctl.eval(net: net, rewrited: rewrited, simplified: simplified)
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
    let phi = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    var res = ctl.eval(net: net, rewrited: rewrited, simplified: simplified)
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
  
  /// Reduce a query using some rewriting on CTL formulas. Using rewriting theories of the paper: Simplification of CTL Formulae
  /// for Efficient Model Checking of Petri Nets from Frederik Bønneland & al. .
  /// - Returns: The reduced query
  public func queryReduction() -> CTL {
    switch self {
    case .intExpr(e1: _, operator: _, e2: _):
      return self
    case .deadlock:
      return .deadlock
    case .isFireable(_):
      return self
    case .true:
      return .true
    case .false:
      return .false
    case .after(_):
      return self
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
    case .EF(_):
      return self.efReduction()
    case .AF(_):
      return self.afReduction()
    case .EG(let ctl):
      return .not(.AF(.not(ctl).queryReduction())).queryReduction()
    case .AG(let ctl):
      return .not(.EF(.not(ctl).queryReduction())).queryReduction()
    case .EU(_, _):
      return self.euReduction()
    case .AU(_, _):
      return self.auReduction()
    }
  }
  
  public func notReduction() -> CTL {
    switch self {
    case .not(let ctl):
      switch ctl {
      case .not(let ctl1):
        return ctl1.queryReduction()
      case .EX(let ctl1):
        return .AX(.not(ctl1)).queryReduction()
      case .AX(let ctl1):
        return .EX(.not(ctl1)).queryReduction()
      case .or(let ctl1, let ctl2):
        return .and(.not(ctl1), .not(ctl2)).queryReduction()
      case .and(let ctl1, let ctl2):
        return .or(.not(ctl1), .not(ctl2)).queryReduction()
      case .EF(let ctl1):
        return .AG(.not(ctl1).queryReduction())
      case .AF(let ctl1):
        return .EG(.not(ctl1).queryReduction())
      case .EG(let ctl1):
        return .AF(.not(ctl1).queryReduction())
      case .AG(let ctl1):
        return .EF(.not(ctl1).queryReduction())
      default:
        return .not(ctl.queryReduction())
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  public func efReduction() -> CTL {
    switch self {
    case .EF(let ctl):
      switch ctl {
      case .not(.deadlock):
        return .not(.deadlock)
      case .EF(let ctl1):
        return .EF(ctl1)
      case .AF(let ctl1):
        return .EF(ctl1).queryReduction()
      case .EU(_, let ctl2):
        return .EF(ctl2).queryReduction()
      case .AU(_, let ctl2):
        return .EF(ctl2).queryReduction()
      case .or(let ctl1, let ctl2):
        return .or(.EF(ctl1), .EF(ctl2)).queryReduction()
      default:
        return .EF(ctl.queryReduction())
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  public func afReduction() -> CTL {
    switch self {
    case .AF(let ctl):
      let ctlReduced = ctl.queryReduction()
      switch ctlReduced {
      case .not(.deadlock):
        return .not(.deadlock)
      case .EF(let ctl1):
        return .EF(ctl1)
      case .AF(let ctl1):
        return .AF(ctl1)
      case .AU(_, let ctl2):
        return .AF(ctl2).queryReduction()
      case .or(let ctl1, .EF(let ctl2)):
        return .or(.EF(ctl2), .AF(ctl1)).queryReduction()
      default:
        return .AF(ctl.queryReduction())
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  public func auReduction() -> CTL {
    switch self {
    case .AU(let ctl1, let ctl2):
      switch (ctl1, ctl2) {
      case (_, .not(.deadlock)):
        return .not(.deadlock)
      case (.deadlock, _):
        return ctl2.queryReduction()
      case (.not(.deadlock), _):
        return .AF(ctl2).queryReduction()
      case (_, .EF(let ctl3)):
        return .AF(ctl3)
      case (_, .or(let ctl3, .EF(let ctl4))):
        return .or(.EF(ctl4), .AU(ctl1, ctl3)).queryReduction()
      default:
        return .AU(ctl1.queryReduction(), ctl2.queryReduction())
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  public func euReduction() -> CTL {
    switch self {
    case .EU(let ctl1, let ctl2):
      switch (ctl1, ctl2) {
      case (_, .not(.deadlock)):
        return .not(.deadlock)
      case (.deadlock, let ctl2):
        return ctl2.queryReduction()
      case (.not(.deadlock), _):
        return .EF(ctl2).queryReduction()
      case (_, .EF(let ctl3)):
        return .EF(ctl3)
      case (_, .or(let ctl3, .EF(let ctl4))):
        return .or(.EF(ctl4), .EU(ctl1, ctl3)).queryReduction()
      default:
        return .EU(ctl1.queryReduction(), ctl2.queryReduction())
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  
  /// Count the number of elements of a CTL formula
  /// - Returns: The number of elements of the CTL formula
  public func count() -> Int {
    switch self {
    case .intExpr(e1: _, operator: _, e2: _):
      return 1
    case .deadlock:
      return 1
    case .isFireable(_):
      return 1
    case .true:
      return 1
    case .false:
      return 1
    case .after(_):
      return 1
    case .not(let ctl):
      return 1 + ctl.count()
    case .and(let ctl1, let ctl2):
      return 2 + ctl1.count() + ctl2.count()
    case .or(let ctl1, let ctl2):
      return 2 + ctl1.count() + ctl2.count()
    case .EX(let ctl):
      return 1 + ctl.count()
    case .AX(let ctl):
      return 1 + ctl.count()
    case .EF(let ctl):
      return 1 + ctl.count()
    case .AF(let ctl):
      return 1 + ctl.count()
    case .EG(let ctl):
      return 1 + ctl.count()
    case .AG(let ctl):
      return 1 + ctl.count()
    case .EU(let ctl1, let ctl2):
      return 2 + ctl1.count() + ctl2.count()
    case .AU(let ctl1, let ctl2):
      return 2 + ctl1.count() + ctl2.count()
    }
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
    case .intExpr(e1: _, operator: _, e2: _):
      return evalCardinality(net: net).contains(marking: marking)
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
    case .false:
      return false
    case .and(let ctl1, let ctl2):
      let evalCTL1 = ctl1.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
      if evalCTL1 == false {
        return false
      }
      return ctl2.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .or(let ctl1, let ctl2):
      let evalCTL1 = ctl1.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
      if evalCTL1 == true {
        return true
      }
      return (ctl2.eval(marking: marking, net: net, rewrited: rewrited, simplified: simplified))
    case .not(let ctl1):
      return ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).not().contains(marking: marking)
    case .deadlock:
      return SPS.deadlock(net: net).contains(marking: marking)
    case .EX(let ctl1):
      if SPS.deadlock(net: net).contains(marking: marking) {
        return false
      }
      return ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).revert().contains(marking: marking)
    case .AX(let ctl1):
      if SPS.deadlock(net: net).contains(marking: marking) {
        return true
      }
      return ctl1.eval(net: net, rewrited: rewrited, simplified: simplified).revertTilde(rewrited: rewrited).contains(marking: marking)
    case .EF(let ctl1):
      return ctl1.evalEF(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .AF(let ctl1):
      return ctl1.evalAF(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .EG(let ctl1):
      return ctl1.evalEG(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .AG(let ctl1):
      return ctl1.evalAG(marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .EU(let ctl1, let ctl2):
      return ctl1.evalEU(ctl: ctl2, marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    case .AU(let ctl1, let ctl2):
      return ctl1.evalAU(ctl: ctl2, marking: marking, net: net, rewrited: rewrited, simplified: simplified)
    }
    
  }

  func evalEF(marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    if res.contains(marking: marking) == true {
      return true
    }
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
    } while !SPS(values: Set(res.filter({!resTemp.contains($0)}))).isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAF(marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    if res.contains(marking: marking) == true {
      return true
    }
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      // We do not need to apply the union with res, because we are looking for a predicate structure that includes our marking.
      // Thus, if a predicate structure is not valid, we just use it to compute the revert and do not reinsert it.
      res = res.union(res.revert().intersection(res.revertTilde(rewrited: rewrited)))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalEG(marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    var res = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    if res.contains(marking: marking) == false {
      return false
    }
    
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
    if res.contains(marking: marking) == false {
      return false
    }
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
  
  func evalEU(ctl: CTL, marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    let phi = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    let isPhiContained = phi.contains(marking: marking)
    if  isPhiContained == true {
      return true
    }
    var res = ctl.eval(net: net, rewrited: rewrited, simplified: simplified)
    if isPhiContained == false && res.contains(marking: marking) == false {
      return false
    }
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      // We do not need to apply the union with res, because we are looking for a predicate structure that includes our marking.
      // Thus, if a predicate structure is not valid, we just use it to compute the revert and do not reinsert it.
      res = res.union(phi.intersection(res.revert()))
      if simplified {
        res = res.simplified()
      }
    } while !res.isIncluded(resTemp)
    return res.contains(marking: marking)
  }
  
  func evalAU(ctl: CTL, marking: Marking, net: PetriNet, rewrited: Bool, simplified: Bool) -> Bool {
    let phi = self.eval(net: net, rewrited: rewrited, simplified: simplified)
    var res = ctl.eval(net: net, rewrited: rewrited, simplified: simplified)
    var resTemp: SPS
    repeat {
      if res.contains(marking: marking) {
        return true
      }
      resTemp = res
      // We do not need to apply the union with res, because we are looking for a predicate structure that includes our marking.
      // Thus, if a predicate structure is not valid, we just use it to compute the revert and do not reinsert it.
      res = res.union(phi.intersection(res.revert().intersection(res.revertTilde(rewrited: rewrited))))
      if simplified {
        res = res.simplified()
      }
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
    case .false:
      res = "false"
    case .isFireable(let s):
      res = "isFireable(\(s))"
    case .intExpr(e1: let e1, operator: let op, e2: let e2):
      res = "\(e1) \(op) \(e2)"
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
      res = "E(\(ctl1)) U (\(ctl2))"
    case .AU(let ctl1, let ctl2):
      res = "A(\(ctl1)) U (\(ctl2))"
    }
    return res
  }
}
