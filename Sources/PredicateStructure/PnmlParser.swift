import Foundation

public class PnmlParser: NSObject, XMLParserDelegate {
  
  var net: [String: String] = [:]
  var places: [String: [String: String]] = [:]
  var transitions: [String: [String: String]] = [:]
  var arcs: [String: [String: String]] = [:]
  var currentID = ""
  var currentType = ""
  var currentTag = ""
  var currentDic = [String: String]()
  let regularTags = Set<String>(["name", "initialmarking", "inscription"])

  
  /// Load a Petri net from a local pnml file.
  /// - Parameter filePath: The path name in the Resource folder
  /// - Returns: The corresponding Petri net and its  initial marking
  public func loadPN(filePath: String) -> (PetriNet, Marking) {
    if let url = Bundle.module.url(forResource: filePath, withExtension: nil) {
      let parser = XMLParser(contentsOf: url)!
      parser.delegate = self
      parser.parse()
    } else {
      print("Did not find a file to parse")
    }
    return createPN()
  }
  
  /// Load a Petri net in a pnml format from an url.
  /// - Parameter filePath: The url of the pnml file
  /// - Returns: The corresponding Petri net and its  initial marking
  public func loadPN(url: URL) -> (PetriNet, Marking) {
    let parser = XMLParser(contentsOf: url)!
    parser.delegate = self
    parser.parse()
    return createPN()
  }
  
  /// Parse  the tags
  public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
    switch elementName.lowercased() {
      case "net":
      if let id = attributeDict["id"] {
        net["id"] = id
        currentType = "net"
      }
      if let type = attributeDict["type"] {
        net["type"] = type
        currentType = "net"
      }
      case "place":
      if let id = attributeDict["id"] {
        places[id] = [:]
        currentID = id
        currentType = "place"
      }
      case "transition":
      if let id = attributeDict["id"] {
        transitions[id] = [:]
        currentID = id
        currentType = "transition"
      }
      case "arc":
      if let id = attributeDict["id"] {
        arcs[id] = [:]
        if let source = attributeDict["source"], let target = attributeDict["target"] {
          arcs[id]!["source"] = source
          arcs[id]!["target"] = target
          arcs[id]!["inscription"] = "1"
        }
        currentID = id
        currentType = "arc"
      }
      case "name":
        currentTag = "name"
      case "initialmarking":
        currentTag = "initialmarking"
      case "inscription":
        currentTag = "inscription"
      default:
        break
      }
  }

  /// Parse the content of tags
  public func parser(_ parser: XMLParser, foundCharacters string: String) {
    if !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      switch currentType {
      case "place":
        if regularTags.contains(currentTag) {
          places[currentID]![currentTag] = string
          currentTag = ""
        }
      case "transition":
        if regularTags.contains(currentTag) {
          transitions[currentID]![currentTag] = string
          currentTag = ""
        }
      case "arc":
        if regularTags.contains(currentTag) {
          arcs[currentID]![currentTag] = string
          currentTag = ""
        }
      default:
        break
      }
    }
  }

  public func parserDidEndDocument(_ parser: XMLParser) {
    print("Parsing complete")
  }
  
  
  /// Create the petri net corresponding to the parsing pnml file and the initial marking
  /// - Returns: A couple where the first element is a Petri net and the second a marking
  func createPN() -> (PetriNet, Marking) {
    var p: Set<String> = []
    var t: Set<String> = []
    var a: [PetriNet.ArcDescription] = []
    var storage: [String: Int] = [:]
    // A dic containing place and transition names. The left element is the id and the right one the name. If there is no name, the id is kept as a name
    var dicName: [String: String] = [:]
    
    for (id, information) in places {
      if let name = information["name"] {
        p.insert(name)
        dicName[id] = name
      } else {
        p.insert(id)
        dicName[id] = id
      }
      if let initialMarking = information["initialmarking"] {
        storage[dicName[id]!] = Int(initialMarking)!
      } else {
        storage[dicName[id]!] = 0
      }
    }
    
    for (id, information) in transitions {
      if let name = information["name"] {
        t.insert(name)
        dicName[id] = name
      } else {
        t.insert(id)
        dicName[id] = id
      }
    }

    for (_, information) in arcs {
      if let source = information["source"], let target = information["target"], let inscription = information["inscription"] {
        if let i = Int(inscription) {
          if let sourceName = dicName[source], let targetName = dicName[target] {
            if p.contains(sourceName) {
              a.append(.pre(from: sourceName, to: targetName, labeled: i))
            } else {
              a.append(.post(from: sourceName, to: targetName, labeled: i))
            }
          } else {
            fatalError("An arc source or target has no correspondence with the existing places or transitions")
          }
        } else {
          fatalError("The inscription cannot be converted into an integer")
        }
      } else {
        fatalError("Information about an arc is not complete.")
      }
    }
    
    let net = PetriNet(places: p, transitions: t, arcs: a)
    let marking = Marking(storage, net: net)
    
    return (net, marking)
  }
  
}
