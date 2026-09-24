import SwiftData
import SwiftUI

struct CalculatorView: View {
    @Environment(AppState.self) private var appState
    @Environment(SettingsStore.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \CustomMaterial.createdAt) private var customMaterials: [CustomMaterial]

    @State private var searchText = ""
    @State private var showCustomSheet = false
    @State private var areaText = ""
    @State private var packageText = ""
    @State private var priceText = ""

    var body: some View {
        let step = appState.calculatorDraft.step

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                stepIndicator(step: step)
                stepContent(step: step)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 120)
        }
        .background(AppTheme.screenBackground(colorScheme))
        .navigationTitle("Calculator")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            bottomBar(step: step, draft: appState.calculatorDraft)
        }
        .sheet(isPresented: $showCustomSheet) {
            CustomMaterialSheet(category: appState.calculatorDraft.category ?? .mixes) { custom in
                appState.calculatorDraft.customMaterialId = custom.id
                appState.calculatorDraft.catalogMaterialId = nil
                appState.calculatorDraft.materialName = custom.name
                appState.calculatorDraft.rate = custom.rate
                appState.calculatorDraft.unit = custom.unit
                appState.calculatorDraft.packageSize = custom.defaultPackageSize
            }
        }
        .onAppear {
            if appState.calculatorDraft.category == nil, appState.calculatorDraft.step == 1 {
                appState.calculatorDraft.wastePercent = settings.defaultWastePercent
            }
            syncTextFields(from: appState.calculatorDraft)
        }
        .onChange(of: appState.calculatorDraft.step) { _, _ in
            syncTextFields(from: appState.calculatorDraft)
        }
    }

    @ViewBuilder
    private func stepContent(step: Int) -> some View {
        switch step {
        case 1: categoryStep
        case 2: materialStep
        case 3: surfaceStep
        case 4: parametersStep
        case 5: pricingStep
        default: EmptyView()
        }
    }

    @ViewBuilder
    private var categoryStep: some View {
        let draft = appState.calculatorDraft
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("SELECT MATERIAL TYPE")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MaterialCategory.allCases) { category in
                    Button {
                        appState.selectCategory(category)
                    } label: {
                        VStack(spacing: 8) {
                            Text(category.icon)
                                .font(.title)
                            Text(category.rawValue)
                                .font(.subheadline.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(cardFill(selected: draft.category == category))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                                .stroke(draft.category == category ? AppTheme.yellow : Color.clear, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var materialStep: some View {
        let draft = appState.calculatorDraft
        let category = draft.category ?? .mixes
        let filtered = filteredMaterials(category: category)
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("SELECT MATERIAL")
            TextField("Search materials...", text: $searchText)
                .padding()
                .foregroundStyle(Color.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            ForEach(filtered) { material in
                materialRow(material: material, selected: draft.catalogMaterialId == material.id) {
                    appState.calculatorDraft.catalogMaterialId = material.id
                    appState.calculatorDraft.customMaterialId = nil
                    appState.calculatorDraft.materialName = material.name
                    appState.calculatorDraft.rate = material.rate
                    appState.calculatorDraft.unit = material.unit
                    appState.calculatorDraft.packageSize = material.defaultPackageSize
                    appState.calculatorDraft.pricePerPackage = material.defaultPrice
                }
            }
            ForEach(customMaterials.filter { $0.category == category }) { custom in
                materialRowCustom(custom: custom, selected: draft.customMaterialId == custom.id) {
                    appState.calculatorDraft.customMaterialId = custom.id
                    appState.calculatorDraft.catalogMaterialId = nil
                    appState.calculatorDraft.materialName = custom.name
                    appState.calculatorDraft.rate = custom.rate
                    appState.calculatorDraft.unit = custom.unit
                    appState.calculatorDraft.packageSize = custom.defaultPackageSize
                }
            }
            Button { showCustomSheet = true } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Custom Material")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(AppTheme.yellow)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    @ViewBuilder
    private var surfaceStep: some View {
        let draft = appState.calculatorDraft
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("WORK SURFACE")
            ForEach(WorkSurface.allCases) { surface in
                Button {
                    appState.calculatorDraft.surface = surface
                } label: {
                    HStack {
                        Text(surface.icon)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(surface.rawValue)
                                .font(.headline)
                                .foregroundStyle(Color.black)
                            Text("Recommended waste: \(surface.wasteRangeLabel)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText(colorScheme))
                        }
                        Spacer()
                        if draft.surface == surface {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.yellow)
                        }
                    }
                    .padding()
                    .background(cardFill(selected: draft.surface == surface))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var parametersStep: some View {
        @Bindable var state = appState
        let draft = state.calculatorDraft
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("CALCULATION PARAMETERS")
            VStack(alignment: .leading, spacing: 8) {
                Text(CalculationEngine.areaLabel(for: draft.category).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
                TextField("0", text: $areaText)
                    .keyboardType(.decimalPad)
                    .font(.title2.bold())
                    .foregroundStyle(Color.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .onChange(of: areaText) { _, new in
                        let display = Double(new.replacingOccurrences(of: ",", with: ".")) ?? 0
                        state.calculatorDraft.area = CalculationEngine.metricArea(
                            fromDisplay: display,
                            category: draft.category,
                            system: settings.unitSystem
                        )
                    }
                Text(CalculationEngine.areaUnitSuffix(for: draft.category, system: settings.unitSystem))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText(colorScheme))
            }
            if draft.appliesCoats {
                HStack {
                    Text("Number of coats")
                        .font(.headline)
                    Spacer()
                    Stepper("\(draft.coats)", value: $state.calculatorDraft.coats, in: 1...10)
                        .labelsHidden()
                    Text("\(draft.coats)")
                        .font(.headline)
                        .foregroundStyle(Color.black)
                        .frame(width: 24)
                }
                .padding()
                .foregroundStyle(Color.black)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Waste allowance")
                        .font(.headline)
                    Spacer()
                    Text("+\(Int(draft.wastePercent))%")
                        .font(.headline)
                }
                Slider(value: $state.calculatorDraft.wastePercent, in: 0...20, step: 1)
                    .tint(AppTheme.yellow)
                if let surface = draft.surface {
                    Text("Recommended for \(surface.rawValue): \(surface.wasteRangeLabel)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.green)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.green.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .foregroundStyle(Color.black)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private var pricingStep: some View {
        let draft = appState.calculatorDraft
        let result = draft.result()
        let unit = draft.unit.displayUnit
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("PACKAGE & PRICE")
            VStack(spacing: 12) {
                fieldRow(title: "Package size (\(unit))", text: $packageText) {
                    appState.calculatorDraft.packageSize = Double(packageText.replacingOccurrences(of: ",", with: ".")) ?? 0
                }
                fieldRow(title: "Price per package", text: $priceText) {
                    appState.calculatorDraft.pricePerPackage = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))

            VStack(alignment: .leading, spacing: 8) {
                Text("PREVIEW")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.7))
                Text(CalculationEngine.formatMaterial(result.withWasteMaterial, unit: draft.unit, system: settings.unitSystem))
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text("\(result.packages) packages · \(settings.formatMoney(result.totalCost))")
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private func bottomBar(step: Int, draft: CalculationDraft) -> some View {
        HStack(spacing: 12) {
            if step > 1 {
                Button("Back") {
                    appState.calculatorDraft.step -= 1
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonRadius))
            }
            Button(step == 5 ? "Calculate" : "Continue") {
                if step == 5 {
                    appState.pendingResultDraft = appState.calculatorDraft
                    appState.showResultFromCalculator = true
                } else {
                    appState.calculatorDraft.step += 1
                }
            }
            .buttonStyle(PrimaryYellowButtonStyle(enabled: canContinue(step: step, draft: draft)))
            .disabled(!canContinue(step: step, draft: draft))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppTheme.screenBackground(colorScheme).opacity(0.95))
    }

    private func canContinue(step: Int, draft: CalculationDraft) -> Bool {
        switch step {
        case 1: draft.category != nil
        case 2: !draft.materialName.isEmpty
        case 3: draft.surface != nil
        case 4: draft.area > 0
        case 5: draft.packageSize > 0
        default: false
        }
    }

    private func filteredMaterials(category: MaterialCategory) -> [CatalogMaterial] {
        let base = Catalog.materials(for: category)
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func materialRow(material: CatalogMaterial, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(material.name)
                        .font(.headline)
                        .foregroundStyle(Color.black)
                    Text(String(format: "%.2g %@ · %@ %@", material.rate, material.unit.rawValue, settings.formatMoney(material.defaultPrice), material.packageLabel))
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.yellow)
                }
            }
            .padding()
            .background(cardFill(selected: selected))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func materialRowCustom(custom: CustomMaterial, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(custom.name)
                        .font(.headline)
                        .foregroundStyle(Color.black)
                    Text("Custom · \(custom.rate) \(custom.unit.rawValue)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText(colorScheme))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppTheme.yellow)
                }
            }
            .padding()
            .background(cardFill(selected: selected))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func fieldRow(title: String, text: Binding<String>, onChange: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText(colorScheme))
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .font(.headline)
                .onChange(of: text.wrappedValue) { _, _ in onChange() }
        }
    }

    private func stepIndicator(step: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AppTheme.yellow : Color.gray.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.secondaryText(colorScheme))
    }

    private func cardFill(selected: Bool) -> Color {
        if colorScheme == .dark {
            return selected ? Color.white : Color.white.opacity(0.95)
        }
        return Color.white
    }

    private func syncTextFields(from draft: CalculationDraft) {
        let displayArea = CalculationEngine.displayAreaInput(draft.area, category: draft.category, system: settings.unitSystem)
        if displayArea > 0 {
            areaText = displayArea == displayArea.rounded() ? "\(Int(displayArea))" : String(format: "%.1f", displayArea)
        }
        packageText = draft.packageSize == draft.packageSize.rounded() ? "\(Int(draft.packageSize))" : String(draft.packageSize)
        priceText = draft.pricePerPackage > 0 ? (draft.pricePerPackage == draft.pricePerPackage.rounded() ? "\(Int(draft.pricePerPackage))" : String(draft.pricePerPackage)) : ""
    }
}

struct CustomMaterialSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let category: MaterialCategory
    let onSave: (CustomMaterial) -> Void

    @State private var name = ""
    @State private var rate = ""
    @State private var unit: ConsumptionUnit = .kgPerSqM
    @State private var packageSize = "25"

    var body: some View {
        NavigationStack {
            Form {
                TextField("Material name", text: $name)
                TextField("Consumption rate", text: $rate)
                    .keyboardType(.decimalPad)
                Picker("Unit", selection: $unit) {
                    ForEach(ConsumptionUnit.allCases, id: \.self) { u in
                        Text(u.rawValue).tag(u)
                    }
                }
                TextField("Default package size", text: $packageSize)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Custom Material")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let custom = CustomMaterial(
                            name: name,
                            rate: Double(rate.replacingOccurrences(of: ",", with: ".")) ?? 0,
                            unit: unit,
                            category: category,
                            defaultPackageSize: Double(packageSize) ?? 25
                        )
                        modelContext.insert(custom)
                        try? modelContext.save()
                        onSave(custom)
                        dismiss()
                    }
                    .disabled(name.isEmpty || (Double(rate.replacingOccurrences(of: ",", with: ".")) ?? 0) <= 0)
                }
            }
        }
    }
}
