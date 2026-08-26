public import Institute_Architecture_Model
public import Institute_Model

extension Institute.Architecture.Migration {
  /// Deterministic tracked-text and tracked-path transformation for the flag day.
  public struct Transformer: Sendable, Equatable {
    public let ledger: Ledger
    public let mapping: Mapping

    public init(ledger: Ledger, mapping: Mapping = .init()) {
      self.ledger = ledger
      self.mapping = mapping
    }

    public func text(
      _ current: Swift.String,
      productRenames: [Swift.String: Swift.String] = [:]
    ) -> Swift.String {
      var result = current
      for repository in ledger.repositories.sorted(by: {
        $0.current.count == $1.current.count
          ? $0.current < $1.current
          : $0.current.count > $1.current.count
      }) {
        let currentName = Self.name(in: repository.current)
        let futureName = Self.name(in: repository.future)
        result = replacing(
          "https://github.com/\(repository.current).git",
          with: "https://github.com/\(repository.future).git",
          in: result
        )
        result = replacing(repository.current, with: repository.future, in: result)
        if currentName != futureName {
          result = replacing(currentName, with: futureName, in: result)
        }
      }
      result = replacing(
        "https://github.com/swift-primitives",
        with: "https://github.com/swift-molecules",
        in: result
      )
      result = replacing(
        "https://github.com/swift-foundations",
        with: "https://github.com/swift-compositions",
        in: result
      )
      result = replacing("swift-primitives/", with: "swift-molecules/", in: result)
      result = replacing("swift-foundations/", with: "swift-compositions/", in: result)
      result = replacing("\"swift-primitives\"", with: "\"swift-molecules\"", in: result)
      result = replacing(
        "\"swift-foundations\"",
        with: "\"swift-compositions\"",
        in: result
      )
      result = replacing("topic: primitives", with: "topic: molecules", in: result)
      result = replacing("topic: foundations", with: "topic: compositions", in: result)
      for currentProduct in productRenames.keys.sorted(by: {
        $0.count == $1.count ? $0 < $1 : $0.count > $1.count
      }) {
        guard let futureProduct = productRenames[currentProduct] else { continue }
        result = replacing(currentProduct, with: futureProduct, in: result)
      }
      result = mapping.module(result)
      return result
    }

    public func path(_ current: Swift.String) -> Swift.String {
      mapping.product(mapping.module(current))
    }

    public func plan(files: [Swift.String: Swift.String?]) -> [Edit] {
      let productRenames = productRenames(in: files)
      files.keys.sorted().compactMap { currentPath in
        let futurePath = path(currentPath)
        let currentText = files[currentPath] ?? nil
        let futureText = currentText.map {
          text($0, productRenames: productRenames)
        }
        let edit = Edit(
          currentPath: currentPath,
          futurePath: futurePath,
          currentText: currentText,
          futureText: futureText
        )
        return edit.changesPath || edit.changesText ? edit : nil
      }
    }

    private func productRenames(
      in files: [Swift.String: Swift.String?]
    ) -> [Swift.String: Swift.String] {
      var result: [Swift.String: Swift.String] = [:]
      for (path, source) in files where path.hasSuffix("Package.swift") {
        guard let source else { continue }
        for value in Self.quotedValues(in: source) where value.contains(" Primitives") {
          result[value] = mapping.product(value)
        }
      }
      return result
    }

    private static func quotedValues(in source: Swift.String) -> [Swift.String] {
      var result: [Swift.String] = []
      var value = ""
      var isQuoted = false
      var isEscaped = false
      for character in source {
        if isEscaped {
          if isQuoted { value.append(character) }
          isEscaped = false
        } else if character == "\\", isQuoted {
          isEscaped = true
        } else if character == "\"" {
          if isQuoted { result.append(value) }
          value = ""
          isQuoted.toggle()
        } else if isQuoted {
          value.append(character)
        }
      }
      return result
    }

    private static func name(in coordinate: Swift.String) -> Swift.String {
      coordinate.split(separator: "/").last.map(Swift.String.init) ?? coordinate
    }

    private func replacing(
      _ current: Swift.String,
      with future: Swift.String,
      in source: Swift.String
    ) -> Swift.String {
      guard current != future, !current.isEmpty else { return source }
      var result = source
      while let range = result.firstRange(of: current) {
        result.replaceSubrange(range, with: future)
      }
      return result
    }
  }
}
