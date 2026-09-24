import Foundation
import SwiftData

enum SeedService {
    private static let didSeedKey = "didApplyMockSeed"

    @MainActor
    static func applyIfNeeded(context: ModelContext, settings: SettingsStore) {
        repairStoredResults(context: context)
        guard AppConfig.useMockSeed else { return }
        guard !UserDefaults.standard.bool(forKey: didSeedKey) else { return }

        let descriptor = FetchDescriptor<CalculationRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        settings.displayName = "Alex Johnson"
        settings.occupation = "DIY Builder"
        settings.currencyCode = "USD"
        settings.defaultWastePercent = 10
        settings.favoriteTipIDs = ["t1"]

        let now = Date()
        let calendar = Calendar.current

        let seeds: [(String, WorkSurface, Double, Int, Double, Date)] = [
            ("Gypsum Plaster", .interiorWalls, 30, 1, 10, calendar.date(byAdding: .hour, value: -2, to: now)!),
            ("Interior Wall Paint", .interiorWalls, 45, 2, 10, calendar.date(byAdding: .day, value: -1, to: now)!),
            ("Floor Screed", .floor, 22, 1, 10, calendar.date(byAdding: .day, value: -2, to: now)!),
            ("Finishing Putty", .ceiling, 18, 2, 10, calendar.date(byAdding: .day, value: -3, to: now)!),
            ("Ceramic Wall Tile", .wetArea, 12, 1, 10, calendar.date(byAdding: .day, value: -4, to: now)!),
        ]

        for seed in seeds {
            let catalog = Catalog.materials.first { $0.name == seed.0 }
            let category = catalog?.category ?? .mixes
            let rate = catalog?.rate ?? 8.5
            let unit = catalog?.unit ?? .kgPerSqM
            let packageSize = catalog?.defaultPackageSize ?? 25
            let price = catalog?.defaultPrice ?? 0
            let coats = category == .tiles || category == .wallpaper || category == .flooring || category == .linear ? 1 : seed.3
            let result = CalculationEngine.calculate(
                area: seed.2,
                rate: rate,
                coats: coats,
                wastePercent: seed.4,
                packageSize: packageSize,
                pricePerPackage: price,
                unit: unit
            )
            let record = CalculationRecord(
                category: category,
                materialName: seed.0,
                surface: seed.1,
                areaSquareMeters: seed.2,
                coats: coats,
                wastePercent: seed.4,
                rate: rate,
                unit: unit,
                packageSize: packageSize,
                pricePerPackage: price,
                currencyCode: "USD",
                rawMaterial: result.rawMaterial,
                withWasteMaterial: result.withWasteMaterial,
                packages: result.packages,
                totalCost: result.totalCost,
                createdAt: seed.5
            )
            context.insert(record)
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: didSeedKey)
    }

    @MainActor
    private static func repairStoredResults(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: repairKey) else { return }
        let records = (try? context.fetch(FetchDescriptor<CalculationRecord>())) ?? []
        for record in records {
            if record.materialName == "Gypsum Plaster", record.coats > 3 {
                record.coats = 1
            }
            let coats = record.category == .tiles || record.category == .wallpaper || record.category == .flooring || record.category == .linear
                ? 1
                : record.coats
            record.coats = coats
            let result = CalculationEngine.calculate(
                area: record.areaSquareMeters,
                rate: record.rate,
                coats: coats,
                wastePercent: record.wastePercent,
                packageSize: record.packageSize,
                pricePerPackage: record.pricePerPackage,
                unit: record.unit
            )
            record.rawMaterial = result.rawMaterial
            record.withWasteMaterial = result.withWasteMaterial
            record.packages = result.packages
            record.totalCost = result.totalCost
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: repairKey)
    }

    private static let repairKey = "didRepairCalculationResultsV1"
}
