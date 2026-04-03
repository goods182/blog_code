import Foundation

/// Live rowing metrics decoded from the FTMS Rower Data characteristic (0x2AD1)
struct RowingData {
    var strokeRate: Double = 0       // strokes per minute
    var strokeCount: Int = 0         // total strokes this session
    var distanceMeters: Double = 0   // total meters rowed
    var instantPace: Double = 0      // seconds per 500m
    var instantPower: Int = 0        // watts
    var calories: Int = 0            // kcal
    var elapsedSeconds: Int = 0      // session duration
    var resistanceLevel: Int = 0     // 1–16 on Yosuda Plus

    static let zero = RowingData()
}

/// A completed workout snapshot stored for history and achievements
struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let durationSeconds: Int
    let distanceMeters: Double
    let strokeCount: Int
    let calories: Int
    let averageStrokeRate: Double
    let maxStrokeRate: Double
    let averagePower: Int
    let pointsEarned: Int

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedDistance: String {
        if distanceMeters >= 1000 {
            return String(format: "%.2f km", distanceMeters / 1000)
        }
        return String(format: "%.0f m", distanceMeters)
    }
}

/// Defines a single in-app achievement/badge
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String        // SF Symbol name
    let category: AchievementCategory
    let requiredValue: Double
    var isUnlocked: Bool
    var unlockedDate: Date?

    enum AchievementCategory: String, Codable {
        case distance, strokes, calories, streak, power, duration
    }
}

/// Active challenge the user can work toward
struct Challenge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetValue: Double
    let metric: ChallengeMetric
    var currentValue: Double
    let expiresAt: Date?
    let pointReward: Int

    var progress: Double {
        min(currentValue / targetValue, 1.0)
    }

    var isComplete: Bool {
        currentValue >= targetValue
    }

    enum ChallengeMetric: String, Codable {
        case distance, strokes, calories, duration
    }
}
