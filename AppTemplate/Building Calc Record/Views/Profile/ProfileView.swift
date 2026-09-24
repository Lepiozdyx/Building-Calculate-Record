import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Query private var records: [CalculationRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsRow
                    accountSection
                    preferencesSection
                    footer
                }
                .padding(20)
            }
            .background(AppTheme.screenBackground(colorScheme))
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    avatar
                }
            }
        }
    }

    private var avatar: some View {
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

    private var statsRow: some View {
        HStack(spacing: 12) {
            profileStat(value: "\(records.count)", label: "Calculations", bg: AppTheme.yellow.opacity(0.35))
            profileStat(value: CalculationEngine.formatArea(totalArea, system: settings.unitSystem), label: "Total area", bg: AppTheme.green.opacity(0.2))
            profileStat(value: settings.formatMoney(totalCost), label: "Est. cost", bg: Color.orange.opacity(0.2))
        }
    }

    private var totalArea: Double { records.reduce(0) { $0 + $1.areaSquareMeters } }
    private var totalCost: Double { records.reduce(0) { $0 + $1.totalCost } }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("ACCOUNT")
            VStack(spacing: 0) {
                NavigationLink { EditProfileView() } label: {
                    settingsRow(icon: "👤", title: "Edit Profile", subtitle: settings.displayName)
                }
                divider
                NavigationLink { NotificationsSettingsView() } label: {
                    settingsRow(icon: "🔔", title: "Notifications", subtitle: settings.calculationReminders ? "Enabled" : "Disabled")
                }
            }
            .foregroundStyle(Color.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("PREFERENCES")
            VStack(spacing: 0) {
                NavigationLink { MeasurementUnitsView() } label: {
                    settingsRow(icon: "📐", title: "Default Units", subtitle: unitsSubtitle)
                }
                divider
                NavigationLink { CurrencySettingsView() } label: {
                    settingsRow(icon: "💰", title: "Currency", subtitle: "\(settings.currencyCode) (\(CurrencyCatalog.option(for: settings.currencyCode).symbol))")
                }
                divider
                NavigationLink { WasteFactorSettingsView() } label: {
                    settingsRow(icon: "♻️", title: "Default Waste Factor", subtitle: "\(Int(settings.defaultWastePercent))%")
                }
            }
            .foregroundStyle(Color.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private var unitsSubtitle: String {
        settings.unitSystem == .metric ? "Metric (m², kg)" : "Imperial (ft², lb)"
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Building Calculate & Record")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            Text("Version 1.0.0")
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.secondaryText(colorScheme))
            .padding(.leading, 4)
    }

    private var divider: some View {
        Divider().padding(.leading, 56)
    }

    private func settingsRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.black)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .padding()
    }

    private func profileStat(value: String, label: String, bg: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct EditProfileView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name: String = ""
    @State private var occupation: String = ""
    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                avatarSection
                formCard
                Button("Save Changes") {
                    settings.displayName = name
                    settings.occupation = occupation
                    dismiss()
                }
                .buttonStyle(PrimaryYellowButtonStyle())
                Button("Cancel") { dismiss() }
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }
            .padding(20)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = settings.displayName
            occupation = settings.occupation
        }
        .onChange(of: pickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    try? settings.saveProfilePhoto(data: data)
                }
            }
        }
    }

    private var avatarSection: some View {
        VStack(spacing: 12) {
            Group {
                if let url = settings.profilePhotoURL(),
                   let uiImage = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Text(name.prefix(1).uppercased())
                        .font(.largeTitle.bold())
                }
            }
            .frame(width: 120, height: 120)
            .background(AppTheme.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Change Photo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.yellow)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.yellow.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            fieldBlock(label: "NAME", value: $name)
            Divider().padding(.leading, 16)
            fieldBlock(label: "OCCUPATION", value: $occupation)
        }
        .foregroundStyle(Color.black)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private func fieldBlock(label: String, value: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            TextField(label, text: value)
                .font(.title3.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NotificationsSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    toggleRow(
                        title: "Calculation Reminders",
                        subtitle: "Get reminders about unfinished calculations.",
                        isOn: Bindable(settings).calculationReminders
                    )
                    Divider().padding(.leading, 16)
                    toggleRow(
                        title: "Tip of the Day",
                        subtitle: "Receive a useful construction tip each morning.",
                        isOn: Bindable(settings).tipOfTheDay
                    )
                    Divider().padding(.leading, 16)
                    toggleRow(
                        title: "Project Reminders",
                        subtitle: "Stay updated on your active projects.",
                        isOn: Bindable(settings).projectReminders
                    )
                    Divider().padding(.leading, 16)
                    toggleRow(
                        title: "App Updates",
                        subtitle: "Get notified about new features and improvements.",
                        isOn: Bindable(settings).appUpdates
                    )
                }
                .foregroundStyle(Color.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

                Text("Notifications help you stay on top of your projects. You can change these settings at any time.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.yellow.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(20)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggleRow(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppTheme.yellow)
        }
        .padding()
    }
}

