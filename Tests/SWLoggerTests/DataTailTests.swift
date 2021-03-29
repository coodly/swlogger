import XCTest
@testable import SWLogger

final class DataTailTests: XCTestCase {
    func testNumberOfLines() {
        let input =
        """
        Line 1
        Line 2
        Line 3
        Line 4
        Line 5
        """
        
        let data = input.data(using: .utf8)!
        let tail = data.tail(lines: 3)
        
        let extracted = String(data: tail, encoding: .utf8)
        let expected =
        """
        
        Line 3
        Line 4
        Line 5
        """
        XCTAssertEqual(expected, extracted)
        
        let full = String(data: data.tail(lines: 10), encoding: .utf8)
        XCTAssertEqual(input, full)
    }
}
