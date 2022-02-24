import ConsoleKit
import CoreImage
import Foundation

enum ExportHEICError: Error, CustomStringConvertible {
  var description: String {
    switch self {
    case .couldNotReadImage:
      return "Could not read image file"
    }
  }

  case couldNotReadImage
}

struct ExportHEICCommand: Command {
  public struct ExportHEICCommandSignature: CommandSignature {
    @Option(name: "input-file", help: "Path to input image file", required: true)
    var inputFile: String!

    @Option(
      name: "quality", help: "Compression quality between 0.0-1.0. Cannot be used with --size-limit",
      allowedValues: 0.0...1.0)
    var quality: Float?

    @Option(
      name: "size-limit",
      help: "Limit the size in bytes of the resulting image file, instead of specifying a "
        + "quality directly. Cannot be used with --quality",
      allowedValues: 1...Int64.max)
    var sizeLimit: Int64?

    @Option(
      name: "min-quality",
      help: "Minimal allowed compression quality, between 0.0-1.0, if --size-limit is used. Default: 0.0",
      allowedValues: 0.0...1.0)
    var minQuality: Double?

    @Option(
      name: "max-quality",
      help: "Maximal allowed compression quality, between 0.0-1.0, if --size-limit is used. Default: 1.0",
      allowedValues: 0.0...1.0)
    var maxQuality: Double?

    @Option(
      name: "color-space",
      help: "Name of the output color space. Omit to use input image color space",
      allowedValues: [
        CGColorSpace.sRGB,
        CGColorSpace.displayP3,
        CGColorSpace.adobeRGB1998,
      ].map { ($0 as String).replacingOccurrences(of: "kCGColorSpace", with: "") })
    var colorSpaceName: String?

    @Argument(name: "output-file", help: "Path to where the output file will be placed")
    var outputFile: String

    @Flag(name: "verbose")
    var verbose: Bool

    var inputFileURL: URL! {
      guard let inputFile = self.inputFile else {
        fatalError("Missing inputFile")
      }

      return URL(fileURLWithPath: inputFile)
    }

    var outputFileURL: URL {
      return URL(fileURLWithPath: outputFile)
    }

    var colorSpace: CGColorSpace? {
      guard let colorSpaceName = self.colorSpaceName else {
        return nil
      }

      return CGColorSpace(name: "kCGColorSpace\(colorSpaceName)" as CFString)
    }

    public init() {}
  }

  var help: String {
    return "Export input image file as HEIC"
  }

  func run(using context: CommandContext, signature: ExportHEICCommandSignature) throws {
    try signature.enhanceOptions()
    try signature.checkOptions()

    let inputImage = CIImage(contentsOf: signature.inputFileURL)
    guard let inputImage = inputImage else {
      throw ExportHEICError.couldNotReadImage
    }

    let bitDepth = inputImage.properties["Depth"] as? Int ?? 8
    let colorSpace =
      signature.colorSpace ?? inputImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
    let shouldUseHEIF10 = bitDepth > 8

    if signature.verbose {
      context.console.print("Input URL: \(signature.inputFileURL!)")
      context.console.print("Input Colorspace: \(inputImage.colorSpace!)")
      context.console.print("Input Bitdepth: \(bitDepth)")
    }

    if signature.quality != nil {
      try writeHEIF(
        of: inputImage,
        to: signature.outputFileURL,
        in: colorSpace,
        withQuality: signature.quality!,
        shouldUseHEIF10: shouldUseHEIF10,
        verbose: signature.verbose)
    } else {
      try writeSizeLimitedHEIF(
        of: inputImage,
        to: signature.outputFileURL,
        in: colorSpace,
        withSizeLimit: signature.sizeLimit!,
        withinRange: (signature.minQuality ?? 0)...(signature.maxQuality ?? 1),
        shouldUseHEIF10: shouldUseHEIF10,
        verbose: signature.verbose)
    }
  }
}

extension ExportHEICCommand.ExportHEICCommandSignature {
  enum MyError: Error, CustomStringConvertible {
    var description: String {
      switch self {
      case .coexistencyNotAllowed(let label, let anotherArgumentLabel):
        return "`--\(label)` cannot be used with `--\(anotherArgumentLabel)`"
      case .missingEitherArgument(let labels):
        let flags = labels.map({ s in "--" + s }).joined(separator: ", ")
        return "One of \(flags) must be specified"
      }
    }

    case coexistencyNotAllowed(_ label: String, _ anotherArgumentLabel: String)
    case missingEitherArgument(_ labels: [String])
  }

  func checkOptions() throws {
    if quality != nil {
      if sizeLimit != nil { throw MyError.coexistencyNotAllowed("quality", "size-limit") }
      if minQuality != nil { throw MyError.coexistencyNotAllowed("quality", "min-quality") }
      if maxQuality != nil { throw MyError.coexistencyNotAllowed("quality", "max-quality") }
    } else {
      if sizeLimit == nil { throw MyError.missingEitherArgument(["quality", "size-limit"]) }
    }
  }
}
