import ConsoleKit
import Foundation

precedencegroup SingleFowardPipe {
    associativity: left
    higherThan: BitwiseShiftPrecedence
}

infix operator |> : SingleFowardPipe

func |> <V,R>(value:V,function:((V)->R)) -> R {
    function(value)
}

class Block<T> {
    let f: T
    init(_ f: T) { self.f = f }
}

struct OptionContainer: Hashable, Equatable {
    let validator: AnyObject
    let option: EnhancedOption
    let isRequired: Bool

    let uuid = UUID()

    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }

    static func == (lhs: OptionContainer, rhs: OptionContainer) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

var containers: [OptionContainer] = []

protocol EnhancedOption {
    var isPresent: Bool { get }
    var name: String { get }
}


protocol AnyArrayOfErrors{}
enum ArrayOfErrors<ErrorType>: Error, AnyArrayOfErrors {
    case array(_ list: [ErrorType])
}

extension ArrayOfErrors: CustomStringConvertible where ErrorType: CustomStringConvertible {
    var description: String {
        switch (self) {
        case .array(let errors):
            return "Encountered these errors: \(errors.map { $0.description }.joined(separator: ", "))"
        }
    }
}

func chainValidations<InType, ErrorType: Error>(
    _ validations: ((InType) -> Result<Void, ErrorType>)...
) -> ((InType) -> Result<Void, ArrayOfErrors<ErrorType>>){
    return { opt in 
        let results = validations.map { validation in 
            return validation(opt)
        }
        let errors = results.compactMap { result -> ErrorType? in 
            if case let .failure(error) = result {
                return error
            }
            return nil
        }
        if errors.isEmpty {
            return .success(())
        }

        return .failure(.array(errors))
    }
}

func throwOnFailure<InType, ErrorType: Error>(
    _ function: @escaping (InType) -> Result<Void, ErrorType>
) -> (InType) throws -> Void {
    return { arg in
        let result = function(arg)
        try result.get()
    }
}

extension Option: EnhancedOption {
    enum EnhancedOptionError: Error, CustomStringConvertible {
        var description: String {
            switch(self) {
            case .missingArgument(let argumentLabel):
                return "Missing required argument: `--\(argumentLabel)`"
            case .argumentNotAllowed(let allowedValues, let actualValue):
                return "\(actualValue) needed to be in \(allowedValues)"
            }
        }

        case missingArgument(label: String)
        case argumentNotAllowed(allowedValues: String, actualValue: String)
    }

    func validateRequiredOptionsPresent(_ required: Bool) -> (Option<Value>) -> Result<Void, Option<Value>.EnhancedOptionError> {
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
        let validator = chainValidations(
                            validateRequiredOptionsPresent(required)
                        )
                        |> throwOnFailure
        containers.append(OptionContainer(validator: Block(validator), option: self, isRequired: required))
    }
}

public protocol HasContains {
    associatedtype Element
    func contains(_: Element) -> Bool
}

extension Range: HasContains {}
extension ClosedRange: HasContains {}
extension Array: HasContains where Element: Equatable {}

extension Option where Value : Equatable {
    func validateOnlyAllowedValues<CType: HasContains>(_ allowed: CType?) -> (Option<Value>) -> Result<Void, Option<Value>.EnhancedOptionError> where CType.Element == Value {
        return { option in
            guard let value = option.wrappedValue else {
                return .success(())
            }
            guard let allowed = allowed else {
                return .success(())
            }
            if !allowed.contains(value) {
                return .failure(.argumentNotAllowed(allowedValues: "\(allowed)", actualValue: "\(value)"))
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
        let validator = chainValidations(
                            validateOnlyAllowedValues(allowedValues)
                        )
                        |> throwOnFailure
        containers.append(OptionContainer(validator: Block(validator), option: self, isRequired: required))
    }
}

// extension Option where Value : Comparable {
//     func validateInRange(_ range: Range) -> (Option<Value>) -> Result<Void, Option<Value>.EnhancedOptionError> {
//         return { option in
//             guard let value = option.wrappedValue else {
//                 return .success(())
//             }
//             if !allowed.isEmpty && !allowed.contains(value) {
//                 return .failure(.argumentNotAllowed(allowedValues: allowed, actualValue: value))
//             }

//             return .success(())
//         }
//     }

//     convenience public init(
//         name: String,
//         short: Character? = nil,
//         help: String = "",
//         completion: CompletionAction = .default,
//         required: Bool = false,
//         allowedValues: [Value] = []
//     ) {
//         self.init(name: name, short: short, help: help, completion: completion, required: required)
//         let validator = chainValidations(
//                             validateOnlyAllowedValues(allowedValues)
//                         )
//                         |> throwOnFailure
//         containers.append(OptionContainer(validator: Block(validator), option: self, isRequired: required))
//     }
// }

extension CommandSignature {
    func enhanceOptions() throws {
        for option in containers { 
            let validate = unsafeBitCast(option.validator, to: Block<(AnyObject) throws -> Void>.self)
            try validate.f(option.option as AnyObject)
        }
    }
}

