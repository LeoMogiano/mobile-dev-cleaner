import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("ByteFormatter")
struct ByteFormatterTests {
    private let esLocale = Locale(identifier: "es_BO")
    private let enLocale = Locale(identifier: "en_US")

    @Test("es: 0 bytes")
    func esZeroBytes() {
        let result = ByteFormatter.string(0, locale: esLocale)
        #expect(result == "0 MB")
    }

    @Test("es: less than 1 MB")
    func esLessThanOneMB() {
        let bytes = 500_000 // 0.5 MB (500 KB), rounds to 1 MB
        let result = ByteFormatter.string(Int64(bytes), locale: esLocale)
        #expect(result == "1 MB")
    }

    @Test("es: exactly 1 MB")
    func esExactlyOneMB() {
        let bytes = 1_000_000 // 1 MB
        let result = ByteFormatter.string(Int64(bytes), locale: esLocale)
        #expect(result == "1 MB")
    }

    @Test("es: 500 MB")
    func esFiveHundredMB() {
        let bytes = 500_000_000 // 500 MB
        let result = ByteFormatter.string(Int64(bytes), locale: esLocale)
        #expect(result == "500 MB")
    }

    @Test("es: 999 MB (less than 1 GB)")
    func esNineHundredNinetyNineMB() {
        let bytes: Int64 = 999_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "999 MB")
    }

    @Test("es: exactly 1 GB")
    func esExactlyOneGB() {
        let bytes: Int64 = 1_000_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "1,0 GB")
    }

    @Test("es: 1.5 GB")
    func esOnePointFiveGB() {
        let bytes: Int64 = 1_500_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "1,5 GB")
    }

    @Test("es: 18.2 GB (design example)")
    func esEighteenPointTwoGB() {
        let bytes: Int64 = 18_200_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "18,2 GB")
    }

    @Test("es: 6.1 GB")
    func esSixPointOneGB() {
        let bytes: Int64 = 6_100_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "6,1 GB")
    }

    @Test("es: 37.7 GB")
    func esThirtySevenPointSevenGB() {
        let bytes: Int64 = 37_700_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "37,7 GB")
    }

    @Test("es: TB scale (1.5 TB)")
    func esOnePointFiveTB() {
        let bytes: Int64 = 1_500_000_000_000
        let result = ByteFormatter.string(bytes, locale: esLocale)
        #expect(result == "1500,0 GB")
    }

    @Test("en: 0 bytes")
    func enZeroBytes() {
        let result = ByteFormatter.string(0, locale: enLocale)
        #expect(result == "0 MB")
    }

    @Test("en: exactly 1 MB")
    func enExactlyOneMB() {
        let bytes = 1_000_000 // 1 MB
        let result = ByteFormatter.string(Int64(bytes), locale: enLocale)
        #expect(result == "1 MB")
    }

    @Test("en: 500 MB")
    func enFiveHundredMB() {
        let bytes = 500_000_000 // 500 MB
        let result = ByteFormatter.string(Int64(bytes), locale: enLocale)
        #expect(result == "500 MB")
    }

    @Test("en: exactly 1 GB")
    func enExactlyOneGB() {
        let bytes: Int64 = 1_000_000_000
        let result = ByteFormatter.string(bytes, locale: enLocale)
        #expect(result == "1.0 GB")
    }

    @Test("en: 18.2 GB (design example)")
    func enEighteenPointTwoGB() {
        let bytes: Int64 = 18_200_000_000
        let result = ByteFormatter.string(bytes, locale: enLocale)
        #expect(result == "18.2 GB")
    }

    @Test("en: 6.1 GB")
    func enSixPointOneGB() {
        let bytes: Int64 = 6_100_000_000
        let result = ByteFormatter.string(bytes, locale: enLocale)
        #expect(result == "6.1 GB")
    }

    @Test("parts: es 18.2 GB separated")
    func partesEsEighteenPointTwo() {
        let bytes: Int64 = 18_200_000_000
        let (value, unit) = ByteFormatter.parts(bytes, locale: esLocale)
        #expect(value == "18,2")
        #expect(unit == "GB")
    }

    @Test("parts: es 500 MB separated")
    func partesEsFiveHundredMB() {
        let bytes: Int64 = 500_000_000
        let (value, unit) = ByteFormatter.parts(bytes, locale: esLocale)
        #expect(value == "500")
        #expect(unit == "MB")
    }

    @Test("parts: en 1 GB separated")
    func partesEnOneGB() {
        let bytes: Int64 = 1_000_000_000
        let (value, unit) = ByteFormatter.parts(bytes, locale: enLocale)
        #expect(value == "1.0")
        #expect(unit == "GB")
    }

    @Test("parts: en 0 MB separated")
    func partesEnZero() {
        let (value, unit) = ByteFormatter.parts(0, locale: enLocale)
        #expect(value == "0")
        #expect(unit == "MB")
    }

    @Test("Perf: 100k calls < 0.5 s")
    func performanceTest() throws {
        let clock = ContinuousClock()
        let testBytes: [Int64] = [
            0,
            500_000,
            1_000_000,
            500_000_000,
            1_000_000_000,
            18_200_000_000,
            1_500_000_000_000
        ]

        let elapsed = clock.measure {
            for _ in 0..<(100_000 / testBytes.count) {
                for bytes in testBytes {
                    _ = ByteFormatter.string(bytes, locale: esLocale)
                    _ = ByteFormatter.string(bytes, locale: enLocale)
                }
            }
        }

        #expect(elapsed < .milliseconds(500))
    }
}
