import SwiftData
import SwiftUI

struct ResultView: View {
    @Environment(AppState.self) private var appState
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let draft: CalculationDraft
    var isNew: Bool = false
    var savedRecord: CalculationRecord?
    var storedResult: CalculationResult?
    var currencyCode: String?

    @State private var showDeleteConfirm = false

    private var result: CalculationResult { storedResult ?? draft.result() }
    private var category: MaterialCategory { draft.category ?? .mixes }
    private var surface: WorkSurface { draft.surface ?? .interiorWalls }
    private var packageLabel: String { Catalog.packageLabel(for: draft.materialName) }
    private var moneyCode: String { currencyCode ?? savedRecord?.currencyCode ?? settings.currencyCode }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("\(draft.materialName) · \(surface.rawValue)")
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))

                summaryCards
                breakdownCard
                proTipCard
                actions
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Calculation Results")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete calculation?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { deleteRecord() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MATERIAL NEEDED")
                    .font(.caption.weight(.bold))
                Text(CalculationEngine.formatMaterial(result.withWasteMaterial, unit: draft.unit, system: settings.unitSystem))
                    .font(.system(size: 36, weight: .bold))
                Text("Including \(Int(draft.wastePercent))% waste factor")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppTheme.yellow)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("PACKAGES")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(result.packages)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(CalculationEngine.formatPackageSize(draft.packageSize, unit: draft.unit, system: settings.unitSystem)) each")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

                VStack(alignment: .leading, spacing: 6) {
                    Text("TOTAL COST")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(settings.formatMoney(result.totalCost, currencyCode: moneyCode))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(settings.formatMoney(draft.pricePerPackage, currencyCode: moneyCode)) × \(result.packages) \(packageLabel)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
        }
    }

    private var breakdownCard: some View {
        VStack(spacing: 12) {
            Text("CALCULATION BREAKDOWN")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            breakdownRow("Surface Area", CalculationEngine.formatMeasure(draft.area, category: category, system: settings.unitSystem))
            breakdownRow("Consumption Rate", draft.materialName)
            breakdownRow("Number of Coats", "\(draft.appliesCoats ? draft.coats : 1)")
            breakdownRow("Waste Allowance", "+\(Int(draft.wastePercent))%")
            breakdownRow("Raw Material", CalculationEngine.formatMaterial(result.rawMaterial, unit: draft.unit, system: settings.unitSystem))
            breakdownRow("With Waste", CalculationEngine.formatMaterial(result.withWasteMaterial, unit: draft.unit, system: settings.unitSystem))
            breakdownRow("Package Size", CalculationEngine.formatPackageSize(draft.packageSize, unit: draft.unit, system: settings.unitSystem))
            breakdownRow("Packages to Buy", "\(result.packages) \(packageLabel)")
            breakdownRow("Price per Package", settings.formatMoney(draft.pricePerPackage, currencyCode: moneyCode))
            Divider()
            HStack {
                Text("Total Cost")
                    .font(.headline)
                Spacer()
                Text(settings.formatMoney(result.totalCost, currencyCode: moneyCode))
                    .font(.headline)
                    .foregroundStyle(AppTheme.green)
            }
        }
            .padding()
            .foregroundStyle(Color.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private func breakdownRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private var proTipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("💡")
            VStack(alignment: .leading, spacing: 6) {
                Text("Pro Tip")
                    .font(.headline)
                    .foregroundStyle(AppTheme.orange)
                Text(Catalog.proTip(for: category))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }
        }
        .padding()
        .background(AppTheme.yellow.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var actions: some View {
        VStack(spacing: 12) {
            if savedRecord == nil {
                Button("💾 Save Calculation 💾") { save() }
                    .buttonStyle(PrimaryYellowButtonStyle())
            }
            Button("✏️ Edit ✏️") { edit() }
                .font(.headline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.green)
                .foregroundStyle(.black)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius))
            Button("+ New Calculation") {
                appState.resetCalculator()
                appState.startNewCalculation(defaultWaste: settings.defaultWastePercent)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius))
            if savedRecord != nil || draft.recordId != nil {
                Button("🗑️ Delete 🗑️") { showDeleteConfirm = true }
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius))
            }
        }
    }

    private func save() {
        let record = CalculationRecord(
            category: category,
            materialName: draft.materialName,
            surface: surface,
            areaSquareMeters: draft.area,
            coats: draft.coats,
            wastePercent: draft.wastePercent,
            rate: draft.rate,
            unit: draft.unit,
            packageSize: draft.packageSize,
            pricePerPackage: draft.pricePerPackage,
            currencyCode: moneyCode,
            rawMaterial: result.rawMaterial,
            withWasteMaterial: result.withWasteMaterial,
            packages: result.packages,
            totalCost: result.totalCost,
            customMaterialId: draft.customMaterialId
        )
        if let existingId = draft.recordId {
            let descriptor = FetchDescriptor<CalculationRecord>()
            if let existing = try? modelContext.fetch(descriptor).first(where: { $0.id == existingId }) {
                modelContext.delete(existing)
            }
        }
        modelContext.insert(record)
        try? modelContext.save()
        appState.calculatorDraft.recordId = record.id
        appState.showResultFromCalculator = false
        appState.selectedTab = 0
    }

    private func edit() {
        appState.calculatorDraft = draft
        appState.calculatorDraft.step = 1
        appState.showResultFromCalculator = false
        appState.selectedTab = 1
        dismiss()
    }

    private func deleteRecord() {
        let id = savedRecord?.id ?? draft.recordId
        if let id {
            let descriptor = FetchDescriptor<CalculationRecord>()
            if let existing = try? modelContext.fetch(descriptor).first(where: { $0.id == id }) {
                modelContext.delete(existing)
                try? modelContext.save()
            }
        }
        appState.resetCalculator()
        appState.selectedTab = 2
        dismiss()
    }
}

struct SavedResultView: View {
    let record: CalculationRecord

    var body: some View {
        let draft = CalculationDraft(
            recordId: record.id,
            category: record.category,
            catalogMaterialId: Catalog.materials.first { $0.name == record.materialName }?.id,
            customMaterialId: record.customMaterialId,
            materialName: record.materialName,
            rate: record.rate,
            unit: record.unit,
            surface: record.surface,
            area: record.areaSquareMeters,
            coats: record.coats,
            wastePercent: record.wastePercent,
            packageSize: record.packageSize,
            pricePerPackage: record.pricePerPackage
        )
        ResultView(
            draft: draft,
            isNew: false,
            savedRecord: record,
            storedResult: CalculationResult(
                rawMaterial: record.rawMaterial,
                withWasteMaterial: record.withWasteMaterial,
                packages: record.packages,
                totalCost: record.totalCost
            ),
            currencyCode: record.currencyCode
        )
    }
}
