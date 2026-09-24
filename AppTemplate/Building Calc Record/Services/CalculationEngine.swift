import Foundation

enum CalculationEngine {
    static func calculate(
        area: Double,
        rate: Double,
        coats: Int,
        wastePercent: Double,
        packageSize: Double,
        pricePerPackage: Double,
        unit: ConsumptionUnit
    ) -> CalculationResult {
        let raw = area * rate * Double(max(coats, 1))
        let withWaste = raw * (1 + wastePercent / 100)
        let pkg = packageSize > 0 ? Int(ceil(withWaste / packageSize)) : 0
        let cost = Double(pkg) * pricePerPackage
        return CalculationResult(
            rawMaterial: raw,
            withWasteMaterial: withWaste,
            packages: pkg,
            totalCost: cost
        )
    }

    static func formatMaterial(_ value: Double, unit: ConsumptionUnit, system: UnitSystem) -> String {
        switch (unit.displayUnit, system) {
        case ("kg", .imperial):
            return "\(plainNumber(value * 2.20462)) lb"
        case ("L", .imperial):
            return "\(plainNumber(value * 0.264172)) gal"
        default:
            return "\(plainNumber(value)) \(unit.displayUnit)"
        }
    }

    static func formatPackageSize(_ size: Double, unit: ConsumptionUnit, system: UnitSystem) -> String {
        switch (unit.displayUnit, system) {
        case ("kg", .imperial):
            return "\(plainNumber(size * 2.20462)) lb"
        case ("L", .imperial):
            return "\(plainNumber(size * 0.264172)) gal"
        default:
            return "\(plainNumber(size)) \(unit.displayUnit)"
        }
    }

    static func formatArea(_ squareMeters: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(plainNumber(squareMeters)) m²"
        case .imperial:
            return "\(plainNumber(squareMeters * 10.7639)) ft²"
        }
    }

    static func formatLength(_ meters: Double, system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(plainNumber(meters)) m"
        case .imperial:
            return "\(plainNumber(meters * 3.28084)) ft"
        }
    }

    static func formatMeasure(_ metricValue: Double, category: MaterialCategory?, system: UnitSystem) -> String {
        if category == .linear {
            return formatLength(metricValue, system: system)
        }
        return formatArea(metricValue, system: system)
    }

    private static func plainNumber(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.05 {
            return "\(Int(value.rounded()))"
        }
        return String(format: "%.1f", value)
    }

    static func areaLabel(for category: MaterialCategory?) -> String {
        category == .linear ? "Length" : "Area"
    }

    static func areaUnitSuffix(for category: MaterialCategory?, system: UnitSystem) -> String {
        if category == .linear {
            return system == .metric ? "m" : "ft"
        }
        return system == .metric ? "m²" : "ft²"
    }

    static func displayAreaInput(_ metricValue: Double, category: MaterialCategory?, system: UnitSystem) -> Double {
        guard metricValue > 0 else { return 0 }
        if category == .linear {
            return system == .metric ? metricValue : metricValue * 3.28084
        }
        return system == .metric ? metricValue : metricValue * 10.7639
    }

    static func metricArea(fromDisplay value: Double, category: MaterialCategory?, system: UnitSystem) -> Double {
        guard value > 0 else { return 0 }
        if category == .linear {
            return system == .metric ? value : value / 3.28084
        }
        return system == .metric ? value : value / 10.7639
    }
}
