import Foundation
import SwiftData

enum MaterialCategory: String, Codable, CaseIterable, Identifiable {
    case mixes = "Mixes"
    case paint = "Paint"
    case primer = "Primer"
    case tiles = "Tiles"
    case wallpaper = "Wallpaper"
    case flooring = "Flooring"
    case linear = "Linear Materials"

    var id: String { rawValue }

    var filterChipTitle: String {
        switch self {
        case .mixes: "Mixes"
        case .paint: "Paint"
        case .tiles: "Tiles"
        case .wallpaper: "Wallpaper"
        case .flooring: "Flooring"
        default: rawValue
        }
    }

    var historyFilter: Bool {
        switch self {
        case .primer, .linear: false
        default: true
        }
    }

    static var historyFilters: [MaterialCategory] {
        [.mixes, .paint, .tiles, .wallpaper, .flooring]
    }

    var icon: String {
        switch self {
        case .mixes: "🏗️"
        case .paint: "🎨"
        case .primer: "💧"
        case .tiles: "🧩"
        case .wallpaper: "🖼️"
        case .flooring: "📐"
        case .linear: "📏"
        }
    }
}

enum WorkSurface: String, Codable, CaseIterable, Identifiable {
    case interiorWalls = "Interior Walls"
    case ceiling = "Ceiling"
    case floor = "Floor"
    case exteriorFacade = "Exterior / Facade"
    case wetArea = "Wet Area"
    case slopesLinear = "Slopes & Linear"

    var id: String { rawValue }

    var wasteRange: ClosedRange<Double> {
        switch self {
        case .interiorWalls: 5...10
        case .ceiling: 10...15
        case .floor: 8...12
        case .exteriorFacade: 10...15
        case .wetArea: 10...15
        case .slopesLinear: 5...8
        }
    }

    var wasteRangeLabel: String {
        let r = wasteRange
        return "+\(Int(r.lowerBound))–\(Int(r.upperBound))%"
    }

    var icon: String {
        switch self {
        case .interiorWalls: "🧱"
        case .ceiling: "⬆️"
        case .floor: "⬇️"
        case .exteriorFacade: "🌤️"
        case .wetArea: "🚿"
        case .slopesLinear: "📐"
        }
    }
}

enum ConsumptionUnit: String, Codable, CaseIterable {
    case kgPerSqM = "kg/m²"
    case lPerSqM = "L/m²"
    case kgPerM = "kg/m"
    case lPerM = "L/m"
    case piecesPerSqM = "pcs/m²"
    case piecesPerM = "pcs/m"

    var displayUnit: String {
        switch self {
        case .kgPerSqM, .kgPerM: "kg"
        case .lPerSqM, .lPerM: "L"
        case .piecesPerSqM, .piecesPerM: "pcs"
        }
    }

    var usesLinearMeasure: Bool {
        self == .kgPerM || self == .lPerM || self == .piecesPerM
    }
}

enum UnitSystem: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
}

struct CatalogMaterial: Identifiable, Hashable {
    let id: String
    let name: String
    let category: MaterialCategory
    let rate: Double
    let unit: ConsumptionUnit
    let defaultPackageSize: Double
    let defaultPrice: Double
    let packageLabel: String
}

struct TipItem: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let categoryTag: String
    let topicTag: String
    let filter: TipFilter
}

enum TipFilter: String, CaseIterable {
    case all = "All"
    case plaster = "Plaster"
    case paint = "Paint"
    case tiles = "Tiles"
    case flooring = "Flooring"
}

@Model
final class CustomMaterial {
    var id: UUID
    var name: String
    var rate: Double
    var unitRaw: String
    var categoryRaw: String
    var defaultPackageSize: Double
    var createdAt: Date

    init(
        name: String,
        rate: Double,
        unit: ConsumptionUnit,
        category: MaterialCategory,
        defaultPackageSize: Double = 25
    ) {
        self.id = UUID()
        self.name = name
        self.rate = rate
        self.unitRaw = unit.rawValue
        self.categoryRaw = category.rawValue
        self.defaultPackageSize = defaultPackageSize
        self.createdAt = Date()
    }

    var unit: ConsumptionUnit {
        ConsumptionUnit(rawValue: unitRaw) ?? .kgPerSqM
    }

    var category: MaterialCategory {
        MaterialCategory(rawValue: categoryRaw) ?? .mixes
    }
}

@Model
final class CalculationRecord {
    var id: UUID
    var createdAt: Date
    var categoryRaw: String
    var materialName: String
    var surfaceRaw: String
    var areaSquareMeters: Double
    var coats: Int
    var wastePercent: Double
    var rate: Double
    var unitRaw: String
    var packageSize: Double
    var pricePerPackage: Double
    var currencyCode: String
    var rawMaterial: Double
    var withWasteMaterial: Double
    var packages: Int
    var totalCost: Double
    var customMaterialId: UUID?

    init(
        category: MaterialCategory,
        materialName: String,
        surface: WorkSurface,
        areaSquareMeters: Double,
        coats: Int,
        wastePercent: Double,
        rate: Double,
        unit: ConsumptionUnit,
        packageSize: Double,
        pricePerPackage: Double,
        currencyCode: String,
        rawMaterial: Double,
        withWasteMaterial: Double,
        packages: Int,
        totalCost: Double,
        customMaterialId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.categoryRaw = category.rawValue
        self.materialName = materialName
        self.surfaceRaw = surface.rawValue
        self.areaSquareMeters = areaSquareMeters
        self.coats = coats
        self.wastePercent = wastePercent
        self.rate = rate
        self.unitRaw = unit.rawValue
        self.packageSize = packageSize
        self.pricePerPackage = pricePerPackage
        self.currencyCode = currencyCode
        self.rawMaterial = rawMaterial
        self.withWasteMaterial = withWasteMaterial
        self.packages = packages
        self.totalCost = totalCost
        self.customMaterialId = customMaterialId
    }

    var category: MaterialCategory {
        MaterialCategory(rawValue: categoryRaw) ?? .mixes
    }

    var surface: WorkSurface {
        WorkSurface(rawValue: surfaceRaw) ?? .interiorWalls
    }

    var unit: ConsumptionUnit {
        ConsumptionUnit(rawValue: unitRaw) ?? .kgPerSqM
    }
}

struct CalculationDraft: Equatable {
    var recordId: UUID?
    var step: Int = 1
    var category: MaterialCategory?
    var catalogMaterialId: String?
    var customMaterialId: UUID?
    var materialName: String = ""
    var rate: Double = 0
    var unit: ConsumptionUnit = .kgPerSqM
    var surface: WorkSurface?
    var area: Double = 0
    var coats: Int = 1
    var wastePercent: Double = 10
    var packageSize: Double = 25
    var pricePerPackage: Double = 0

    var appliesCoats: Bool {
        switch category {
        case .tiles, .wallpaper, .flooring, .linear, nil:
            false
        default:
            true
        }
    }

    func result() -> CalculationResult {
        CalculationEngine.calculate(
            area: area,
            rate: rate,
            coats: appliesCoats ? coats : 1,
            wastePercent: wastePercent,
            packageSize: packageSize,
            pricePerPackage: pricePerPackage,
            unit: unit
        )
    }
}

struct CalculationResult: Equatable {
    let rawMaterial: Double
    let withWasteMaterial: Double
    let packages: Int
    let totalCost: Double
}
