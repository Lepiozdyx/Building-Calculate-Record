import Foundation
import Observation

@Observable
final class AppState {
    var selectedTab = 0
    var calculatorDraft = CalculationDraft()
    var showCalculatorFlow = false
    var showResultFromCalculator = false
    var pendingResultDraft: CalculationDraft?
    var editingRecordId: UUID?

    func resetCalculator() {
        calculatorDraft = CalculationDraft()
        calculatorDraft.wastePercent = 10
        editingRecordId = nil
        showResultFromCalculator = false
        pendingResultDraft = nil
    }

    func startNewCalculation(defaultWaste: Double) {
        resetCalculator()
        calculatorDraft.wastePercent = defaultWaste
        calculatorDraft.step = 1
        showCalculatorFlow = true
        showResultFromCalculator = false
        pendingResultDraft = nil
        selectedTab = 1
    }

    func selectCategory(_ category: MaterialCategory) {
        let changed = calculatorDraft.category != category
        calculatorDraft.category = category
        guard changed else { return }
        calculatorDraft.catalogMaterialId = nil
        calculatorDraft.customMaterialId = nil
        calculatorDraft.materialName = ""
        calculatorDraft.rate = 0
        calculatorDraft.pricePerPackage = 0
        calculatorDraft.packageSize = 25
        calculatorDraft.coats = 1
        calculatorDraft.unit = category == .linear ? .piecesPerM : .kgPerSqM
    }

    func loadFromRecord(_ record: CalculationRecord) {
        let catalogId = Catalog.materials.first { $0.name == record.materialName }?.id
        calculatorDraft = CalculationDraft(
            recordId: record.id,
            step: 1,
            category: record.category,
            catalogMaterialId: catalogId,
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
        editingRecordId = record.id
        showCalculatorFlow = true
        selectedTab = 1
    }
}
