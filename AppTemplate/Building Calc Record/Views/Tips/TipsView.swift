import SwiftUI

struct TipsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedFilter: TipFilter = .all
    @State private var showFavoritesOnly = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    statsRow
                    filterChips
                    tipsList
                }
                .padding(20)
            }
            .background(AppTheme.screenBackground(colorScheme))
            .navigationTitle("Tips Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .foregroundStyle(AppTheme.yellow)
                    }
                    .accessibilityLabel(showFavoritesOnly ? "Show all tips" : "Show favorites only")
                }
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            tipStat(value: "\(Catalog.tips.count)", label: "Tips total", bg: AppTheme.yellow.opacity(0.35))
            tipStat(value: "\(settings.favoriteTipIDs.count)", label: "Favorited", bg: AppTheme.green.opacity(0.25))
            tipStat(value: "7", label: "Categories", bg: Color.white)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TipFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? AppTheme.yellow : Color.white)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.gray.opacity(0.2), lineWidth: selectedFilter == filter ? 0 : 1))
                    }
                }
            }
        }
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .padding(.horizontal, -20)
    }

    private var tipsList: some View {
        VStack(spacing: 12) {
            ForEach(filteredTips) { tip in
                TipCard(tip: tip)
            }
        }
    }

    private var filteredTips: [TipItem] {
        Catalog.tips.filter { tip in
            let filterMatch = selectedFilter == .all || tip.filter == selectedFilter
            let favMatch = !showFavoritesOnly || settings.isFavorite(tipID: tip.id)
            return filterMatch && favMatch
        }
    }

    private func tipStat(value: String, label: String, bg: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct TipCard: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    let tip: TipItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(iconForFilter(tip.filter))
                    .frame(width: 40, height: 40)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 6) {
                    Text(tip.title)
                        .font(.headline)
                        .foregroundStyle(Color.black)
                    HStack(spacing: 6) {
                        tag(tip.categoryTag, bg: Color.gray.opacity(0.15), fg: AppTheme.secondaryText(colorScheme))
                        tag(tip.topicTag, bg: AppTheme.yellow.opacity(0.35), fg: AppTheme.orange)
                    }
                }
                Spacer()
                Button {
                    settings.toggleFavorite(tipID: tip.id)
                } label: {
                    Image(systemName: settings.isFavorite(tipID: tip.id) ? "star.fill" : "star")
                        .foregroundStyle(settings.isFavorite(tipID: tip.id) ? AppTheme.yellow : .gray)
                }
            }
            Text(tip.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .padding()
        .foregroundStyle(Color.black)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private func tag(_ text: String, bg: Color, fg: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .foregroundStyle(fg)
            .clipShape(Capsule())
    }

    private func iconForFilter(_ filter: TipFilter) -> String {
        switch filter {
        case .plaster: "🏗️"
        case .paint: "🎨"
        case .tiles: "🧩"
        case .flooring: "📐"
        case .all: "💡"
        }
    }
}
