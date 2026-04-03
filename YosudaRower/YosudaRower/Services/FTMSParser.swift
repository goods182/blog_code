import Foundation

/// Parses the FTMS Rower Data characteristic (UUID 0x2AD1) per Bluetooth SIG spec.
/// Flags field is a 16-bit little-endian bitmask controlling which optional fields follow.
enum FTMSParser {

    // MARK: – Flag bit positions (Bluetooth SIG FTMS §4.8.1.1)
    private struct Flags {
        static let moreData            = 0      // bit 0: if 0, stroke rate & count present
        static let averageStrokeRate   = 1
        static let totalDistance       = 2
        static let instantaneousPace   = 3
        static let averagePace         = 4
        static let instantaneousPower  = 5
        static let averagePower        = 6
        static let resistanceLevel     = 7
        static let expendedEnergy      = 8
        static let heartRate           = 9
        static let metabolicEquivalent = 10
        static let elapsedTime         = 11
        static let remainingTime       = 12
    }

    /// Parse raw BLE notification bytes into a `RowingData` value.
    /// Returns nil when the payload is too short or malformed.
    static func parse(_ data: Data) -> RowingData? {
        guard data.count >= 4 else { return nil }

        var offset = 0
        var result = RowingData()

        // Flags (2 bytes, little-endian)
        let flags = UInt16(data[0]) | (UInt16(data[1]) << 8)
        offset = 2

        func bit(_ position: Int) -> Bool {
            (flags & (1 << position)) != 0
        }

        // Stroke rate (uint8, 0.5 /min resolution) + stroke count (uint16 LE)
        // present when bit 0 (More Data) is NOT set
        if !bit(Flags.moreData) {
            guard offset + 3 <= data.count else { return result }
            result.strokeRate = Double(data[offset]) * 0.5
            offset += 1
            result.strokeCount = Int(UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8))
            offset += 2
        }

        if bit(Flags.averageStrokeRate) {
            guard offset + 1 <= data.count else { return result }
            // skip average stroke rate (uint8)
            offset += 1
        }

        if bit(Flags.totalDistance) {
            guard offset + 3 <= data.count else { return result }
            // uint24 little-endian, 1-meter resolution
            let d = UInt32(data[offset])
                  | (UInt32(data[offset + 1]) << 8)
                  | (UInt32(data[offset + 2]) << 16)
            result.distanceMeters = Double(d)
            offset += 3
        }

        if bit(Flags.instantaneousPace) {
            guard offset + 2 <= data.count else { return result }
            // uint16 LE, 0.01 s/m resolution → convert to s/500m
            let rawPace = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
            let secondsPerMeter = Double(rawPace) * 0.01
            result.instantPace = secondsPerMeter * 500.0
            offset += 2
        }

        if bit(Flags.averagePace) {
            guard offset + 2 <= data.count else { return result }
            offset += 2  // skip
        }

        if bit(Flags.instantaneousPower) {
            guard offset + 2 <= data.count else { return result }
            result.instantPower = Int(Int16(bitPattern:
                UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)))
            offset += 2
        }

        if bit(Flags.averagePower) {
            guard offset + 2 <= data.count else { return result }
            offset += 2  // skip
        }

        if bit(Flags.resistanceLevel) {
            guard offset + 2 <= data.count else { return result }
            result.resistanceLevel = Int(Int16(bitPattern:
                UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)))
            offset += 2
        }

        if bit(Flags.expendedEnergy) {
            guard offset + 6 <= data.count else { return result }
            // Total energy (uint16 LE, kcal), energy/hour (uint16 LE), energy/min (uint8)
            result.calories = Int(UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8))
            offset += 6
        }

        if bit(Flags.heartRate) {
            guard offset + 1 <= data.count else { return result }
            offset += 1  // skip
        }

        if bit(Flags.metabolicEquivalent) {
            guard offset + 1 <= data.count else { return result }
            offset += 1  // skip
        }

        if bit(Flags.elapsedTime) {
            guard offset + 2 <= data.count else { return result }
            result.elapsedSeconds = Int(UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8))
            offset += 2
        }

        return result
    }
}
