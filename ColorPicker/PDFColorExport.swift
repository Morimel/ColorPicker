import UIKit

/// Renders saved colors/palettes as a printable PDF swatch sheet — the export
/// counterpart to the plain-text `shareText` used by `ShareLink` elsewhere.
enum PDFColorExport {

    /// One printable row: a swatch plus its RAL name/code, hex, RGB and CMYK.
    struct Entry {
        let hex: String
        let rgbText: String
        let cmykText: String
        let ralCode: String
        let ralName: String

        init(rgb: RGBColor, ral: RALColor) {
            self.hex = rgb.hexString
            self.rgbText = "RGB \(rgb.rgbString)"
            self.cmykText = "CMYK \(rgb.cmykString)"
            self.ralCode = ral.code
            self.ralName = ral.localizedName
        }

        init(_ color: SavedColor) {
            self.init(rgb: color.rgb, ral: color.ral)
        }
    }

    /// A titled group of entries — one per palette when exporting several at once.
    struct Section {
        let title: String
        let entries: [Entry]
    }

    private static let pageSize = CGSize(width: 612, height: 792) // US Letter, in points
    private static let margin: CGFloat = 36
    private static let swatchSize: CGFloat = 40
    private static let rowHeight: CGFloat = 56
    private static let sectionSpacing: CGFloat = 24

    /// Renders `sections` into a temp PDF file and returns its URL, or `nil` if there's
    /// nothing to export or the file couldn't be written.
    static func makePDF(documentTitle: String, sections: [Section]) -> URL? {
        let nonEmptySections = sections.filter { !$0.entries.isEmpty }
        guard !nonEmptySections.isEmpty else { return nil }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(sanitizedFileName(documentTitle))-\(Int(Date().timeIntervalSince1970))")
            .appendingPathExtension("pdf")

        do {
            try renderer.writePDF(to: url) { context in
                var y = beginPage(context: context, title: documentTitle)

                for section in nonEmptySections {
                    if !section.title.isEmpty {
                        y = drawSectionTitle(section.title, at: y, context: context)
                    }
                    for entry in section.entries {
                        if y + rowHeight > pageSize.height - margin {
                            y = beginPage(context: context, title: documentTitle)
                        }
                        y = drawRow(entry, at: y)
                    }
                    y += sectionSpacing
                }
            }
            return url
        } catch {
            return nil
        }
    }

    // MARK: Drawing

    private static func beginPage(context: UIGraphicsPDFRendererContext, title: String) -> CGFloat {
        context.beginPage()
        let titleFont = UIFont.boldSystemFont(ofSize: 20)
        let titleRect = CGRect(x: margin, y: margin, width: pageSize.width - margin * 2, height: 28)
        title.draw(in: titleRect, withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
        return margin + 40
    }

    private static func drawSectionTitle(_ title: String, at y: CGFloat, context: UIGraphicsPDFRendererContext) -> CGFloat {
        var y = y
        if y + 24 > pageSize.height - margin {
            y = beginPage(context: context, title: title)
        }
        let font = UIFont.boldSystemFont(ofSize: 15)
        let rect = CGRect(x: margin, y: y, width: pageSize.width - margin * 2, height: 20)
        title.draw(in: rect, withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
        return y + 26
    }

    private static func drawRow(_ entry: Entry, at y: CGFloat) -> CGFloat {
        let swatchRect = CGRect(x: margin, y: y, width: swatchSize, height: swatchSize)
        let swatchPath = UIBezierPath(roundedRect: swatchRect, cornerRadius: 8)
        uiColor(fromHex: entry.hex).setFill()
        swatchPath.fill()
        UIColor.black.withAlphaComponent(0.1).setStroke()
        swatchPath.lineWidth = 0.5
        swatchPath.stroke()

        let textX = swatchRect.maxX + 14
        let textWidth = pageSize.width - margin - textX

        let titleFont = UIFont.boldSystemFont(ofSize: 13)
        let detailFont = UIFont.systemFont(ofSize: 11)

        let title = "\(entry.ralCode) — \(entry.ralName)"
        title.draw(in: CGRect(x: textX, y: y, width: textWidth, height: 16),
                   withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])

        let detail = "Hex: \(entry.hex)   \(entry.rgbText)   \(entry.cmykText)"
        detail.draw(in: CGRect(x: textX, y: y + 18, width: textWidth, height: 16),
                    withAttributes: [.font: detailFont, .foregroundColor: UIColor.darkGray])

        return y + rowHeight
    }

    private static func uiColor(fromHex hex: String) -> UIColor {
        let hexString = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&value)
        return UIColor(
            red: CGFloat((value & 0xFF0000) >> 16) / 255,
            green: CGFloat((value & 0x00FF00) >> 8) / 255,
            blue: CGFloat(value & 0x0000FF) / 255,
            alpha: 1
        )
    }

    private static func sanitizedFileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let cleaned = name.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let result = String(cleaned)
        return result.isEmpty ? "colors" : result
    }
}
