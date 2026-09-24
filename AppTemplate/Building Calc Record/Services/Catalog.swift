import Foundation

enum Catalog {
    static let materials: [CatalogMaterial] = [
        CatalogMaterial(id: "gypsum_plaster", name: "Gypsum Plaster", category: .mixes, rate: 8.5, unit: .kgPerSqM, defaultPackageSize: 25, defaultPrice: 14, packageLabel: "bags"),
        CatalogMaterial(id: "cement_plaster", name: "Cement Plaster", category: .mixes, rate: 16, unit: .kgPerSqM, defaultPackageSize: 25, defaultPrice: 12, packageLabel: "bags"),
        CatalogMaterial(id: "finishing_putty", name: "Finishing Putty", category: .mixes, rate: 1.25, unit: .kgPerSqM, defaultPackageSize: 5, defaultPrice: 18, packageLabel: "bags"),
        CatalogMaterial(id: "tile_adhesive", name: "Tile Adhesive", category: .mixes, rate: 4, unit: .kgPerSqM, defaultPackageSize: 25, defaultPrice: 22, packageLabel: "bags"),
        CatalogMaterial(id: "floor_screed", name: "Floor Screed", category: .mixes, rate: 19, unit: .kgPerSqM, defaultPackageSize: 25, defaultPrice: 18, packageLabel: "bags"),
        CatalogMaterial(id: "grout", name: "Tile Grout", category: .mixes, rate: 0.5, unit: .kgPerSqM, defaultPackageSize: 5, defaultPrice: 15, packageLabel: "bags"),
        CatalogMaterial(id: "interior_wall_paint", name: "Interior Wall Paint", category: .paint, rate: 0.14, unit: .lPerSqM, defaultPackageSize: 9, defaultPrice: 28, packageLabel: "cans"),
        CatalogMaterial(id: "ceiling_paint", name: "Ceiling Paint", category: .paint, rate: 0.12, unit: .lPerSqM, defaultPackageSize: 9, defaultPrice: 26, packageLabel: "cans"),
        CatalogMaterial(id: "facade_paint", name: "Facade Paint", category: .paint, rate: 0.22, unit: .lPerSqM, defaultPackageSize: 10, defaultPrice: 45, packageLabel: "cans"),
        CatalogMaterial(id: "interior_primer", name: "Interior Primer", category: .primer, rate: 0.12, unit: .lPerSqM, defaultPackageSize: 10, defaultPrice: 24, packageLabel: "cans"),
        CatalogMaterial(id: "deep_primer", name: "Deep Penetrating Primer", category: .primer, rate: 0.15, unit: .lPerSqM, defaultPackageSize: 10, defaultPrice: 30, packageLabel: "cans"),
        CatalogMaterial(id: "ceramic_wall_tile", name: "Ceramic Wall Tile", category: .tiles, rate: 1, unit: .piecesPerSqM, defaultPackageSize: 1, defaultPrice: 32, packageLabel: "boxes"),
        CatalogMaterial(id: "porcelain_floor_tile", name: "Porcelain Floor Tile", category: .tiles, rate: 1, unit: .piecesPerSqM, defaultPackageSize: 1, defaultPrice: 38, packageLabel: "boxes"),
        CatalogMaterial(id: "vinyl_wallpaper", name: "Vinyl Wallpaper", category: .wallpaper, rate: 1, unit: .piecesPerSqM, defaultPackageSize: 1, defaultPrice: 25, packageLabel: "rolls"),
        CatalogMaterial(id: "laminate_flooring", name: "Laminate Flooring", category: .flooring, rate: 1, unit: .piecesPerSqM, defaultPackageSize: 2, defaultPrice: 55, packageLabel: "packs"),
        CatalogMaterial(id: "baseboard", name: "Baseboard Profile", category: .linear, rate: 1, unit: .piecesPerM, defaultPackageSize: 2.4, defaultPrice: 8, packageLabel: "pieces"),
        CatalogMaterial(id: "corner_profile", name: "Corner Profile", category: .linear, rate: 1, unit: .kgPerM, defaultPackageSize: 3, defaultPrice: 12, packageLabel: "pieces"),
    ]

    static func packageLabel(for materialName: String) -> String {
        materials.first { $0.name == materialName }?.packageLabel ?? "packages"
    }

    static func material(id: String) -> CatalogMaterial? {
        materials.first { $0.id == id }
    }

    static func materials(for category: MaterialCategory) -> [CatalogMaterial] {
        materials.filter { $0.category == category }
    }

    static func proTip(for category: MaterialCategory) -> String {
        switch category {
        case .mixes:
            "Consider buying an extra bag from the same batch if the project spans multiple days — materials from the same batch ensure consistency."
        case .paint, .primer:
            "Consider buying 2 cans if the project spans multiple days — materials from the same batch ensure color and consistency match."
        case .tiles:
            "Buy all tile from the same batch and keep a few spare pieces for future repairs."
        case .wallpaper:
            "Order all rolls from the same batch number to avoid shade differences between walls."
        case .flooring:
            "Acclimate flooring packs in the room for 48 hours before installation."
        case .linear:
            "Add 5–8% extra length for cuts and corners on long runs."
        }
    }

