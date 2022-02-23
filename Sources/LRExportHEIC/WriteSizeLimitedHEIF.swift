import CoreImage

func writeSizeLimitedHEIF(
  of image: CIImage,
  to destURL: URL,
  in colorSpace: CGColorSpace,
  withSizeLimit size: Int64,
  withinRange qualityRange: ClosedRange<Double>,
  shouldUseHEIF10: Bool,
  verbose: Bool
) throws {
  let tempDirUrl = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

  // Prefix the temp file's name with a random string to avoid potential conflicts, when we are
  // running on multiple processes.
  let tempBaseName = NSUUID().uuidString + "-" + destURL.deletingPathExtension().lastPathComponent

  // A dict from qualities to URLs. Set up cleanup (temp file removal).
  var qualitiesAndURLs = [Double: URL]()
  defer {
    for (_, url) in qualitiesAndURLs {
      try? FileManager.default.removeItem(at: url)
    }
  }

  func writeTempHEIFAndGetSize(_ quality: Double) -> Int64 {
    let destURL = tempDirUrl.appendingPathComponent("\(tempBaseName)-\(quality).heif")
    do {
      try writeHEIF(
        of: image,
        to: destURL,
        in: colorSpace,
        withQuality: Float(quality),
        shouldUseHEIF10: shouldUseHEIF10,
        verbose: verbose)
      qualitiesAndURLs[quality] = destURL
      let resources = try destURL.resourceValues(forKeys: [.fileSizeKey])
      let fileSize = resources.fileSize!
      if verbose {
        print("Output File Size: \(fileSize)")
      }
      return Int64(fileSize)
    } catch let error {
      fatalError("Cannot write temp HEIF image and get file size: \(error.localizedDescription)")
    }
  }

  // In multiple attempts, generate the images and try to find the fittest quality.
  let quality = qualitySearch(
    byTargetFileSize: size,
    withAccuracy: 0.8,
    withinRange: qualityRange,
    getFileSizeByQualityFn: writeTempHEIFAndGetSize)

  if verbose {
    print("Chosen Output Quality: \(quality)")
  }

  let chosenUrl = qualitiesAndURLs[quality]

  if (chosenUrl != nil) {
    // We have generated an image with given quality.
    if verbose {
      print("Moving \(chosenUrl!) to \(destURL)")
    }
    // Move the right file from the temp directory to the final directory.
    try? FileManager.default.removeItem(at: destURL)
    try FileManager.default.moveItem(at: chosenUrl!, to: destURL)

  } else {
    // We have NOT generated an image with given quality. (qualitySearch may have returned early.)
    try writeHEIF(
      of: image,
      to: destURL,
      in: colorSpace,
      withQuality: Float(quality),
      shouldUseHEIF10: shouldUseHEIF10,
      verbose: verbose)
  }
}
