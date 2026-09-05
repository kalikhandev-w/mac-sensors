import Foundation
import MacSensorsCore

// `--dump`: two samples one second apart, print the second. Used for manual verification.
if CommandLine.arguments.contains("--dump") {
    let provider = SensorProvider()
    _ = provider.sample()
    Thread.sleep(forTimeInterval: 1)
    dump(provider.sample())
    exit(0)
}

print("MacSensors: run with --dump (UI arrives in the next task)")
