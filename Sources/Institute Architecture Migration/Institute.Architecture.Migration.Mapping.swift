public import Institute_Architecture_Model
public import Institute_Model

extension Institute.Architecture.Migration {
  /// The single mechanical identity mapping for the four-layer flag day.
  public struct Mapping: Sendable, Equatable {
    public init() {}

    public var organizationRenames:
      [(current: Swift.String, future: Swift.String, kind: Swift.String)]
    {
      [
        ("swift-molecules", "swift-mol-rsv", "reservation"),
        ("swift-primitives", "swift-molecules", "layer"),
        ("swift-compositions", "swift-comp-rsv", "reservation"),
        ("swift-foundations", "swift-compositions", "layer"),
      ]
    }

    public func organization(_ current: Swift.String) -> Swift.String {
      switch current {
      case "swift-primitives": "swift-molecules"
      case "swift-foundations": "swift-compositions"
      default: current
      }
    }

    public func layer(_ current: Swift.String) -> Swift.String {
      switch current {
      case "primitives": "molecules"
      case "foundations": "compositions"
      default: current
      }
    }

    public func repository(organization: Swift.String, name: Swift.String) -> Swift.String {
      guard organization == "swift-primitives" else { return name }
      guard name.hasSuffix("-primitives") else { return name }
      return Swift.String(name.dropLast("-primitives".count))
    }

    public func coordinate(_ current: Swift.String) -> Swift.String {
      guard let separator = current.firstIndex(of: "/") else { return current }
      let currentOrganization = Swift.String(current[..<separator])
      let currentName = Swift.String(current[current.index(after: separator)...])
      if currentOrganization == "swift-foundations", currentName == "swift-testing" {
        return "swift-compositions/swift-test-application"
      }
      if ["swift-primitives", "swift-foundations"].contains(currentOrganization),
        [
          "swift-standard-library-extensions",
          "swift-foundation-extensions",
        ].contains(currentName)
      {
        return "swift-molecules/\(currentName)"
      }
      return
        "\(organization(currentOrganization))/\(repository(organization: currentOrganization, name: currentName))"
    }

    public func url(_ current: Swift.String) -> Swift.String {
      guard let coordinate = Self.coordinate(in: current) else { return current }
      let mapped = self.coordinate(coordinate)
      return "https://github.com/\(mapped).git"
    }

    public func product(_ current: Swift.String) -> Swift.String {
      replacing(" Primitives", with: "", in: current)
    }

    public func module(_ current: Swift.String) -> Swift.String {
      replacing("_Primitives", with: "", in: current)
    }

    private static func coordinate(in url: Swift.String) -> Swift.String? {
      let prefix = "https://github.com/"
      guard url.hasPrefix(prefix) else { return nil }
      let end = url.hasSuffix(".git") ? url.index(url.endIndex, offsetBy: -4) : url.endIndex
      let coordinate = Swift.String(url[url.index(url.startIndex, offsetBy: prefix.count)..<end])
      guard coordinate.split(separator: "/").count == 2 else { return nil }
      return coordinate
    }

    private func replacing(
      _ removed: Swift.String,
      with replacement: Swift.String,
      in value: Swift.String
    ) -> Swift.String {
      var result = value
      while let range = result.firstRange(of: removed) {
        result.replaceSubrange(range, with: replacement)
      }
      return result
    }
  }
}
