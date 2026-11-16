import Foundation

/// Pure, UI-free model so the logic can be unit-tested on any platform
/// (including `swift test` on a Mac, and XCTest in CI).
struct LabCheck: Identifiable, Equatable {
    enum Status: String {
        case pass
        case pending
    }

    let id: String
    let title: String
    let detail: String
    var status: Status
}

struct LabModel {
    private(set) var checks: [LabCheck]

    init(checks: [LabCheck] = LabModel.defaultChecks) {
        self.checks = checks
    }

    static let defaultChecks: [LabCheck] = [
        LabCheck(id: "build", title: "Build", detail: "xcodebuild 26 · iOS Simulator", status: .pass),
        LabCheck(id: "tests", title: "Unit tests", detail: "XCTest bundle", status: .pass),
        LabCheck(id: "render", title: "Render", detail: "SwiftUI · 393 × 852 pt", status: .pending),
    ]

    var passed: Int { checks.filter { $0.status == .pass }.count }
    var total: Int { checks.count }
    var summary: String { "\(passed)/\(total) checks passing" }

    /// Promotes the first pending check to passing; returns true when it did.
    @discardableResult
    mutating func runNextCheck() -> Bool {
        guard let index = checks.firstIndex(where: { $0.status == .pending }) else { return false }
        checks[index].status = .pass
        return true
    }
}
