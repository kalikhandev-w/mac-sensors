import MacSensorsCore
import SwiftUI

struct PanelView: View {
    var model: PanelModel
    var quit: () -> Void

    private static let hotTemp = 90.0
    private static let smcUnavailable = "SMC unavailable"

    var body: some View {
        let s = model.snapshot
        VStack(alignment: .leading, spacing: 8) {
            row(icon: "thermometer.medium", label: "CPU",
                primary: s.smcAvailable ? Format.temp(s.cpuTemp) : Self.smcUnavailable,
                secondary: Format.percent(s.cpuLoad),
                hot: (s.cpuTemp ?? 0) >= Self.hotTemp)
            row(icon: "cpu", label: "GPU",
                primary: s.smcAvailable ? Format.temp(s.gpuTemp) : Self.smcUnavailable,
                secondary: Format.percent(s.gpuLoad),
                hot: (s.gpuTemp ?? 0) >= Self.hotTemp)
            row(icon: "fanblades", label: "Fans",
                primary: s.smcAvailable ? Format.fans(s.fans) : Self.smcUnavailable,
                secondary: "",
                hot: false)
            row(icon: "memorychip", label: "Memory",
                primary: Format.memory(used: s.memUsed, total: s.memTotal),
                secondary: Format.pressure(s.memPressure),
                hot: s.memPressure >= 2)
            Divider()
            HStack {
                Spacer()
                Button("Quit", action: quit)
            }
        }
        .padding(12)
        .frame(width: 300)
        .font(.system(.body, design: .monospaced))
    }

    private func row(icon: String, label: String, primary: String, secondary: String, hot: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).frame(width: 18)
            Text(label).frame(width: 60, alignment: .leading)
            Text(primary).foregroundStyle(hot ? .red : .primary).lineLimit(1).fixedSize()
            Spacer(minLength: 8)
            Text(secondary).foregroundStyle(.secondary).lineLimit(1).fixedSize()
        }
    }
}
