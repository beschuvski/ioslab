import XCTest
@testable import NativeLab

final class LabModelTests: XCTestCase {
    func testDefaultModelStartsWithTwoPassingChecks() {
        let model = LabModel()
        XCTAssertEqual(model.total, 3)
        XCTAssertEqual(model.passed, 2)
        XCTAssertEqual(model.summary, "2/3 checks passing")
    }

    func testRunNextCheckPromotesFirstPendingCheck() {
        var model = LabModel()
        XCTAssertTrue(model.runNextCheck())
        XCTAssertEqual(model.passed, 3)
        XCTAssertEqual(model.checks.last?.status, .pass)
    }

    func testRunNextCheckReturnsFalseWhenNothingPending() {
        var model = LabModel()
        model.runNextCheck()
        XCTAssertFalse(model.runNextCheck())
        XCTAssertEqual(model.passed, 3)
    }
}
