/// Finds the best compression quality to make the resulting file size to be slightly lower than the target file
/// size limit.
///
/// - Parameter maxSize: The target file size. The resulting file size must equal to or be less then the limit,
///     unless `minQuality` is reached.
/// - Parameter sizeAccuracy: An allowance in range 0 - 1. As it tries multiple times to find the best quality,
///     it can stop early to save time if a file's size satisfies `maxSize * sizeAccuracy <= size <=
///     maxSize`.
/// - Parameter qualityRange: The range of quality to attempt within. The range should be between 0 - 1, inclusive.
///     The resulting quality will never be lower than its lower bound, even when the resulting file size is larger
///     than `maxSize`.
/// - Returns: The "best" compression quality found.
///
func qualitySearch(
  byTargetFileSize maxSize: Int64,
  withAccuracy sizeAccuracy: Double,
  withinRange qualityRange: ClosedRange<Double>,
  getFileSizeByQualityFn: (Double) -> Int64
) -> Double {
  assert(maxSize >= 1, "Invalid argument: maxSize >= 1 is not met")
  assert(0 <= sizeAccuracy && sizeAccuracy <= 1, "Invalid argument: 0 <= sizeAccuracy <= 1 is not met")

  var minQ = qualityRange.lowerBound
  var maxQ = qualityRange.upperBound
  assert(0 <= minQ && minQ <= 1, "Invalid argument: 0 <= entire qualityRange <= 1 is not met")
  assert(0 <= maxQ && maxQ <= 1, "Invalid argument: 0 <= entire qualityRange <= 1 is not met")

  if minQ == maxQ {
    return minQ
  }

  let minSize = Int64(Double(maxSize) * sizeAccuracy)
  var qualitiesAndSizes = [(Double, Int64)]()

  var currQ = (minQ + maxQ) / 2
  var currSize = getFileSizeByQualityFn(currQ)
  qualitiesAndSizes.append((currQ, currSize))

  // Some heuristic early returns.
  if currSize > maxSize * 5 {
    let minPossibleSize = getFileSizeByQualityFn(minQ)
    if minPossibleSize >= minSize { return minQ }
    qualitiesAndSizes.append((minQ, minPossibleSize))
  } else if currSize < minSize / 5 {
    let maxPossibleSize = getFileSizeByQualityFn(maxQ)
    if maxPossibleSize <= maxSize { return maxQ }
    qualitiesAndSizes.append((maxQ, maxPossibleSize))
  }

  while true {
    if minSize <= currSize && currSize <= maxSize {
      return currQ
    } else if currSize < minSize {
      minQ = currQ
    } else {
      maxQ = currQ
    }

    assert(maxQ >= minQ)
    if maxQ - minQ <= 0.015 { break }

    currQ = (minQ + maxQ) / 2
    currSize = getFileSizeByQualityFn(currQ)
    qualitiesAndSizes.append((currQ, currSize))
  }

  // If we reach here, we are sure that no iteration's file size is between the target range [minSize, maxSize],
  // except for the last iteration, which is fine.
  assert(qualitiesAndSizes.count >= 1)

  // Find the file size smaller than and closest to maxSize.
  var tuple = qualitiesAndSizes.filter({ (tuple) in tuple.1 <= maxSize }).max(by: { (a, b) in a.1 < b.1 })
  if tuple != nil {
    return tuple!.0
  }

  // Nothing being found means all sizes are greater than the desired size limit. Return the smallest one.
  tuple = qualitiesAndSizes.min(by: { (a, b) in a.1 < b.1 })
  assert(tuple != nil)
  return tuple!.0
}
