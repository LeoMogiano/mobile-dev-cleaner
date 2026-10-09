import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("CategoryInfo")
struct CategoryInfoTests {
    @Test("every category has non-empty fields")
    func everyFieldPopulated() {
        for categoryID in CategoryID.allCases {
            let info = CategoryInfo.info(for: categoryID)
            #expect(!info.name.isEmpty, "name is empty for \(categoryID)")
            #expect(!info.technicalName.isEmpty, "technicalName is empty for \(categoryID)")
            #expect(!info.displayPath.isEmpty, "displayPath is empty for \(categoryID)")
            #expect(!info.symbol.isEmpty, "symbol is empty for \(categoryID)")
            #expect(!info.whatIsIt.isEmpty, "whatIsIt is empty for \(categoryID)")
            #expect(!info.ifDeleted.isEmpty, "ifDeleted is empty for \(categoryID)")
            #expect(!info.comesBack.isEmpty, "comesBack is empty for \(categoryID)")
        }
    }

    @Test("only runtimes needs full disk access")
    func onlyRuntimesNeedsFda() {
        for categoryID in CategoryID.allCases {
            let info = CategoryInfo.info(for: categoryID)
            if categoryID == .runtimes {
                #expect(info.needsFullDiskAccess == true)
            } else {
                #expect(info.needsFullDiskAccess == false)
            }
        }
    }

    @Test("builds category has hammer symbol")
    func buildsSymbol() {
        let info = CategoryInfo.info(for: .builds)
        #expect(info.symbol == "hammer")
    }

    @Test("runtimes has correct display path")
    func runtimesPath() {
        let info = CategoryInfo.info(for: .runtimes)
        #expect(info.displayPath == "/Library/Developer/CoreSimulator/Profiles/Runtimes")
        #expect(info.technicalName.contains("CoreSimulator/Runtimes"))
    }

    @Test("tests has correct technical name")
    func testsName() {
        let info = CategoryInfo.info(for: .tests)
        #expect(info.technicalName.contains("XCTestDevices"))
        #expect(info.displayPath.contains("XCTestDevices"))
    }
}
