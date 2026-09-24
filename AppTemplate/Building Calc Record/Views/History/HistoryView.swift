import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \CalculationRecord.createdAt, order: .reverse) private var records: [CalculationRecord]

    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all
    @FocusState private var isSearchFocused: Bool

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case mixes = "Mixes"
        case paint = "Paint"
        case tiles = "Tiles"
        case wallpaper = "Wallpaper"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    searchBar
                    statsRow
                    spendingSection
                    filterChips
                    recordsList
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .background(AppTheme.screenBackground(colorScheme))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    appState.startNewCalculation(defaultWaste: settings.defaultWastePercent)
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(AppTheme.yellow)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(24)
            }
            .navigationDestination(for: UUID.self) { recordID in
                if let record = records.first(where: { $0.id == recordID }) {
                    SavedResultView(record: record)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            TextField("Search calculations...", text: $searchText)
                .foregroundStyle(Color.black)
                .focused($isSearchFocused)
                .submitLabel(.search)
            if !searchText.isEmpty || isSearchFocused {
                Button {
                    searchText = ""
                    isSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(value: "\(records.count)", label: "Total calcs", color: AppTheme.yellow)
            miniStat(value: CalculationEngine.formatArea(totalArea, system: settings.unitSystem), label: "Total area", color: .primary)
            miniStat(value: settings.formatMoney(totalCost), label: "Est. cost", color: AppTheme.green)
        }
    }

    private var spendingSection: some View {
        let spending = materialSpending
        let maxSpend = spending.map(\.amount).max() ?? 1
        return VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Material")
                .font(.headline)
            ForEach(spending, id: \.name) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        Text(settings.formatMoney(item.amount))
                            .font(.subheadline.weight(.semibold))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.15))
                            Capsule()
                                .fill(item.color)
                                .frame(width: max(8, geo.size.width * item.amount / maxSpend))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding()
        .foregroundStyle(Color.black)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(HistoryFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? AppTheme.yellow : Color.white)
                            .foregroundStyle(Color.black)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: selectedFilter == filter ? 0 : 1))
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .padding(.horizontal, -20)
    }

    private var recordsList: some View {
        VStack(spacing: 12) {
            if filteredRecords.isEmpty {
                Text("No calculations yet. Start your first estimate.")
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
            ForEach(filteredRecords) { record in
                NavigationLink(value: record.id) {
                    HistoryCard(record: record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filteredRecords: [CalculationRecord] {
        records.filter { record in
            let matchesSearch = searchText.isEmpty
                || record.materialName.localizedCaseInsensitiveContains(searchText)
                || record.surface.rawValue.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool = {
                switch selectedFilter {
                case .all: return true
                case .mixes: return record.category == .mixes
                case .paint: return record.category == .paint || record.category == .primer
                case .tiles: return record.category == .tiles
                case .wallpaper: return record.category == .wallpaper
                }
            }()
            return matchesSearch && matchesFilter
        }
    }

    private var totalArea: Double { records.reduce(0) { $0 + $1.areaSquareMeters } }
    private var totalCost: Double { records.reduce(0) { $0 + $1.totalCost } }

    private struct SpendItem {
        let name: String
        let amount: Double
        let color: Color
    }

    private var materialSpending: [SpendItem] {
        var dict: [String: Double] = [:]
        for r in records {
            dict[r.materialName, default: 0] += r.totalCost
        }
        let colors: [Color] = [AppTheme.yellow, AppTheme.green, AppTheme.orange, Color.black]
        return dict.sorted { $0.value > $1.value }.enumerated().map { index, pair in
            SpendItem(name: pair.key, amount: pair.value, color: colors[index % colors.count])
        }
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color == .primary ? Color.black : color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .foregroundStyle(Color.black)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct HistoryCard: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    let record: CalculationRecord

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Text(record.category.icon)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(AppTheme.yellow.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.materialName)
                        .font(.headline)
                        .foregroundStyle(Color.black)
                    Text(record.surface.rawValue)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(record.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            HStack {
                metricBox(value: CalculationEngine.formatMeasure(record.areaSquareMeters, category: record.category, system: settings.unitSystem), label: "Area")
                metricBox(value: "\(record.packages) \(Catalog.packageLabel(for: record.materialName))", label: "Packages")
                metricBox(value: settings.formatMoney(record.totalCost, currencyCode: record.currencyCode), label: "Cost", green: true)
            }
        }
        .padding()
        .foregroundStyle(Color.black)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private func metricBox(value: String, label: String, green: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(green ? AppTheme.green : Color.black)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(AppTheme.screenBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