struct MeasurementUnitsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selection: UnitSystem = .metric

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Choose the units used throughout your calculations.")
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                unitCard(
                    system: .metric,
                    badges: ["m²", "kg", "L", "mm", "m"],
                    example: "Example: 30 m² → 255 kg",
                    selected: selection == .metric
                ) { selection = .metric }
                unitCard(
                    system: .imperial,
                    badges: ["ft²", "lb", "gal", "in", "ft"],
                    example: "Example: 323 ft² → 562 lb",
                    selected: selection == .imperial
                ) { selection = .imperial }
                Button("Save Units") {
                    settings.unitSystem = selection
                    dismiss()
                }
                .buttonStyle(PrimaryYellowButtonStyle())
            }
            .padding(20)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Measurement Units")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selection = settings.unitSystem }
    }

    private func unitCard(system: UnitSystem, badges: [String], example: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(system.rawValue)
                        .font(.title2.bold())
                    Spacer()
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? AppTheme.yellow : .gray)
                }
                HStack(spacing: 8) {
                    ForEach(badges, id: \.self) { badge in
                        Text(badge)
                            .font(.caption.weight(.bold))
                            .frame(width: 36, height: 36)
                            .background(selected ? AppTheme.yellow : Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                Text(example)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }
            .padding()
            .background(selected ? AppTheme.yellow.opacity(0.15) : Color.white)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.cardRadius).stroke(selected ? AppTheme.yellow : Color.gray.opacity(0.2), lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }
}

struct CurrencySettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var search = ""
    @State private var selection = "USD"

    var body: some View {
        VStack(spacing: 16) {
            TextField("Search currency", text: $search)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(filteredCurrencies) { currency in
                        Button {
                            selection = currency.code
                        } label: {
                            HStack {
                                Text(currency.symbol)
                                    .frame(width: 36, height: 36)
                                    .background(selection == currency.code ? AppTheme.yellow : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading) {
                                    Text(currency.displayTitle)
                                        .font(.headline)
                                    Text(currency.name)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                                }
                                Spacer()
                                if selection == currency.code {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.yellow)
                                }
                            }
                            .padding()
                            .background(selection == currency.code ? AppTheme.yellow.opacity(0.12) : Color.white)
                        }
                        .buttonStyle(.plain)
                        if currency.code != filteredCurrencies.last?.code {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .padding(.horizontal, 20)
            }

            Button("Save Currency") {
                settings.currencyCode = selection
                dismiss()
            }
            .buttonStyle(PrimaryYellowButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selection = settings.currencyCode }
    }

    private var filteredCurrencies: [CurrencyOption] {
        guard !search.isEmpty else { return CurrencyCatalog.all }
        return CurrencyCatalog.all.filter {
            $0.code.localizedCaseInsensitiveContains(search)
                || $0.name.localizedCaseInsensitiveContains(search)
        }
    }
}

struct WasteFactorSettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var value: Double = 10

    private let presets: [Double] = [5, 10, 15, 20]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Set the default extra material allowance for new calculations. You can still adjust it for each project.")
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))

                VStack(spacing: 8) {
                    Text("\(Int(value))%")
                        .font(.system(size: 48, weight: .bold))
                    Text("Extra material")
                    if value == 10 {
                        Label("Recommended", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(AppTheme.yellow)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

                VStack(alignment: .leading, spacing: 12) {
                    Slider(value: $value, in: 0...20, step: 1)
                        .tint(AppTheme.yellow)
                    HStack {
                        Text("0%")
                        Spacer()
                        Text("10%")
                        Spacer()
                        Text("20%")
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

                Text("QUICK PRESETS")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                HStack(spacing: 12) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            value = preset
                        } label: {
                            Text(preset == 10 ? "10% Rec." : "\(Int(preset))%")
                                .font(.subheadline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(value == preset ? AppTheme.yellow : Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Why add extra material?", systemImage: "lightbulb.fill")
                        .font(.headline)
                    Text("A small waste allowance helps cover cutting, surface irregularities, application losses, and future patch repairs.")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                .padding()
                .background(AppTheme.yellow.opacity(0.15))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.yellow.opacity(0.5)))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("Save Default") {
                    settings.defaultWastePercent = value
                    dismiss()
                }
                .buttonStyle(PrimaryYellowButtonStyle())
            }
            .padding(20)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Default Waste Factor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { value = settings.defaultWastePercent }
    }
}
