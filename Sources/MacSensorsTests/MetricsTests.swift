import MacSensorsCore

func runMetricsTests() {
    // cpuLoadPercent: 220 total ticks, 100 idle → 44.44 % busy
    let prev = CPUTicks(user: 100, system: 50, idle: 800, nice: 0)
    let cur = CPUTicks(user: 160, system: 70, idle: 900, nice: 0)
    checkClose(cpuLoadPercent(prev: prev, cur: cur), 44.444, tolerance: 0.01, "cpu load")
    checkEqual(cpuLoadPercent(prev: nil, cur: cur), nil, "cpu load needs previous sample")
    checkEqual(cpuLoadPercent(prev: prev, cur: nil), nil, "cpu load needs current sample")
    checkEqual(cpuLoadPercent(prev: cur, cur: cur), nil, "cpu load zero delta → nil")
    checkEqual(cpuLoadPercent(prev: cur, cur: prev), nil, "cpu load counters went backwards → nil")
    checkClose(cpuLoadPercent(prev: prev, cur: CPUTicks(user: 100, system: 50, idle: 900, nice: 0)), 0, tolerance: 0.001, "fully idle → 0")
    checkClose(cpuLoadPercent(prev: prev, cur: CPUTicks(user: 200, system: 50, idle: 800, nice: 0)), 100, tolerance: 0.001, "fully busy → 100")

    checkClose(maxTemp([45.0, nil, 59.4, 57.0]), 59.4, tolerance: 0.001, "maxTemp skips nil")
    checkEqual(maxTemp([nil, nil]), nil, "maxTemp all nil")
    checkEqual(maxTemp([]), nil, "maxTemp empty")

    let s = Snapshot()
    checkEqual(s.fans.isEmpty, true, "Snapshot default fans empty")
    checkEqual(s.memPressure, 1, "Snapshot default pressure normal")
    checkEqual(s.smcAvailable, false, "Snapshot default smcAvailable false")
}
