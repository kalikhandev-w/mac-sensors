import Darwin
import Foundation
import IOKit

/// Reads every metric in one pass. Probes which SMC keys exist once at init.
public final class SensorProvider {
    // Apple Silicon (M1 Pro verified). Missing keys are filtered out at init.
    static let cpuTempCandidates = ["Tp01", "Tp05", "Tp09", "Tp0D", "Tp0H", "Tp0L", "Tp0P", "Tp0T", "Tp0X", "Tp0b"]
    static let gpuTempCandidates = ["Tg05", "Tg0D", "Tg0L", "Tg0T"]
    /// A previous CPU sample older than this is discarded so a reopened panel does not
    /// show load averaged over minutes.
    static let maxTickAge: TimeInterval = 5

    private let smc: SMC?
    private let cpuTempKeys: [String]
    private let gpuTempKeys: [String]
    private let fanCount: Int
    private let memTotal: UInt64
    private var prevTicks: CPUTicks?
    private var prevTickTime: Date?

    public init() {
        let smc = SMC()
        if smc == nil {
            FileHandle.standardError.write(Data("MacSensors: AppleSMC unavailable\n".utf8))
        }
        self.smc = smc
        cpuTempKeys = Self.cpuTempCandidates.filter { smc?.readDouble($0) != nil }
        gpuTempKeys = Self.gpuTempCandidates.filter { smc?.readDouble($0) != nil }
        fanCount = Int(smc?.read("FNum")?.bytes.first ?? 0)
        memTotal = Self.sysctlUInt64("hw.memsize") ?? 0
    }

    public func sample() -> Snapshot {
        var s = Snapshot()
        s.smcAvailable = smc != nil
        s.cpuTemp = maxTemp(cpuTempKeys.map { smc?.readDouble($0) })
        s.gpuTemp = maxTemp(gpuTempKeys.map { smc?.readDouble($0) })
        s.fans = (0..<fanCount).compactMap { i in
            guard let rpm = smc?.readDouble("F\(i)Ac") else { return nil }
            return Fan(rpm: rpm, min: smc?.readDouble("F\(i)Mn"), max: smc?.readDouble("F\(i)Mx"))
        }

        let now = Date()
        if let t = prevTickTime, now.timeIntervalSince(t) > Self.maxTickAge {
            prevTicks = nil
        }
        let ticks = Self.readCPUTicks()
        s.cpuLoad = cpuLoadPercent(prev: prevTicks, cur: ticks)
        prevTicks = ticks
        prevTickTime = now

        s.gpuLoad = Self.readGPUUtilization()
        s.memUsed = Self.readMemoryUsed() ?? 0
        s.memTotal = memTotal
        s.memPressure = Self.sysctlInt32("kern.memorystatus_vm_pressure_level") ?? 1
        return s
    }

    // MARK: - Mach / IOKit readers

    static func readCPUTicks() -> CPUTicks? {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        guard host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount) == KERN_SUCCESS,
              let info else { return nil }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info),
                          vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }
        var t = CPUTicks()
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * Int(CPU_STATE_MAX)
            t.user += UInt64(info[base + Int(CPU_STATE_USER)])
            t.system += UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            t.idle += UInt64(info[base + Int(CPU_STATE_IDLE)])
            t.nice += UInt64(info[base + Int(CPU_STATE_NICE)])
        }
        return t
    }

    static func readGPUUtilization() -> Double? {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOAccelerator"), &iterator) == kIOReturnSuccess else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        var result: Double?
        var entry = IOIteratorNext(iterator)
        while entry != 0 {
            if result == nil,
               let stats = IORegistryEntryCreateCFProperty(entry, "PerformanceStatistics" as CFString, kCFAllocatorDefault, 0)?
                   .takeRetainedValue() as? [String: Any],
               let util = stats["Device Utilization %"] as? Int {
                result = Double(util)
            }
            IOObjectRelease(entry)
            entry = IOIteratorNext(iterator)
        }
        return result
    }

    /// Active + wired + compressed pages, roughly Activity Monitor's "Memory Used".
    static func readMemoryUsed() -> UInt64? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let rc = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard rc == KERN_SUCCESS else { return nil }
        let pages = UInt64(stats.active_count) + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)
        return pages * UInt64(vm_kernel_page_size)
    }

    static func sysctlUInt64(_ name: String) -> UInt64? {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? value : nil
    }

    static func sysctlInt32(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? Int(value) : nil
    }
}
