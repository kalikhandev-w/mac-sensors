import Foundation

/// Aggregated CPU tick counters over all cores (from host_processor_info).
public struct CPUTicks: Equatable {
    public var user: UInt64
    public var system: UInt64
    public var idle: UInt64
    public var nice: UInt64

    public init(user: UInt64 = 0, system: UInt64 = 0, idle: UInt64 = 0, nice: UInt64 = 0) {
        self.user = user
        self.system = system
        self.idle = idle
        self.nice = nice
    }

    var total: UInt64 { user + system + idle + nice }
}

public struct Fan: Equatable {
    public let rpm: Double
    public let min: Double?
    public let max: Double?

    public init(rpm: Double, min: Double?, max: Double?) {
        self.rpm = rpm
        self.min = min
        self.max = max
    }
}

public struct Snapshot {
    public var cpuTemp: Double?
    public var gpuTemp: Double?
    public var fans: [Fan] = []
    public var cpuLoad: Double?
    public var gpuLoad: Double?
    public var memUsed: UInt64 = 0
    public var memTotal: UInt64 = 0
    /// kern.memorystatus_vm_pressure_level: 1 normal, 2 warn, 4 critical.
    public var memPressure: Int = 1
    public var smcAvailable: Bool = false

    public init() {}
}

/// Busy percentage between two tick samples. nil when either sample is missing,
/// when no time passed, or when counters went backwards.
public func cpuLoadPercent(prev: CPUTicks?, cur: CPUTicks?) -> Double? {
    guard let prev, let cur else { return nil }
    guard cur.total > prev.total, cur.idle >= prev.idle else { return nil }
    let total = cur.total - prev.total
    let idle = cur.idle - prev.idle
    return (1.0 - Double(idle) / Double(total)) * 100.0
}

public func maxTemp(_ values: [Double?]) -> Double? {
    values.compactMap { $0 }.max()
}
