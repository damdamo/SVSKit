import Foundation


/// CTL parser for the Model Checking Contest of 2022
/// It takes a xml file and extracts all CTL formulas.
public class CTLParser: NSObject, XMLParserDelegate {

  var currentID: String = ""
  var currentElement: String = ""
  let booleans = ["conjunction", "disjunction", "negation"]
  var setTransitions: Set<String> = []
  var setPlaces: Set<String> = []
  var CTLOperator: String = ""
  var CTLArray: [String] = []
  var CTLStringDictionnary: [String: [String]] = [:]
  
  /// Load CTL formulas from a local xml file.
  /// - Parameter filePath: The path name in the Resource folder
  /// - Returns: CTL formulas bound to their ID
//  public func loadCTL(filePath: String) -> [String: CTL.Formula] {
//    reset()
//    setTransitions = []
//    CTLStringDictionnary = [:]
//    if let url = Bundle.module.url(forResource: filePath, withExtension: nil) {
//      let parser = XMLParser(contentsOf: url)!
//      parser.delegate = self
//      parser.parse()
//    } else {
//      print("Did not find a file to parse")
//    }
//    return createCTLFormulas()
//  }
  public func loadCTL(filePath: String) -> [String: CTL.Formula] {
    reset()
    setTransitions = []
    CTLStringDictionnary = [:]
    if let data = FileManager.default.contents(atPath: filePath) {
        // Initialize an XMLParser with the XML data
      let parser = XMLParser(data: data)
      parser.delegate = self
      parser.parse()
    } else {
      print("Did not find a file to parse")
    }
    return createCTLFormulas()
  }

  
  /// Load CTL formulas from an url.
  /// - Parameter filePath: The url of the xml file
  /// - Returns: CTL formulas bound to their ID
  public func loadCTL(url: URL) -> [String: CTL.Formula] {
    reset()
    setTransitions = []
    CTLStringDictionnary = [:]
    let parser = XMLParser(contentsOf: url)!
    parser.delegate = self
    parser.parse()
    return createCTLFormulas()
  }
  
  func reset() {
    currentID = ""
    currentElement = ""
    CTLArray = []
  }
  
  /// Parse  the tags
  public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    if elementName == "property" {
      if currentID != "" {
        CTLStringDictionnary[currentID] = CTLArray
        reset()
      }
    } else if elementName == "id" {
      currentElement = "id"
    } else if elementName == "description" {
      currentElement = "description"
    } else if elementName == "formula" {
      currentElement = "formula"
    } else if elementName == "exists-path" {
      CTLOperator = ""
      CTLOperator.append("E")
    } else if elementName == "all-paths" {
      CTLOperator = ""
      CTLOperator.append("A")
    } else if elementName == "next" {
      CTLOperator.append("X")
      CTLArray.append(CTLOperator)
    } else if elementName == "finally" {
      CTLOperator.append("F")
      CTLArray.append(CTLOperator)
    } else if elementName == "globally" {
      CTLOperator.append("G")
      CTLArray.append(CTLOperator)
    } else if elementName == "until" {
      CTLOperator.append("U")
      CTLArray.append(CTLOperator)
    } else if booleans.contains(elementName) {
      CTLArray.append(elementName)
    } else if elementName == "is-fireable" {
      CTLArray.append("isFireable")
    } else if elementName == "transition" {
      currentElement = "transition"
    } else if elementName == "integer-le" {
      CTLArray.append("leq")
    } else if elementName == "tokens-count" {
      CTLArray.append("tokensCount")
    } else if elementName == "place" {
      currentElement = "place"
    } else if elementName == "integer-constant" {
      currentElement = "integerConstant"
    }
    
  }

  /// Parse the content of tags
  public func parser(_ parser: XMLParser, foundCharacters string: String) {
    if !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      if currentElement == "id" {
        currentID = string
        CTLStringDictionnary[string] = []
      } else if currentElement == "transition" {
        CTLArray.append(string)
        setTransitions.insert(string)
      } else if currentElement == "place" {
        CTLArray.append(string)
        setPlaces.insert(string)
      } else if currentElement == "integerConstant" {
        CTLArray.append(string)
      }
    }
  }

  public func parserDidEndDocument(_ parser: XMLParser) {
    if currentID != "" {
      CTLStringDictionnary[currentID] = CTLArray
    }
    print("Parsing complete")
  }
  
  
  /// Create the CTL formulas corresponding to the parsing of the xml file
  /// - Returns: A dictionnary of CTL formulas bound to their ID
  func createCTLFormulas() -> [String: CTL.Formula] {
    let unaryOperators = ["negation", "EX", "AX", "EF", "AF", "EG", "AG"]
    let binaryOperators = ["conjunction", "disjunction", "EU", "AU"]
    var ctlTemp: CTL.Formula
    var res: [String: CTL.Formula] = [:]
    var ctlStack: [CTL.Formula] = []
    var currentT: String = ""
    var expressionStack: [CTL.Expression] = []
    for (key, ctlString) in CTLStringDictionnary {
      for el in ctlString.reversed() {
        if setTransitions.contains(el) {
          currentT = el
        } else if setPlaces.contains(el) {
          expressionStack.insert(.tokenCount(el), at: 0)
        } else if el == "isFireable"{
          ctlStack.insert(.isFireable(currentT), at: 0)
          currentT = ""
        } else if unaryOperators.contains(el) {
          ctlTemp = ctlStack[0]
          ctlStack.removeFirst()
          if el == "negation" {
            ctlStack.insert(.not(ctlTemp), at: 0)
          } else if el == "EX" {
            ctlStack.insert(.EX(ctlTemp), at: 0)
          } else if el == "AX" {
            ctlStack.insert(.AX(ctlTemp), at: 0)
          } else if el == "EF" {
            ctlStack.insert(.EF(ctlTemp), at: 0)
          } else if el == "AF" {
            ctlStack.insert(.AF(ctlTemp), at: 0)
          } else if el == "EG" {
            ctlStack.insert(.EG(ctlTemp), at: 0)
          } else if el == "AG" {
            ctlStack.insert(.AG(ctlTemp), at: 0)
          }
        } else if binaryOperators.contains(el) {
          let x = ctlStack.removeFirst()
          let y = ctlStack.removeFirst()
//          ctlStack.removeFirst(2)
          if el == "conjunction" {
            ctlStack.insert(.and(x,y), at: 0)
          } else if el == "disjunction" {
            ctlStack.insert(.or(x,y), at: 0)
          } else if el == "EU" {
            ctlStack.insert(.EU(x,y), at: 0)
          } else if el == "AU" {
            ctlStack.insert(.AU(x,y), at: 0)
          }
        } else if Int(el) != nil {
          expressionStack.insert(.value(Int(el)!), at: 0)
        } else if el == "leq" {
          let el1 = expressionStack.removeFirst()
          let el2 = expressionStack.removeFirst()
          ctlStack.insert(.intExpr(e1: el1, operator: .leq, e2: el2), at: 0)
        }
      }
      if let ctl = ctlStack.first {
        res[key] = ctl
      }
    }
    return res
  }
  
}