    static let tips: [TipItem] = [
        TipItem(id: "t1", title: "Prime before plastering", body: "Always apply a bonding agent or primer before plastering on smooth concrete — it dramatically improves adhesion and reduces material waste.", categoryTag: "PLASTER", topicTag: "Adhesion", filter: .plaster),
        TipItem(id: "t2", title: "Two thin coats beat one thick coat", body: "Apply paint in two thin coats rather than one thick layer. Each coat dries faster and the finish is more even and durable.", categoryTag: "PAINT", topicTag: "Technique", filter: .paint),
        TipItem(id: "t3", title: "Plan tile layout first", body: "Dry-lay tiles from the center of the room before applying adhesive. Avoid narrow cut pieces along visible walls.", categoryTag: "TILES", topicTag: "Layout", filter: .tiles),
        TipItem(id: "t4", title: "Clean surfaces thoroughly", body: "Always remove dust, grease, and loose coatings before any finish work — adhesion depends on a clean base.", categoryTag: "GENERAL", topicTag: "Prep", filter: .plaster),
        TipItem(id: "t5", title: "Prime before finishing", body: "Priming reduces consumption of top coats and improves bond between layers.", categoryTag: "GENERAL", topicTag: "Prep", filter: .paint),
        TipItem(id: "t6", title: "Fill cracks early", body: "Repair cracks and chips before plaster or paint — they will telegraph through the finish if ignored.", categoryTag: "PLASTER", topicTag: "Prep", filter: .plaster),
        TipItem(id: "t7", title: "Check wall flatness", body: "Use a long straightedge or level before plastering to find high and low spots.", categoryTag: "PLASTER", topicTag: "Prep", filter: .plaster),
        TipItem(id: "t8", title: "Score smooth concrete", body: "On very smooth concrete, use quartz primer or light mechanical scoring for plaster grip.", categoryTag: "PLASTER", topicTag: "Adhesion", filter: .plaster),
        TipItem(id: "t9", title: "Limit plaster layer thickness", body: "Do not exceed manufacturer layer thickness per pass — thick layers crack as they dry.", categoryTag: "PLASTER", topicTag: "Technique", filter: .plaster),
        TipItem(id: "t10", title: "Dry between plaster coats", body: "Allow full drying between plaster layers; rushing causes delamination.", categoryTag: "PLASTER", topicTag: "Drying", filter: .plaster),
        TipItem(id: "t11", title: "Use corner tools", body: "Perforated corner beads or angle trowels keep outside corners straight and durable.", categoryTag: "PLASTER", topicTag: "Technique", filter: .plaster),
        TipItem(id: "t12", title: "Side-light when sanding", body: "Shine a light along the wall when sanding putty — raking light reveals imperfections.", categoryTag: "PLASTER", topicTag: "Finish", filter: .plaster),
        TipItem(id: "t13", title: "Mix on low speed", body: "Mix plaster and putty on low mixer speed to avoid trapping air bubbles.", categoryTag: "PLASTER", topicTag: "Mixing", filter: .plaster),
        TipItem(id: "t14", title: "Let paint coats cure", body: "Wait until each paint coat is fully dry before recoating — tacky layers wrinkle.", categoryTag: "PAINT", topicTag: "Drying", filter: .paint),
        TipItem(id: "t15", title: "Use painter's tape", body: "Mask adjacent surfaces with quality tape for crisp lines and less cleanup.", categoryTag: "PAINT", topicTag: "Technique", filter: .paint),
        TipItem(id: "t16", title: "Paint from the window", body: "Start near the window and work into the room so you always paint into wet edges.", categoryTag: "PAINT", topicTag: "Technique", filter: .paint),
        TipItem(id: "t17", title: "Match roller to texture", body: "Long-nap rollers for textured walls; short nap for smooth surfaces.", categoryTag: "PAINT", topicTag: "Tools", filter: .paint),
        TipItem(id: "t18", title: "Back-butter large tile", body: "Apply adhesive to both tile back and substrate on large format tiles.", categoryTag: "TILES", topicTag: "Adhesion", filter: .tiles),
        TipItem(id: "t19", title: "Use tile spacers", body: "Spacers or leveling clips keep joint width consistent across the field.", categoryTag: "TILES", topicTag: "Layout", filter: .tiles),
        TipItem(id: "t20", title: "Hide cut edges", body: "Place cut tile edges in corners or under trim where possible.", categoryTag: "TILES", topicTag: "Layout", filter: .tiles),
        TipItem(id: "t21", title: "Wait before grouting", body: "Grout only after adhesive has set — usually 24 hours for standard mortars.", categoryTag: "TILES", topicTag: "Timing", filter: .tiles),
        TipItem(id: "t22", title: "Acclimate wallpaper", body: "Let wallpaper rolls rest in the room for 24 hours before hanging.", categoryTag: "WALLPAPER", topicTag: "Prep", filter: .paint),
        TipItem(id: "t23", title: "Match wallpaper adhesive", body: "Use paste formulated for your wallpaper type — vinyl, paper, and fleece differ.", categoryTag: "WALLPAPER", topicTag: "Materials", filter: .paint),
        TipItem(id: "t24", title: "Pattern waste allowance", body: "Add 15% extra wallpaper when matching patterns across seams.", categoryTag: "WALLPAPER", topicTag: "Planning", filter: .paint),
        TipItem(id: "t25", title: "Paste on the right side", body: "Paste the wall for fleece-backed paper; paste the strip for traditional paper.", categoryTag: "WALLPAPER", topicTag: "Technique", filter: .paint),
        TipItem(id: "t26", title: "Smooth from center", body: "Brush bubbles from the center of wallpaper toward the edges.", categoryTag: "WALLPAPER", topicTag: "Technique", filter: .paint),
        TipItem(id: "t27", title: "Screed on guides", body: "Pour floor screed using guides or laser levels for a flat plane.", categoryTag: "FLOORING", topicTag: "Technique", filter: .flooring),
        TipItem(id: "t28", title: "Avoid fast drying screed", body: "Block drafts while screed cures — rapid drying causes cracking.", categoryTag: "FLOORING", topicTag: "Curing", filter: .flooring),
        TipItem(id: "t29", title: "Heated floor mixes", body: "Use polymer-modified screed mixes over underfloor heating.", categoryTag: "FLOORING", topicTag: "Materials", filter: .flooring),
        TipItem(id: "t30", title: "Check level often", body: "Verify floor level in multiple directions before the screed sets.", categoryTag: "FLOORING", topicTag: "Quality", filter: .flooring),
        TipItem(id: "t31", title: "Cure before finish", body: "Do not install finish flooring until the screed has reached design strength.", categoryTag: "FLOORING", topicTag: "Timing", filter: .flooring),
        TipItem(id: "t32", title: "Add waste allowance", body: "A 5–15% material reserve costs less than an emergency mid-job purchase.", categoryTag: "GENERAL", topicTag: "Planning", filter: .plaster),
        TipItem(id: "t33", title: "Measure net area", body: "Subtract openings from wall area when estimating paint and plaster.", categoryTag: "GENERAL", topicTag: "Planning", filter: .paint),
        TipItem(id: "t34", title: "Compare unit price", body: "Compare cost per kg or liter, not just package price.", categoryTag: "GENERAL", topicTag: "Budget", filter: .flooring),
        TipItem(id: "t35", title: "Same production batch", body: "Buy tinted products from one batch to avoid color drift.", categoryTag: "GENERAL", topicTag: "Materials", filter: .paint),
        TipItem(id: "t36", title: "Save your calculations", body: "Keep saved estimates to reorder materials or document project costs.", categoryTag: "GENERAL", topicTag: "Planning", filter: .flooring),
        TipItem(id: "t37", title: "Clean tools promptly", body: "Wash rollers and trowels before compounds set — dried material ruins tools.", categoryTag: "GENERAL", topicTag: "Tools", filter: .paint),
        TipItem(id: "t38", title: "Remove tape carefully", body: "Pull masking tape while paint is still slightly soft to avoid chipped edges.", categoryTag: "PAINT", topicTag: "Finish", filter: .paint),
        TipItem(id: "t39", title: "Keep cleanup ready", body: "A bucket of water and sponge nearby speeds cleanup and reduces mess.", categoryTag: "GENERAL", topicTag: "Tools", filter: .tiles),
        TipItem(id: "t40", title: "Follow climate specs", body: "Work within temperature and humidity ranges listed on the product label.", categoryTag: "GENERAL", topicTag: "Environment", filter: .flooring),
    ]

    static func tipOfTheDay() -> TipItem {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return tips[day % tips.count]
    }
}

struct CurrencyOption: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String
    var id: String { code }

    var displayTitle: String { "\(code) — \(symbol)" }
}

enum CurrencyCatalog {
    static let all: [CurrencyOption] = [
        CurrencyOption(code: "USD", symbol: "$", name: "United States Dollar"),
        CurrencyOption(code: "EUR", symbol: "€", name: "Euro"),
        CurrencyOption(code: "GBP", symbol: "£", name: "British Pound"),
        CurrencyOption(code: "CAD", symbol: "CA$", name: "Canadian Dollar"),
        CurrencyOption(code: "AUD", symbol: "A$", name: "Australian Dollar"),
        CurrencyOption(code: "CHF", symbol: "CHF", name: "Swiss Franc"),
        CurrencyOption(code: "PLN", symbol: "zł", name: "Polish Zloty"),
    ]

    static func option(for code: String) -> CurrencyOption {
        all.first { $0.code == code } ?? all[0]
    }
}
