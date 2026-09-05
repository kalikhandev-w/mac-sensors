import Foundation

public enum Format {
    public static let missing = "—"

    public static func temp(_ v: Double?) -> String {
        guard let v else { return missing }
        return String(format: "%.0f°", v)
    }

    public static func percent(_ v: Double?) -> String {
        guard let v else { return missing }
        return String(format: "%.0f %%", v)
    }

    public static func fans(_ fans: [Fan]) -> String {
        guard !fans.isEmpty else { return missing }
        return fans.map { String(format: "%.0f", $0.rpm) }.joined(separator: " · ") + " rpm"
    }

    public static func memory(used: UInt64, total: UInt64) -> String {
        guard total > 0 else { return missing }
        let gib = Double(1 << 30)
        return String(format: "%.1f / %.0f GB", Double(used) / gib, Double(total) / gib)
    }

    public static func pressure(_ level: Int) -> String {
        switch level {
        case 1: return "normal"
        case 2: return "warn"
        case 4: return "critical"
        default: return missing
        }
    }
}
