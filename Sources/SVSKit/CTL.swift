/// The Computation tree logic (CTL), is a language to express temporal properties that must hold a model.
///  Semantics are often based on Kripke structures. However, the computation here is made on the fly and does not know the whole state space beforehand.
///   The strategy is to use the fixpoint to construct this state space, and thanks to monotonicity properties, the computation always finishes.
public struct CTL {
  
  /// CTL formula
  let formula: Formula
  /// Related Petri net
//  private static var netStatic: PetriNet? = nil
  /// Option to decide if the simplification function should be called during execution. It removes redundancy in svs and sv.
  /// Set to true
  private static var simplifiedStatic: Bool = true
  /// Option to print the state number in fixpoint loop.
  /// Set to false
  private static var debugStatic: Bool = false
  /// Option to sature each step of the fixed point computation using capacity of a PN.
  /// Instead of starting by computing the whole set, it will start by a cardinality one, then two, until reaching the current cardinality. It converges faster by creationg the set of solutions required at each step of the cardinality.
  private static var saturatedStatic: Bool = true
  
  private let canonicityLevel: CanonicityLevel
  
//  public var net: PetriNet {
//    return CTL.netStatic!
//  }
  public let net: PetriNet

  var simplified: Bool {
    return CTL.simplifiedStatic
  }
  var debug: Bool {
    return CTL.debugStatic
  }
  var saturated: Bool {
    return CTL.saturatedStatic
  }
  
  public init(formula: Formula, net: PetriNet, canonicityLevel: CanonicityLevel, simplified: Bool = true, saturated: Bool = true, debug: Bool = false) {
    self.formula = formula
    self.net = net
    CTL.simplifiedStatic = simplified
    CTL.debugStatic = debug
    CTL.saturatedStatic = saturated
    
    self.canonicityLevel = canonicityLevel
  }
  
  private init(formula: Formula, net: PetriNet, canonicityLevel: CanonicityLevel) {
    self.formula = formula
    self.net = net
    self.canonicityLevel = canonicityLevel
  }
    
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
  
