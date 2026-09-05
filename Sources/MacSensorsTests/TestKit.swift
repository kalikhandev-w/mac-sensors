import Foundation

var testPasses = 0
var testFailures = 0

func check(_ condition: Bool, _ message: String, file: String = #fileID, line: Int = #line) {
    if condition {
        testPasses += 1
    } else {
        testFailures += 1
        print("FAIL \(file):\(line): \(message)")
    }
}

func checkEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String = "",
                              file: String = #fileID, line: Int = #line) {
    check(actual == expected, "\(label) expected \(expected), got \(actual)", file: file, line: line)
}

func checkClose(_ actual: Double?, _ expected: Double, tolerance: Double = 0.01, _ label: String = "",
                file: String = #fileID, line: Int = #line) {
    guard let actual else {
        check(false, "\(label) expected \(expected), got nil", file: file, line: line)
        return
    }
    check(abs(actual - expected) <= tolerance,
          "\(label) expected \(expected) ± \(tolerance), got \(actual)", file: file, line: line)
}

func finish() -> Never {
    print("\(testPasses) passed, \(testFailures) failed")
    exit(testFailures == 0 ? 0 : 1)
}
