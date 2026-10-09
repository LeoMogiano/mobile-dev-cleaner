import Foundation
import Testing
@testable import MobileDevCleaner

@Suite("Sidebar sections")
@MainActor
struct SidebarSectionsTests {
    private func report(_ id: CategoryID, bytes: Int64, denied: Bool = false) -> CategoryReport {
        var report = CategoryReport(id: id, accessDenied: denied)
        if bytes > 0 {
            report.candidates = [CleanupCandidate(
            id: "\(id.rawValue)-1", category: id, name: "x", url: URL(fileURLWithPath: "/tmp/\(id.rawValue)"),
            size: bytes, risk: .regenerates, group: nil, isOrphan: false, modifiedAt: nil, reason: nil, cost: nil,
            execution: .remove(URL(fileURLWithPath: "/tmp/\(id.rawValue)"))
        )]
        }
        return report
    }

    private func all(_ sizes: [CategoryID: Int64]) -> [CategoryID: CategoryReport] {
        Dictionary(uniqueKeysWithValues: CategoryID.allCases.map { ($0, report($0, bytes: sizes[$0] ?? 0)) })
    }

    private func xcode(_ model: SidebarSections) -> SidebarSections.Section { model.sections[0] }

    @Test("only the 4 biggest rows show, in sidebar order; the rest collapse")
    func showsFourBiggest() {
        let reports = all([
            .builds: 5_000_000_000, .caches: 200_000_000, .tests: 10_000_000,
            .sims: 3_000_000_000, .devsup: 7_000_000_000, .archives: 900_000_000,
        ])
        let model = SidebarSections(reports: reports, pending: [], showEmpty: false, expanded: [])
        #expect(xcode(model).rows.map(\.id) == [.builds, .sims, .devsup, .archives])
        #expect(xcode(model).hiddenCount == 2)
        #expect(xcode(model).moreLabel == "2 más pequeñas")
    }

    @Test("expanded section shows every row and offers Menos")
    func expandedShowsAll() {
        let reports = all([
            .builds: 5_000_000_000, .caches: 200_000_000, .sims: 3_000_000_000,
            .devsup: 7_000_000_000, .archives: 900_000_000,
        ])
        let model = SidebarSections(reports: reports, pending: [], showEmpty: false, expanded: [.xcode])
        #expect(xcode(model).rows.map(\.id) == [.builds, .caches, .sims, .devsup, .archives])
        #expect(xcode(model).moreLabel == "Menos")
        #expect(xcode(model).hasMore)
    }

    @Test("selected small category stays visible")
    func selectedStaysVisible() {
        let reports = all([
            .builds: 5_000_000_000, .caches: 200_000_000, .sims: 3_000_000_000,
            .devsup: 7_000_000_000, .archives: 900_000_000,
        ])
        let model = SidebarSections(reports: reports, pending: [], showEmpty: false, expanded: [], selected: .caches)
        #expect(xcode(model).rows.map(\.id) == [.builds, .caches, .sims, .devsup, .archives])
    }

    @Test("empty categories hidden unless showEmpty")
    func emptyHiddenOrShown() {
        let reports = all([.builds: 5_000_000_000])
        let hidden = SidebarSections(reports: reports, pending: [], showEmpty: false, expanded: [.xcode])
        #expect(xcode(hidden).rows.map(\.id) == [.builds])
        let shown = SidebarSections(reports: reports, pending: [], showEmpty: true, expanded: [.xcode])
        #expect(xcode(shown).rows.count == 9)
        #expect(xcode(shown).rows.last?.state == .notFound)
        #expect(xcode(shown).rows.last?.sizeText == "No encontrado")
    }

    @Test("access denied shows Sin acceso")
    func accessDenied() {
        var reports = all([:])
        reports[.devsup] = report(.devsup, bytes: 0, denied: true)
        let model = SidebarSections(reports: reports, pending: [], showEmpty: false, expanded: [.xcode])
        let row = xcode(model).rows.first { $0.id == .devsup }
        #expect(row?.state == .noAccess)
        #expect(row?.sizeText == "Sin acceso")
    }

    @Test("sections follow category order with tool totals")
    func orderAndTotals() {
        let reports = all([.builds: 2_000_000_000, .pods: 1_000_000_000, .gcache: 3_000_000_000])
        let model = SidebarSections(reports: reports, pending: [], showEmpty: false, expanded: [], tools: [.xcode, .android])
        #expect(model.sections.map(\.title) == ["Xcode", "Android"])
        #expect(xcode(model).rows.map(\.id) == [.builds, .pods])
        #expect(xcode(model).total == ByteFormatter.string(3_000_000_000))
        #expect(model.sections[1].total == ByteFormatter.string(3_000_000_000))
    }

    @Test("scanning keeps the first 4 rows, ellipsis and no totals")
    func scanning() {
        let reports = [CategoryID.builds: report(.builds, bytes: 100)]
        let model = SidebarSections(reports: reports, pending: [.caches], showEmpty: false, expanded: [])
        #expect(xcode(model).total.isEmpty)
        #expect(xcode(model).rows.count == 4)
        #expect(xcode(model).hiddenCount == 5)
        #expect(xcode(model).rows.first { $0.id == .caches }?.sizeText == "…")
        #expect(xcode(model).rows.first { $0.id == .caches }?.state == .scanning)
    }

    @Test("non-applicable categories never show, even when showEmpty")
    func nonApplicableHidden() {
        /// Start with all xcode categories having 0 bytes
        let allReports = all([.builds: 0])
        var reports = allReports

        /// Mark the .builds category as not applicable
        var buildsReport = reports[.builds]!
        buildsReport.isApplicable = false
        reports[.builds] = buildsReport

        let model = SidebarSections(reports: reports, pending: [], showEmpty: true, expanded: [.xcode], tools: [.xcode])
        let xcodeSection = xcode(model)
        /// Even though builds is not applicable, all other categories should still show
        #expect(!xcodeSection.rows.contains { $0.id == .builds })
    }
}
