import Foundation
import IOKit

/// User-space client for the AppleSMC kext. One connection per instance; keep one for the app's lifetime.
public final class SMC {
    public struct Value {
        public let type: String
        public let bytes: [UInt8]
    }

    private let connection: io_connect_t

    // SMCKeyData_t is an 80-byte C struct. We write it as a raw buffer at fixed offsets
    // (verified with offsetof on macOS 26 / arm64) instead of trusting Swift struct layout.
    private static let structSize = 80
    private enum Offset {
        static let key = 0
        static let dataSize = 28
        static let dataType = 32
        static let result = 40
        static let data8 = 42
        static let bytes = 48
    }
    private static let selectorHandleYPCEvent: UInt32 = 2
    private static let cmdReadKeyInfo: UInt8 = 9
    private static let cmdReadBytes: UInt8 = 5

    public init?() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var conn: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &conn) == kIOReturnSuccess else { return nil }
        connection = conn
    }

    deinit { IOServiceClose(connection) }

    public func read(_ key: String) -> Value? {
        guard let code = SMCDecode.fourCC(key) else { return nil }

        var infoQuery = [UInt8](repeating: 0, count: SMC.structSize)
        SMC.store32(&infoQuery, Offset.key, code)
        infoQuery[Offset.data8] = SMC.cmdReadKeyInfo
        guard let info = call(infoQuery), info[Offset.result] == 0 else { return nil }
        let size = Int(SMC.load32(info, Offset.dataSize))
        let typeCode = SMC.load32(info, Offset.dataType)
        guard size > 0, size <= 32 else { return nil }

        var readQuery = [UInt8](repeating: 0, count: SMC.structSize)
        SMC.store32(&readQuery, Offset.key, code)
        SMC.store32(&readQuery, Offset.dataSize, UInt32(size))
        readQuery[Offset.data8] = SMC.cmdReadBytes
        guard let out = call(readQuery), out[Offset.result] == 0 else { return nil }

        return Value(type: SMCDecode.typeString(typeCode),
                     bytes: Array(out[Offset.bytes ..< Offset.bytes + size]))
    }

    public func readDouble(_ key: String) -> Double? {
        guard let v = read(key) else { return nil }
        return SMCDecode.value(type: v.type, bytes: v.bytes)
    }

    private func call(_ input: [UInt8]) -> [UInt8]? {
        var output = [UInt8](repeating: 0, count: SMC.structSize)
        var outSize = SMC.structSize
        let rc = input.withUnsafeBytes { inPtr in
            output.withUnsafeMutableBytes { outPtr in
                IOConnectCallStructMethod(connection, SMC.selectorHandleYPCEvent,
                                          inPtr.baseAddress, input.count,
                                          outPtr.baseAddress, &outSize)
            }
        }
        return rc == kIOReturnSuccess ? output : nil
    }

    private static func store32(_ buf: inout [UInt8], _ offset: Int, _ value: UInt32) {
        buf.withUnsafeMutableBytes { $0.storeBytes(of: value, toByteOffset: offset, as: UInt32.self) }
    }

    private static func load32(_ buf: [UInt8], _ offset: Int) -> UInt32 {
        buf.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self) }
    }
}
