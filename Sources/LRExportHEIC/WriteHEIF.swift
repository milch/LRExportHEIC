import CoreImage

func writeHEIF(
  of image: CIImage,
  to url: URL,
  in colorSpace: CGColorSpace,
  withQuality quality: Float,
  shouldUseHEIF10: Bool,
  verbose: Bool
) throws {
  let opts = [kCGImageDestinationLossyCompressionQuality: quality] as [CIImageRepresentationOption: Any]
  let ctx = CIContext()

  if verbose {
    print("Output URL: \(url)")
    print("Output Quality: \(quality)")
    print("Output Colorspace: \(colorSpace)")
    print("Output Bitdepth: \(shouldUseHEIF10 ? 10 : 8)")
  }

  if shouldUseHEIF10 {
    try ctx.writeHEIF10Representation(
      of: image,
      to: url,
      colorSpace: colorSpace,
      options: opts
    )
  } else {
    try ctx.writeHEIFRepresentation(
      of: image,
      to: url,
      format: .RGBA8,
      colorSpace: colorSpace,
      options: opts
    )
  }
}
