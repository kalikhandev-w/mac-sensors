import Foundation

/// Pure helpers for AppleSMC key codes and value encodings.
public enum SMCDecode {
    /// Four ASCII chars → big-endian UInt32 as the SMC expects in the struct.
    public static func fourCC(_ s: String) -> UInt32? {
        let u = Array(s.utf8)
        guard u.count == 4 else { return nil }
        return UInt32(u[0]) << 24 | UInt32(u[1]) << 16 | UInt32(u[2]) << 8 | UInt32(u[3])
    }

    public static func typeString(_ code: UInt32) -> String {
        let chars: [UInt8] = [UInt8(code >> 24 & 0xff), UInt8(code >> 16 & 0xff),
                              UInt8(code >> 8 & 0xff), UInt8(code & 0xff)]
        return String(decoding: chars, as: UTF8.self)
    }

    /// "flt ": IEEE-754 single, little-endian.
    public static func flt(_ b: [UInt8]) -> Double? {
        guard b.count >= 4 else { return nil }
        let bits = UInt32(b[0]) | UInt32(b[1]) << 8 | UInt32(b[2]) << 16 | UInt32(b[3]) << 24
        return Double(Float(bitPattern: bits))
    }

    /// "sp78": signed fixed-point 8.8, big-endian.
    public static func sp78(_ b: [UInt8]) -> Double? {
        guard b.count >= 2 else { return nil }
        let raw = Int16(bitPattern: UInt16(b[0]) << 8 | UInt16(b[1]))
        return Double(raw) / 256.0
    }

    /// "fpe2": unsigned fixed-point 14.2, big-endian.
    public static func fpe2(_ b: [UInt8]) -> Double? {
        guard b.count >= 2 else { return nil }
        return Double(UInt16(b[0]) << 8 | UInt16(b[1])) / 4.0
    }

    public static func value(type: String, bytes: [UInt8]) -> Double? {
        switch type {
        case "flt ": return flt(bytes)
        case "sp78": return sp78(bytes)
        case "fpe2": return fpe2(bytes)
        default: return nil
        }
    }
}