  // Enum that list all CTL formulas
  public indirect enum Formula: Equatable, CustomStringConvertible {
    // Basic case
    case deadlock
    case isFireable(String)
    case intExpr(e1: Expression, operator: Operator, e2: Expression)
    case after(String)
    // Boolean logic
    case `true`
    case `false`
    case and(Formula, Formula)
    case or(Formula, Formula)
    case not(Formula)
    // CTL operators
    case EX(Formula)
    case EF(Formula)
    case EG(Formula)
    case EU(Formula, Formula)
    case AX(Formula)
    case AF(Formula)
    case AG(Formula)
    case AU(Formula, Formula)
    
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
      case .not(let formula):
        res = "not(\(formula))"
      case .and(let formula1, let formula2):
        res = "and(\(formula1), \(formula2))"
      case .or(let formula1, let formula2):
        res = "or(\(formula1), \(formula2))"
      case .EX(let formula):
        res = "EX(\(formula))"
      case .AX(let formula):
        res = "AX(\(formula))"
      case .EF(let formula):
        res = "EF(\(formula))"
      case .AF(let formula):
        res = "AF(\(formula))"
      case .EG(let formula):
        res = "EG(\(formula))"
      case .AG(let formula):
        res = "AG(\(formula))"
      case .EU(let formula1, let formula2):
        res = "E(\(formula1)) U (\(formula2))"
      case .AU(let formula1, let formula2):
        res = "A(\(formula1)) U (\(formula2))"
      }
      return res
    }
      
  }
  
  /// Evaluate a CTL formula to find all markings that satisfy it.
  /// - Parameters:
  ///   - net: The current Petri net
  ///   - rewrited: An option to specify how to compute the function revertTilde. If it is true, we rewrite revertTilde as `not revert not`. When it is false, we use a specific function to compute it. False by default.
  ///   - simplified: An option to specify if there simplified function must be used or not. True by default.
  /// - Returns: A symbolic vector set that symbolically represents all markings that satisfy the CTL formula.
  public func eval() -> SVS {
    var res: SVS
    switch formula {
    case .intExpr(e1: _, operator: _, e2: _):
      return evalCardinality()
    case .isFireable(let t):
      if net.transitions.contains(t) {
        res = [
          SV(value: ([net.inputMarkingForATransition(transition: t)], []), net: net)
        ]
      } else {
        fatalError("Unknown transition")
      }
    case .after(let t):
      if net.transitions.contains(t) {
        res = [
          SV(value:  ([], [net.outputMarkingForATransition(transition: t)]), net: net)
        ]
      } else {
        fatalError("Unknown transition")
      }
    case .true:
      res = [
        SV(value: ([net.zeroMarking()], []), net: net)
      ]
    case .false:
      res = []
    case .and(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.eval().intersection(ctl2.eval(), canonicityLevel: canonicityLevel)
      if debug {
        print("Predicate structure number after and: \(res.count)")
      }
    case .or(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel).eval()
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel).eval()
      res = ctl1.union(ctl2, canonicityLevel: canonicityLevel)
      if debug {
        print("Predicate structure number after or: \(res.count)")
      }
    case .not(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.eval().not(net: net, canonicityLevel: canonicityLevel)
      if debug {
        print("Predicate structure number after not: \(res.count)")
      }
    case .deadlock:
      res = SVS.deadlock(net: net)
    case .EX(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.eval().revert(canonicityLevel: canonicityLevel, capacity: net.capacity)
      if debug {
        print("Predicate structure number after EX: \(res.count)")
      }
    case .AX(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.eval().revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: net.capacity)
      if debug {
        print("Predicate structure number after AX: \(res.count)")
      }
    case .EF(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.evalEF()
    case .AF(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.evalAF()
    case .EG(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.evalEG()
    case .AG(let formula):
      let ctl1 = CTL(formula: formula, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.evalAG()
    case .EU(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.evalEU(ctl2)
    case .AU(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      res = ctl1.evalAU(ctl2)
    }
    
    if simplified {
      return res.simplified()
    }
    return res
  }
  
  /// Encode a cardinality formula into a SVS that represents all markings satisfying the condition.
  /// - Parameter net: The corresponding net
  /// - Returns: The resulting symbolic vector set
  func evalCardinality() -> SVS {
    switch formula {
    case .intExpr(e1: .value(_), operator: _, e2: .value(_)):
      return CTL(formula: .true, net: net, canonicityLevel: canonicityLevel, simplified: simplified).eval()
    case .intExpr(e1: .tokenCount(_), operator: _, e2: .tokenCount(_)):
      fatalError("The tool does not manage a cardinality comparison between places")
    case .intExpr(e1: let e1, operator: .leq, e2: let e2):
      return evalLeq(e1: e1, e2: e2)
    case .intExpr(e1: let e1, operator: .lt, e2: let e2):
      return evalLt(e1: e1, e2: e2)
    default:
      fatalError("This is not possible")
    }
  }
  
  /// Evaluate a "less than or equal to" expression and it creates the equivalent symbolic vector set which satisfies the condition.
  ///  e.g.: `p1 ≤ 2`, `3 ≤ p2`
  /// - Parameters:
  ///   - e1: First expression
  ///   - e2: Second expression
  ///   - net: The corresponding Petri net
  /// - Returns: The symbolic vector set that encodes all markings that satisfy the condition
  func evalLeq(e1: Expression, e2: Expression) -> SVS {
    var marking = net.zeroMarking()
    switch (e1, e2) {
    // i <= p
    case (.value(let i), .tokenCount(let p)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i
      return [SV(value: ([marking],[]), net: net)]
    // p <= i
    case (.tokenCount(let p), .value(let i)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i+1
      return [SV(value: ([],[marking]), net: net)]
    default:
      fatalError("Operators are not managed yet. They cannot be evaluated")
    }
  }
  
  /// Evaluate a "less than expression and it creates the equivalent symbolic vector set which satisfies the condition.
  ///  e.g.: `p1 < 2`, `3 < p2`
  /// - Parameters:
  ///   - e1: First expression
  ///   - e2: Second expression
  ///   - net: The corresponding Petri net
  /// - Returns: The symbolic vector set that encodes all markings that satisfy the condition
  func evalLt(e1: Expression, e2: Expression) -> SVS {
    var marking = net.zeroMarking()
    switch (e1, e2) {
    // i < p
    case (.value(let i), .tokenCount(let p)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i+1
      return [SV(value: ([marking],[]), net: net)]
    // p < i
    case (.tokenCount(let p), .value(let i)):
      guard net.places.contains(p) else {
        fatalError("Place \(p) does not exist")
      }
      marking[p] = i
      return [SV(value: ([],[marking]), net: net)]
    default:
      fatalError("Operators are not managed yet. They cannot be evaluated")
    }
  }
  
  func evalEF() -> SVS {
    let phi = self.eval()
    var res = phi
    var resTemp: SVS
    if debug {
      print("Predicate structure number at the start of EF evaluation: \(res.count)")
    }
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        resTemp = res
        res = phi.union(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during EF evaluation: \(res.count)")
        }
      } while !SVS(values: Set(res.filter({!resTemp.contains($0)}))).isIncluded(resTemp)
    }
    return res
  }
  
  func evalAF() -> SVS {
    let phi = self.eval()
    var res = phi
    var resTemp: SVS
    if debug {
      print("Predicate structure number at the start of AF evaluation: \(res.count)")
    }
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        resTemp = res
        res = phi.union(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity).intersection(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during AF evaluation: \(res.count)")
        }
      } while !res.isIncluded(resTemp)
    }
    return res
  }
  
  func evalEG() -> SVS {
    let phi = self.eval()
    var res = phi
    var resTemp: SVS
    if debug {
      print("Predicate structure number at the start of EG evaluation: \(res.count)")
    }
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        resTemp = res
        res = phi.intersection(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity).union(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during EG evaluation: \(res.count)")
        }
      } while !resTemp.isIncluded(res)
    }
    return res
  }
  
  func evalAG() -> SVS {
    let phi = self.eval()
    var res = phi
    var resTemp: SVS
    if debug {
      print("Predicate structure number at the start of AG evaluation: \(res.count)")
    }
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        resTemp = res
        res = phi.intersection(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during AG evaluation: \(res.count)")
        }
      } while !resTemp.isIncluded(res)
    }
    return res
  }
  
  func evalEU(_ ctl: CTL) -> SVS {
    let phi = self.eval()
    let psi = ctl.eval()
    var res = psi
    if debug {
      print("Predicate structure number of phi at the start of EU evaluation: \(phi.count)")
      print("Predicate structure number of psi at the start of EU evaluation: \(res.count)")
    }
    var resTemp: SVS
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        resTemp = res
        res = psi.union(phi.intersection(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during EU evaluation: \(res.count)")
        }
      } while !res.isIncluded(resTemp)
    }
    return res
  }
  
  func evalAU(_ ctl: CTL) -> SVS {
    let phi = self.eval()
    let psi = ctl.eval()
    var res = psi
    var resTemp: SVS
    if debug {
      print("Predicate structure number of phi at the start of AU evaluation: \(phi.count)")
      print("Predicate structure number of psi at the start of AU evaluation: \(res.count)")
    }
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        resTemp = res
        res = psi.union(phi.intersection(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity).intersection(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during AU evaluation: \(res.count)")
        }
      } while !res.isIncluded(resTemp)
    }
    return res
  }
  
  /// Reduce a query using some rewriting on CTL formulas. Using rewriting theories of the paper: Simplification of CTL Formulae
  /// for Efficient Model Checking of Petri Nets from Frederik Bønneland & al. .
  /// - Returns: The reduced CTL
  public func queryReduction() -> CTL {
    return CTL(formula: queryReduction(formula), net: net, canonicityLevel: canonicityLevel)
  }
  
  
  /// Reduce a query using some rewriting on CTL formulas. Using rewriting theories of the paper: Simplification of CTL Formulae
  /// for Efficient Model Checking of Petri Nets from Frederik Bønneland & al. .
  /// - Parameter formula: The formula to rewrite
  /// - Returns: The rewritten formula
  func queryReduction(_ formula: Formula) -> Formula {
    switch formula {
    case .intExpr(e1: _, operator: _, e2: _):
      return formula
    case .deadlock:
      return .deadlock
    case .isFireable(_):
      return formula
    case .true:
      return .true
    case .false:
      return .false
    case .after(_):
      return formula
    case .not(_):
      return self.notReduction(formula)
    case .and(let formula1, let formula2):
      return .and(queryReduction(formula1), queryReduction(formula2))
    case .or(let formula1, let formula2):
      return .or(queryReduction(formula1), queryReduction(formula2))
    case .EX(let formula):
      return .EX(queryReduction(formula))
    case .AX(let formula):
      return .AX(queryReduction(formula))
    case .EF(_):
      return efReduction(formula)
    case .AF(_):
      return afReduction(formula)
    case .EG(let formula):
      return queryReduction(.not(.AF(queryReduction(.not(formula)))))
    case .AG(let formula):
      return queryReduction(.not(.EF(queryReduction(.not(formula)))))
    case .EU(_, _):
      return euReduction(formula)
    case .AU(_, _):
      return auReduction(formula)
    }
  }
  
  func notReduction(_ formula: Formula) -> Formula {
    switch formula {
    case .not(let subFormula):
      switch subFormula {
      case .not(let formula1):
        return queryReduction(formula1)
      case .EX(let formula1):
        return queryReduction(.AX(.not(formula1)))
      case .AX(let formula1):
        return queryReduction(.EX(.not(formula1)))
      case .or(let formula1, let formula2):
        return queryReduction(.and(.not(formula1), .not(formula2)))
      case .and(let formula1, let formula2):
        return queryReduction(.or(.not(formula1), .not(formula2)))
      case .EF(let formula1):
        return .AG(queryReduction(.not(formula1)))
      case .AF(let formula1):
        return .EG(queryReduction(.not(formula1)))
      case .EG(let formula1):
        return .AF(queryReduction(.not(formula1)))
      case .AG(let formula1):
        return .EF(queryReduction(.not(formula1)))
      default:
        return .not(queryReduction(subFormula))
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  func efReduction(_ formula: Formula) -> Formula {
    switch formula {
    case .EF(let subFormula):
      switch subFormula {
      case .not(.deadlock):
        return .not(.deadlock)
      case .EF(let formula1):
        return .EF(formula1)
      case .AF(let formula1):
        return queryReduction(.EF(formula1))
      case .EU(_, let formula2):
        return queryReduction(.EF(formula2))
      case .AU(_, let formula2):
        return queryReduction(.EF(formula2))
      case .or(let formula1, let formula2):
        return queryReduction(.or(.EF(formula1), .EF(formula2)))
      default:
        return .EF(queryReduction(subFormula))
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  func afReduction(_ formula: Formula) -> Formula {
    switch formula {
    case .AF(let subFormula):
      let formulaReduced = queryReduction(subFormula)
      switch formulaReduced {
      case .not(.deadlock):
        return .not(.deadlock)
      case .EF(let formula1):
        return .EF(formula1)
      case .AF(let formula1):
        return .AF(formula1)
      case .AU(_, let formula2):
        return queryReduction(.AF(formula2))
      case .or(let formula1, .EF(let formula2)):
        return queryReduction(.or(.EF(formula2), .AF(formula1)))
      default:
        return .AF(queryReduction(subFormula))
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  func auReduction(_ formula: Formula) -> Formula {
    switch formula {
    case .AU(let formula1, let formula2):
      switch (formula1, formula2) {
      case (_, .not(.deadlock)):
        return .not(.deadlock)
      case (.deadlock, _):
        return queryReduction(formula2)
      case (.not(.deadlock), _):
        return queryReduction(.AF(formula2))
      case (_, .EF(let formula3)):
        return .AF(formula3)
      case (_, .or(let formula3, .EF(let formula4))):
        return queryReduction(.or(.EF(formula4), .AU(formula1, formula3)))
      default:
        return .AU(queryReduction(formula1), queryReduction(formula2))
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  func euReduction(_ formula: Formula) -> Formula {
    switch formula {
    case .EU(let formula1, let formula2):
      switch (formula1, formula2) {
      case (_, .not(.deadlock)):
        return .not(.deadlock)
      case (.deadlock, let formula2):
        return queryReduction(formula2)
      case (.not(.deadlock), _):
        return queryReduction(.EF(formula2))
      case (_, .EF(let formula3)):
        return .EF(formula3)
      case (_, .or(let formula3, .EF(let formula4))):
        return queryReduction(.or(.EF(formula4), .EU(formula1, formula3)))
      default:
        return .EU(queryReduction(formula1), queryReduction(formula2))
      }
    default:
      fatalError("This is not possible")
    }
  }
  
  public func count() -> Int {
    return count(formula)
  }
  /// Count the number of elements of a CTL formula
  /// - Returns: The number of elements of the CTL formula
  public func count(_ formula: Formula) -> Int {
    switch formula {
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
    case .not(let formula1):
      return 1 + count(formula1)
    case .and(let formula1, let formula2):
      return 2 + count(formula1) + count(formula2)
    case .or(let formula1, let formula2):
      return 2 + count(formula1) + count(formula2)
    case .EX(let formula1):
      return 1 + count(formula1)
    case .AX(let formula1):
      return 1 + count(formula1)
    case .EF(let formula1):
      return 1 + count(formula1)
    case .AF(let formula1):
      return 1 + count(formula1)
    case .EG(let formula1):
      return 1 + count(formula1)
    case .AG(let formula1):
      return 1 + count(formula1)
    case .EU(let formula1, let formula2):
      return 2 + count(formula1) + count(formula2)
    case .AU(let formula1, let formula2):
      return 2 + count(formula1) + count(formula2)
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
  public func eval(marking: Marking) -> Bool {
    switch formula {
    case .intExpr(e1: _, operator: _, e2: _):
      return evalCardinality().contains(marking: marking)
    case .isFireable(let t):
      if net.transitions.contains(t) {
        return
          SV(value: ([net.inputMarkingForATransition(transition: t)], []), net: net).contains(marking: marking)
      } else {
        fatalError("Unknown transition")
      }
    case .after(let t):
      if net.transitions.contains(t) {
        return SV(value:  ([], [net.outputMarkingForATransition(transition: t)]), net: net).contains(marking: marking)
      } else {
        fatalError("Unknown transition")
      }
    case .true:
      return true
    case .false:
      return false
    case .and(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let evalCTL1 = ctl1.eval(marking: marking)
      if evalCTL1 == false {
        return false
      }
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      return ctl2.eval(marking: marking)
    case .or(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let evalCTL1 = ctl1.eval(marking: marking)
      if evalCTL1 == true {
        return true
      }
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      return (ctl2.eval(marking: marking))
    case .not(let formula1):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.eval().not(net: net, canonicityLevel: canonicityLevel).contains(marking: marking)
    case .deadlock:
      return SVS.deadlock(net: net).contains(marking: marking)
    case .EX(let formula1):
      if SVS.deadlock(net: net).contains(marking: marking) {
        return false
      }
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.eval().revert(canonicityLevel: canonicityLevel, capacity: net.capacity).contains(marking: marking)
    case .AX(let formula1):
      if SVS.deadlock(net: net).contains(marking: marking) {
        return true
      }
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.eval().revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: net.capacity).contains(marking: marking)
    case .EF(let formula1):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.evalEF(marking: marking)
    case .AF(let formula1):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.evalAF(marking: marking)
    case .EG(let formula1):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.evalEG(marking: marking)
    case .AG(let formula1):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      return ctl1.evalAG(marking: marking)
    case .EU(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      return ctl1.evalEU(ctl2, marking: marking)
    case .AU(let formula1, let formula2):
      let ctl1 = CTL(formula: formula1, net: net, canonicityLevel: canonicityLevel)
      let ctl2 = CTL(formula: formula2, net: net, canonicityLevel: canonicityLevel)
      return ctl1.evalAU(ctl2, marking: marking)
    }
    
  }

//  func evalEF(marking: Marking) -> Bool {
//    let phi = self.eval()
//    var res = phi
//    if debug {
//      print("Predicate structure number at the start of EF evaluation: \(res.count)")
//    }
//    if res.contains(marking: marking) == true {
//      return true
//    }
//    var resTemp: SVS
//    repeat {
//      if res.contains(marking: marking) {
//        return true
//      }
//      resTemp = res
//      res = phi.union(res.revert(canonicityLevel: canonicityLevel, capacity: net.capacity), canonicityLevel: canonicityLevel)
//
//      if simplified {
//        res = res.simplified()
//      }
//      if debug {
//        print("Predicate structure number during EF evaluation: \(res.count)")
//      }
//    } while !SVS(values: Set(res.filter({!resTemp.contains($0)}))).isIncluded(resTemp)
//    return res.contains(marking: marking)
//  }
  func evalEF(marking: Marking) -> Bool {
    let phi = self.eval()
    var res = phi
    if debug {
      print("Predicate structure number at the start of EF evaluation: \(res.count)")
    }
    if res.contains(marking: marking) == true {
      return true
    }
    var resTemp: SVS
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        if res.contains(marking: marking) {
          return true
        }
        resTemp = res
        res = phi.union(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel)
        
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during EF evaluation: \(res.count)")
        }
      } while !SVS(values: Set(res.filter({!resTemp.contains($0)}))).isIncluded(resTemp)
    }
    return res.contains(marking: marking)
  }
  
  func evalAF(marking: Marking) -> Bool {
    let phi = self.eval()
    var res = phi
    if debug {
      print("Predicate structure number at the start of AF evaluation: \(res.count)")
    }
    if res.contains(marking: marking) == true {
      return true
    }
    var resTemp: SVS
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        if res.contains(marking: marking) {
          return true
        }
        resTemp = res
        // We do not need to apply the union with res, because we are looking for a predicate structure that includes our marking.
        // Thus, if a predicate structure is not valid, we just use it to compute the revert and do not reinsert it.
        res = phi.union(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity).intersection(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during AF evaluation: \(res.count)")
        }
      } while !res.isIncluded(resTemp)
    }
    return res.contains(marking: marking)
  }
  
  func evalEG(marking: Marking) -> Bool {
    let phi = self.eval()
    var res = phi
    if debug {
      print("Predicate structure number at the start of EG evaluation: \(res.count)")
    }
    if res.contains(marking: marking) == false {
      return false
    }
    var resTemp: SVS
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        if !res.contains(marking: marking) {
          return false
        }
        resTemp = res
        res = phi.intersection(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity).union(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during EG evaluation: \(res.count)")
        }
      } while !resTemp.isIncluded(res)
    }
    return res.contains(marking: marking)
  }
  
  func evalAG(marking: Marking) -> Bool {
    let phi = self.eval()
    var res = phi
    if debug {
      print("Predicate structure number at the start of AG evaluation: \(res.count)")
    }
    if res.contains(marking: marking) == false {
      return false
    }
    var resTemp: SVS
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        if !res.contains(marking: marking) {
          return false
        }
        resTemp = res
        res = phi.intersection(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during AG evaluation: \(res.count)")
        }
      } while !resTemp.isIncluded(res)
    }
    return res.contains(marking: marking)
  }
  
  func evalEU(_ ctl: CTL, marking: Marking) -> Bool {
    let psi = ctl.eval()
    if debug {
      print("Predicate structure number of phi at the start of EU evaluation: \(psi.count)")
    }
    let isPsiContained = psi.contains(marking: marking)
    if  isPsiContained == true {
      return true
    }
    let phi = self.eval()
    if debug {
      print("Predicate structure number of psi at the start of EU evaluation: \(phi.count)")
    }
    if isPsiContained == false && phi.contains(marking: marking) == false {
      return false
    }
    var res = psi
    var resTemp: SVS
    
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        if res.contains(marking: marking) {
          return true
        }
        resTemp = res
        // We do not need to apply the union with res, because we are looking for a predicate structure that includes our marking.
        // Thus, if a predicate structure is not valid, we just use it to compute the revert and do not reinsert it.
        //      let res1 = res.revert(canonicityLevel: canonicityLevel)
        //      let res2 = phi.intersection(res1, canonicityLevel: canonicityLevel)
        //      let res = psi.union(res2, canonicityLevel: canonicityLevel)
        res = psi.union(phi.intersection(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        //      print(res)
        if debug {
          print("Predicate structure number during EU evaluation: \(res.count)")
        }
      } while !res.isIncluded(resTemp)
    }
    return res.contains(marking: marking)
  }
  
  func evalAU(_ ctl: CTL, marking: Marking) -> Bool {
    let psi = ctl.eval()
    if debug {
      print("Predicate structure number of phi at the start of AU evaluation: \(psi.count)")
    }
    let isPsiContained = psi.contains(marking: marking)
    if  isPsiContained == true {
      return true
    }
    let phi = self.eval()
    if debug {
      print("Predicate structure number of psi at the start of AU evaluation: \(phi.count)")
    }
    if isPsiContained == false && phi.contains(marking: marking) == false {
      return false
    }
    var res = psi
    var resTemp: SVS
    let saturatedStarter = saturated ? 1 : net.capacity.first!.value
    
    for n in saturatedStarter ..< net.capacity.first!.value + 1 {
      let newCapacity = net.createCapacityVectorBasedOnANat(n: n)
      repeat {
        if res.contains(marking: marking) {
          return true
        }
        resTemp = res
        // We do not need to apply the union with res, because we are looking for a predicate structure that includes our marking.
        // Thus, if a predicate structure is not valid, we just use it to compute the revert and do not reinsert it.
        res = psi.union(phi.intersection(res.revert(canonicityLevel: canonicityLevel, capacity: newCapacity).intersection(res.revertTilde(net: net, canonicityLevel: canonicityLevel, capacity: newCapacity), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel), canonicityLevel: canonicityLevel)
        if simplified {
          res = res.simplified()
        }
        if debug {
          print("Predicate structure number during AU evaluation: \(res.count)")
        }
      } while !res.isIncluded(resTemp)
    }
    return res.contains(marking: marking)
  }
  
  public func relatedPlaces() -> Set<PetriNet.PlaceType> {
    switch self.formula {
    case .deadlock:
      return net.places
    case .isFireable(let t):
      var places: Set<PetriNet.PlaceType> = []
      if let i = net.input[t] {
        places = places.union(i.keys)
      }
      if let o = net.output[t] {
        places = places.union(o.keys)
      }
      return places
    case .intExpr(e1: _, operator: _, e2: _):
      print("CAREFUL, NOT MANAGED YET")
      return []
    case .after(let t):
      var places: Set<PetriNet.PlaceType> = []
      if let i = net.input[t] {
        places = places.union(i.keys)
      }
      if let o = net.output[t] {
        places = places.union(o.keys)
      }
      return places
    case .true:
      return net.places
    case .false:
      return net.places
    case .and(let formula1, let formula2):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces().union(CTL(formula: formula2, net: net, canonicityLevel: .none).relatedPlaces())
    case .or(let formula1, let formula2):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces().union(CTL(formula: formula2, net: net, canonicityLevel: .none).relatedPlaces())
    case .not(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .EX(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .EF(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .EG(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .AX(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .AF(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .AG(let formula1):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces()
    case .EU(let formula1, let formula2):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces().union(CTL(formula: formula2, net: net, canonicityLevel: .none).relatedPlaces())
    case .AU(let formula1, let formula2):
      return CTL(formula: formula1, net: net, canonicityLevel: .none).relatedPlaces().union(CTL(formula: formula2, net: net, canonicityLevel: .none).relatedPlaces())
    }
  }
  
}

extension CTL: Equatable {
  public static func == (lhs: CTL, rhs: CTL) -> Bool {
    return lhs.formula == rhs.formula
  }
}

extension CTL: CustomStringConvertible {
  public var description: String {
    var res: String = ""
    res.append("CTL formula: \(formula.description)\n")
    res.append("Options: \n")
    res.append("  Canonicity level: \(canonicityLevel)\n")
    res.append("  Simplified: \(simplified)\n")
    res.append("  Debug: \(debug)")
    return res
    }
  
}
