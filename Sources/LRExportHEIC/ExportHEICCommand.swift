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
      name: "quality", help: "Compression quality between 0.0-1.0", required: true,
      allowedValues: 0.0...1.0)
    var quality: Float!

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

    let inputImage = CIImage(contentsOf: signature.inputFileURL)
    guard let inputImage = inputImage else {
      throw ExportHEICError.couldNotReadImage
    }
    var outputFileURL = signature.outputFileURL
    if outputFileURL.pathExtension != "heic" {
      outputFileURL.appendPathExtension("heic")
    }

    let bitDepth = inputImage.properties["Depth"] as? Int ?? 8
    let colorSpace =
      signature.colorSpace ?? inputImage.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
    let shouldUseHEIF10 = bitDepth > 8

    if signature.verbose {
      context.console.print("Input URL: \(signature.inputFileURL!)")
      context.console.print("Output URL: \(outputFileURL)")
      context.console.print("Input Colorspace: \(inputImage.colorSpace!)")
      context.console.print("Output Colorspace: \(colorSpace)")
      context.console.print("Input Bitdepth: \(bitDepth)")
      context.console.print("Output Bitdepth: \(shouldUseHEIF10 ? 10 : 8)")
    }

    let ctx = CIContext()
    let opts =
      [kCGImageDestinationLossyCompressionQuality: signature.quality]
      as [CIImageRepresentationOption: Any]

    if shouldUseHEIF10 {
      try ctx.writeHEIF10Representation(
        of: inputImage,
        to: outputFileURL,
        colorSpace: colorSpace,
        options: opts
      )
    } else {
      try ctx.writeHEIFRepresentation(
        of: inputImage,
        to: outputFileURL,
        format: .RGBA8,
        colorSpace: colorSpace,
        options: opts
      )
    }
  }
}
