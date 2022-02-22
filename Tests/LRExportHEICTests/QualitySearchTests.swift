import Foundation
import XCTest

@testable import func LRExportHEIC.qualitySearch

final class QualitySearchTests: XCTestCase {
  private var getFileSizeByQualityFnCallCount = 0

  override func setUp() {
    super.setUp()
    getFileSizeByQualityFnCallCount = 0
  }

  private func fakeGetFileSize(_ quality: Double) -> Int64 {
    getFileSizeByQualityFnCallCount += 1
    let fileSize = Int64(round(quality * 10000))
    // print(quality, "\t", fileSize)  // Uncomment this line for debugging.
    return fileSize
  }

  func testBasic() throws {
    let actual = qualitySearch(
      byTargetFileSize: 3100, withAccuracy: 0.8, withinRange: 0.1...0.9,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 2 attempts: 0.5 => 5000, 0.3 => 3000
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 2)
    XCTAssertEqual(actual, 0.3)
  }

  func testSameMinMaxQuality() throws {
    let actual = qualitySearch(
      byTargetFileSize: 10, withAccuracy: 1, withinRange: 0.5...0.5,
      getFileSizeByQualityFn: fakeGetFileSize)
    // No need to make attempts.
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 0)
    XCTAssertEqual(actual, 0.5)
  }

  func testTargetVerySmall() throws {
    let actual = qualitySearch(
      byTargetFileSize: 10, withAccuracy: 1, withinRange: 0.1...0.9,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 2 attempts: 0.5 => 5000, 0.1 => 1000
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 2)
    XCTAssertEqual(actual, 0.1)
  }

  func testTargetVerySmallButNotSmallerThanLowestQuality() throws {
    let actual = qualitySearch(
      byTargetFileSize: 900, withAccuracy: 0.5, withinRange: 0.001...1,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 5 attempts: 0.5005 => 5005, 0.001 => 10, 0.2507 => 2507, 0.1259 => 1259, 0.0634 => 634
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 5)
    XCTAssertEqual(actual, 0.0634375)
  }

  func testTargetVeryBig() throws {
    let actual = qualitySearch(
      byTargetFileSize: 100000, withAccuracy: 1, withinRange: 0...1,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 2 attempts: 0.5 => 5000, 1 => 10000
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 2)
    XCTAssertEqual(actual, 1)
  }

  func testLooseSizeAccuracy() throws {
    let actual = qualitySearch(
      byTargetFileSize: 10000, withAccuracy: 0.1, withinRange: 0...1,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 1 attempt: 0.5 => 5000
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 1)
    XCTAssertEqual(actual, 0.5)
  }

  func testStrictSizeAccuracyCannotReachTarget() throws {
    let actual = qualitySearch(
      byTargetFileSize: 10, withAccuracy: 1, withinRange: 0...0.8192,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 7 attempts: 0.4096, 0, 0.2048, 0.1024, 0.0512, 0.0256, 0.0128
    // Ending criteria "len(0, 0.0128) is less than 0.015" is met.
    // Size 128 > TargetSize 10, so returns quality 0.
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 7)
    XCTAssertEqual(actual, 0)
  }

  func testStrictSizeAccuracyButReachedTarget() throws {
    let actual = qualitySearch(
      byTargetFileSize: 129, withAccuracy: 1, withinRange: 0...0.8192,
      getFileSizeByQualityFn: fakeGetFileSize)
    // 7 attempts: 0.4096, 0, 0.2048, 0.1024, 0.0512, 0.0256, 0.0128
    // Ending criteria "len(0, 0.0128) is less than 0.015" is met.
    // Size 128 < TargetSize 129, so returns quality 0.0128.
    XCTAssertEqual(getFileSizeByQualityFnCallCount, 7)
    XCTAssertEqual(actual, 0.0128)
  }
}
