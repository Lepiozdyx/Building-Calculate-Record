import SwiftData
import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \CalculationRecord.createdAt, order: .reverse) private var records: [CalculationRecord]

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var firstName: String {
        settings.displayName.split(separator: " ").first.map(String.init) ?? settings.displayName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroCard
                    overviewSection
                    lastCalculationSection
                    quickActions
                    tipOfDay
                }
                .padding(20)
            }
            .background(AppTheme.screenBackground(colorScheme))
            .navigationTitle("\(greeting), \(firstName)")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.selectedTab = 4
                    } label: {
                        homeAvatar
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationDestination(for: UUID.self) { recordID in
                if let record = records.first(where: { $0.id == recordID }) {
                    SavedResultView(record: record)
                }
            }
        }
    }

    private var homeAvatar: some View {
        Group {
            if let url = settings.profilePhotoURL(),
               let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
            } else {
                Text(settings.displayName.prefix(1).uppercased())
                    .font(.body.bold())
                    .foregroundStyle(.black)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NEW PROJECT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppTheme.yellow)
                .clipShape(Capsule())

            Text("Calculate before you build.")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Get accurate material estimates in seconds.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))

            Button {
                appState.startNewCalculation(defaultWaste: settings.defaultWastePercent)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("New Calculation")
                }
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.yellow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius))
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color(red: 0.12, green: 0.12, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Overview")
                .font(.title3.bold())
            HStack(alignment: .top, spacing: 12) {
                overviewCard(icon: "🧱", value: "\(records.count)", label: "Total calculations")
                overviewCard(
                    icon: "📐",
                    value: CalculationEngine.formatArea(totalArea, system: settings.unitSystem),
                    label: "Calculated area"
                )
                overviewCard(icon: "💰", value: settings.formatMoney(totalCost), label: "Estimated cost")
            }
        }
    }

    private var totalArea: Double {
        records.reduce(0) { $0 + $1.areaSquareMeters }
    }

    private var totalCost: Double {
        records.reduce(0) { $0 + $1.totalCost }
    }

    private func overviewCard(icon: String, value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(icon)
                .font(.title3)
                .frame(height: 28, alignment: .leading)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.black)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    @ViewBuilder
    private var lastCalculationSection: some View {
        Text("Last Calculation")
            .font(.title3.bold())
        if let latest = records.first {
            NavigationLink(value: latest.id) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        Text(latest.category.icon)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(AppTheme.yellow.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(latest.materialName)
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text(latest.surface.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                        }
                        Spacer()
                        Text("Done")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppTheme.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.green.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    HStack(spacing: 8) {
                        lastMetricBox(
                            value: CalculationEngine.formatMeasure(latest.areaSquareMeters, category: latest.category, system: settings.unitSystem),
                            label: "Area"
                        )
                        lastMetricBox(
                            value: "\(latest.packages) \(Catalog.packageLabel(for: latest.materialName))",
                            label: "Needed"
                        )
                        lastMetricBox(
                            value: settings.formatMoney(latest.totalCost, currencyCode: latest.currencyCode),
                            label: "Cost",
                            green: true
                        )
                    }
                    HStack {
                        Text(latest.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText(colorScheme))
                        Spacer()
                        Text("View Details →")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.yellow)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.yellow.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
            .buttonStyle(.plain)
        } else {
            Text("No calculations yet. Start your first estimate.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private func lastMetricBox(value: String, label: String, green: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(green ? AppTheme.green : .black)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(AppTheme.screenBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title3.bold())
            Button {
                appState.selectedTab = 2
            } label: {
                HStack {
                    Image(systemName: "clock")
                    Text("History")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .foregroundStyle(.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            Button {
                appState.selectedTab = 3
            } label: {
                HStack {
                    Image(systemName: "books.vertical")
                    Text("Tips Library")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding()
                .foregroundStyle(.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    private var tipOfDay: some View {
        let tip = Catalog.tipOfTheDay()
        return VStack(alignment: .leading, spacing: 8) {
            Text("TIP OF THE DAY")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            Text(tip.title)
                .font(.headline)
                .foregroundStyle(.black)
            Text(tip.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            Button("More Tips") {
                appState.selectedTab = 3
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.yellow)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
