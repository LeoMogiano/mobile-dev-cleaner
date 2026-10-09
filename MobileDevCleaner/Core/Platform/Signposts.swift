import os

/// Instruments intervals (Points of Interest). See the performance budgets in CLAUDE.md.
enum Signposts {
    static let subsystem = "com.leomogiano.MobileDevCleaner"
    static let scan = OSSignposter(subsystem: subsystem, category: "scan")
    static let size = OSSignposter(subsystem: subsystem, category: "size")
    static let cleanup = OSSignposter(subsystem: subsystem, category: "cleanup")
}
