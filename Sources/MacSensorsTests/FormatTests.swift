import MacSensorsCore

func runFormatTests() {
    checkEqual(Format.temp(59.4), "59°", "temp rounds")
    checkEqual(Format.temp(59.6), "60°", "temp rounds up")
    checkEqual(Format.temp(nil), "—", "temp nil")

    checkEqual(Format.percent(44.44), "44 %", "percent")
    checkEqual(Format.percent(nil), "—", "percent nil")

    checkEqual(Format.fans([Fan(rpm: 2326, min: nil, max: nil), Fan(rpm: 2509.4, min: nil, max: nil)]),
               "2326 · 2509 rpm", "two fans")
    checkEqual(Format.fans([Fan(rpm: 1200, min: nil, max: nil)]), "1200 rpm", "one fan")
    checkEqual(Format.fans([]), "—", "no fans")

    let gib: UInt64 = 1 << 30
    checkEqual(Format.memory(used: UInt64(12.3 * Double(gib)), total: 16 * gib), "12.3 / 16 GB", "memory")
    checkEqual(Format.memory(used: 0, total: 0), "—", "memory unknown total")

    checkEqual(Format.pressure(1), "normal", "pressure 1")
    checkEqual(Format.pressure(2), "warn", "pressure 2")
    checkEqual(Format.pressure(4), "critical", "pressure 4")
    checkEqual(Format.pressure(99), "—", "pressure unknown")
}
