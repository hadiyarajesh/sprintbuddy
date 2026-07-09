import Foundation

final class Harness {
    private var failures: [String] = []
    private var passed = 0
    func expect(_ cond: Bool, _ msg: String) {
        if cond { passed += 1 } else { failures.append("FAIL: \(msg)") }
    }
    func expectEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String) {
        expect(a == b, "\(msg) (got \(a), want \(b))")
    }
    func summary() -> Never {
        if failures.isEmpty { print("ALL PASS (\(passed) checks)"); exit(0) }
        failures.forEach { print($0) }
        print("\(failures.count) FAILED, \(passed) passed"); exit(1)
    }
}
let t = Harness()
