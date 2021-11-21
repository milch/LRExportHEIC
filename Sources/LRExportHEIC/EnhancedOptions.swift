import ConsoleKit
import Foundation

var validationFunctions: [() throws -> Void] = []

protocol EnhancedOption {
  var isPresent: Bool { get }
  var name: String { get }
}

func throwOnFailure<ErrorType: Error>(
  _ function: @escaping () -> Result<Void, ErrorType>
) -> () throws -> Void {
  return {
    let result = function()
    try result.get()
  }
}

extension Option: EnhancedOption {
  enum EnhancedOptionError: Error, CustomStringConvertible {
    var description: String {
      switch self {
      case .missingArgument(let argumentLabel):
        return "Missing required argument: `--\(argumentLabel)`"
      case .argumentNotAllowed(let label, let allowedValues, let actualValue):
        return "Value \(actualValue) for `--\(label)` needed to be in \(allowedValues)"
      }
    }

    case missingArgument(label: String)
    case argumentNotAllowed(label: String, allowedValues: String, actualValue: String)
  }
  typealias ValidationResult = Result<Void, Option<Value>.EnhancedOptionError>

  func injectOption(
    _ function: @escaping (Option<Value>) -> ValidationResult
  ) -> (() -> ValidationResult) {
    return {
      return function(self)
    }
  }

  func validateRequiredOptionsPresent(_ required: Bool) -> (Option<Value>) -> ValidationResult {
    return { option in
      if required && !option.isPresent {
        return .failure(Option<Value>.EnhancedOptionError.missingArgument(label: option.name))
      }

      return .success(())
    }
  }

  convenience public init(
    name: String,
    short: Character? = nil,
    help: String = "",
    completion: CompletionAction = .default,
    required: Bool = false
  ) {
    self.init(name: name, short: short, help: help, completion: completion)
    let validate =
      required
      |> validateRequiredOptionsPresent
      |> injectOption
      |> throwOnFailure
    validationFunctions.append(validate)
  }
}

// Helper to allow both types of Ranges and Arrays to be passed to `allowedValues`
public protocol HasContains {
  associatedtype Element
  func contains(_: Element) -> Bool
}

extension Range: HasContains {}
extension ClosedRange: HasContains {}
extension Array: HasContains where Element: Equatable {}

extension Option where Value: Equatable {
  func validateOnlyAllowedValues<CType: HasContains>(_ allowed: CType?) -> (Option<Value>) ->
    ValidationResult where CType.Element == Value
  {
    return { option in
      guard let value = option.wrappedValue else {
        return .success(())
      }
      guard let allowed = allowed else {
        return .success(())
      }
      guard allowed.contains(value) else {
        return .failure(.argumentNotAllowed(label: option.name, allowedValues: "\(allowed)", actualValue: "\(value)"))
      }

      return .success(())
    }
  }

  convenience public init<CType: HasContains>(
    name: String,
    short: Character? = nil,
    help: String = "",
    completion: CompletionAction = .default,
    required: Bool = false,
    allowedValues: CType?
  ) where CType.Element == Value {
    self.init(name: name, short: short, help: help, completion: completion, required: required)
    let validate =
      allowedValues
      |> validateOnlyAllowedValues
      |> injectOption
      |> throwOnFailure
    validationFunctions.append(validate)
  }
}

extension CommandSignature {
  func enhanceOptions() throws {
    for validate in validationFunctions {
      try validate()
    }
  }
}
