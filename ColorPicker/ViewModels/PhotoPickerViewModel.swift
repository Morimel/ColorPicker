import SwiftUI
import PhotosUI
import UIKit

// MARK: - PhotoColorMarker

/// A point the user has picked on the photo. `position` is in unit space
/// (0...1 fractions of the image), so it stays meaningful across zoom/pan.
struct PhotoColorMarker: Identifiable {
    let id: UUID
    var position: CGPoint
    var rgb: RGBColor
}

// MARK: - PhotoPickerViewModel

/// Owns all photo-picking state and logic for `PhotoColorPickerView`: image
/// loading, zoom/pan, marker placement and dragging, and the coordinate math
/// that ties on-screen touches to normalized positions on the source image.
@Observable
final class PhotoPickerViewModel {

    enum DragMode {
        case pan, moveMarker
    }

    private let paletteStore: PaletteStore
    private let savedColorsStore: SavedColorsStore

    var selectedItem: PhotosPickerItem?
    var selectedImage: UIImage?
    var isPickerPresented = false

    /// Permanent small dots, in save order — this list is also the palette
    /// strip's source of colors.
    var paletteMarkers: [PhotoColorMarker] = []
    /// The point currently under review (big ring). May or may not already
    /// be one of `paletteMarkers` (re-selecting an existing dot sets this
    /// without duplicating it).
    var activeMarker: PhotoColorMarker?

    var totalZoom: CGFloat = 1
    var currentZoomDelta: CGFloat = 0
    var totalPan: CGSize = .zero
    var currentPanDelta: CGSize = .zero
    var activeDragMode: DragMode?

    var note: String = ""
    var showSavedToast = false

    /// Defaults to showing the brand row and matching within just one
    /// catalog — see `CatalogMatchMode`.
    var catalogMatchMode: CatalogMatchMode = .singleBrand
    var selectedCatalog: ColorCatalog = .ral

    /// How far above the touch point the loupe floats, so the finger doesn't
    /// block the view of what's being magnified (mirrors iOS's own
    /// text-selection loupe).
    let loupeVerticalOffset: CGFloat = 70

    var zoomScale: CGFloat {
        min(max(totalZoom + currentZoomDelta, 1), 5)
    }

    var panOffset: CGSize {
        CGSize(width: totalPan.width + currentPanDelta.width, height: totalPan.height + currentPanDelta.height)
    }

    /// The image's native pixel dimensions (not its displayed point size).
    var imagePixelSize: CGSize {
        guard let cgImage = selectedImage?.cgImage else { return .zero }
        return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
    }

    init(paletteStore: PaletteStore, savedColorsStore: SavedColorsStore) {
        self.paletteStore = paletteStore
        self.savedColorsStore = savedColorsStore
    }

    // MARK: Catalog matching

    func nearestCatalogMatch(for color: RGBColor) -> NearestCatalogMatch? {
        switch catalogMatchMode {
        case .allBrands:
            NearestCatalogColor.find(for: color)
        case .singleBrand:
            NearestCatalogColor.find(for: color, in: selectedCatalog)
        }
    }

    // MARK: Save

    /// Commits the picked colors both grouped as one new palette (so they
    /// show up in the Saved tab's "Палитры" segment) and individually (so
    /// they also show up in its "Цвета" grid) — the same dual save Camera's
    /// `saveStagedColors()` does.
    func savePalette() {
        guard !paletteMarkers.isEmpty else { return }
        let colors = paletteMarkers.map { marker in
            SavedColor(rgb: marker.rgb, ral: RALPalette.nearestRALColor(to: marker.rgb), note: "", createdAt: Date())
        }
        guard savedColorsStore.add(colors) else { return }
        paletteStore.add(colors: colors)
        paletteMarkers = []
        showSavedToast = true
    }

    // MARK: Marker actions

    func saveActivePoint() {
        guard let activeMarker else { return }

        // Snapshot the active marker's current position/color as an
        // independent value — this is what freezes into the palette, not a
        // reference that could keep tracking the reticle afterward.
        let snapshot = PhotoColorMarker(id: activeMarker.id, position: activeMarker.position, rgb: activeMarker.rgb)
        if let index = paletteMarkers.firstIndex(where: { $0.id == snapshot.id }) {
            paletteMarkers[index] = snapshot
        } else {
            paletteMarkers.append(snapshot)
        }

        // Give the reticle a fresh identity so it's decoupled from the point
        // we just froze — dragging or re-tapping it afterward must never
        // retroactively move an already-saved marker (that only happens via
        // another explicit "+").
        self.activeMarker = PhotoColorMarker(id: UUID(), position: snapshot.position, rgb: snapshot.rgb)
    }

    func handleTap(at point: CGPoint, containerSize: CGSize) {
        let hitRadius: CGFloat = 24

        if let hit = paletteMarkers.first(where: { distance(point, screenPosition(for: $0.position, containerSize: containerSize)) <= hitRadius }) {
            activeMarker = hit
            return
        }

        let unit = clampedUnitPoint(fromScreen: point, containerSize: containerSize)
        guard let image = selectedImage, let color = Self.sampleColor(in: image, atNormalizedPoint: unit) else { return }
        activeMarker = PhotoColorMarker(id: UUID(), position: unit, rgb: color)
    }

    /// Moves the active reticle only. Never writes into `paletteMarkers` —
    /// an already-saved point can only change via an explicit "+" tap
    /// (`saveActivePoint`), never as a side effect of the reticle moving.
    func moveActiveMarker(to unit: CGPoint) {
        guard var marker = activeMarker else { return }
        marker.position = unit
        if let image = selectedImage, let color = Self.sampleColor(in: image, atNormalizedPoint: unit) {
            marker.rgb = color
        }
        activeMarker = marker
    }

    // MARK: Gestures

    func tapGesture(containerSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { [weak self] value in
                self?.handleTap(at: value.location, containerSize: containerSize)
            }
    }

    func imageDragGesture(containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { [weak self] value in
                guard let self else { return }
                if activeDragMode == nil {
                    activeDragMode = dragMode(forStart: value.startLocation, containerSize: containerSize)
                }
                switch activeDragMode {
                case .moveMarker:
                    moveActiveMarker(to: clampedUnitPoint(fromScreen: value.location, containerSize: containerSize))
                case .pan, .none:
                    currentPanDelta = value.translation
                }
            }
            .onEnded { [weak self] value in
                guard let self else { return }
                if activeDragMode == .pan {
                    totalPan.width += value.translation.width
                    totalPan.height += value.translation.height
                }
                currentPanDelta = .zero
                activeDragMode = nil
            }
    }

    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { [weak self] value in
                self?.currentZoomDelta = value - 1
            }
            .onEnded { [weak self] value in
                guard let self else { return }
                totalZoom = min(max(totalZoom + (value - 1), 1), 5)
                currentZoomDelta = 0
            }
    }

    private func dragMode(forStart point: CGPoint, containerSize: CGSize) -> DragMode {
        guard let activeMarker else { return .pan }
        let screen = screenPosition(for: activeMarker.position, containerSize: containerSize)
        return distance(point, screen) <= 32 ? .moveMarker : .pan
    }

    func resetZoom() {
        withAnimation(.easeInOut(duration: 0.25)) {
            totalZoom = 1
            currentZoomDelta = 0
            totalPan = .zero
            currentPanDelta = .zero
        }
    }

    // MARK: Coordinate transforms

    /// Maps a unit-space point (0...1, a fraction of the *image's* full
    /// extent) to its current on-screen position, accounting for both the
    /// `.aspectRatio(.fill)` crop/scale and the current zoom/pan — used to
    /// hit-test taps/drags against markers and to place them on screen.
    func screenPosition(for unit: CGPoint, containerSize: CGSize) -> CGPoint {
        let content = containerPoint(forNormalizedPoint: unit, containerSize: containerSize)
        let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
        let scaled = CGPoint(
            x: center.x + (content.x - center.x) * zoomScale,
            y: center.y + (content.y - center.y) * zoomScale
        )
        return CGPoint(x: scaled.x + panOffset.width, y: scaled.y + panOffset.height)
    }

    /// Inverse of `screenPosition(for:containerSize:)`: maps a raw touch
    /// point back to a clamped unit-space point on the source image (i.e.
    /// the exact fraction to feed into `sampleColor(in:atNormalizedPoint:)`).
    func clampedUnitPoint(fromScreen point: CGPoint, containerSize: CGSize) -> CGPoint {
        let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
        let unscaledX = (point.x - panOffset.width - center.x) / zoomScale + center.x
        let unscaledY = (point.y - panOffset.height - center.y) / zoomScale + center.y
        return normalizedImagePoint(forContainerPoint: CGPoint(x: unscaledX, y: unscaledY), containerSize: containerSize)
    }

    /// Converts a point in the container's own (untransformed by zoom/pan)
    /// coordinate space into a normalized (0...1) fraction of the image's
    /// full extent, accounting for the overflow that `.aspectRatio(.fill)`
    /// crops off when the image's aspect ratio doesn't match the container's.
    func normalizedImagePoint(forContainerPoint point: CGPoint, containerSize: CGSize) -> CGPoint {
        let imageSize = imagePixelSize
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return CGPoint(
                x: min(max(point.x / max(containerSize.width, 1), 0), 1),
                y: min(max(point.y / max(containerSize.height, 1), 0), 1)
            )
        }

        let fillScale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let displayedSize = CGSize(width: imageSize.width * fillScale, height: imageSize.height * fillScale)
        let originX = (containerSize.width - displayedSize.width) / 2
        let originY = (containerSize.height - displayedSize.height) / 2

        let normalizedX = (point.x - originX) / displayedSize.width
        let normalizedY = (point.y - originY) / displayedSize.height
        return CGPoint(x: min(max(normalizedX, 0), 1), y: min(max(normalizedY, 0), 1))
    }

    /// Inverse of `normalizedImagePoint(forContainerPoint:containerSize:)`:
    /// where a normalized (0...1) point on the full image lands in the
    /// container's own coordinate space, before any zoom/pan is applied.
    func containerPoint(forNormalizedPoint normalized: CGPoint, containerSize: CGSize) -> CGPoint {
        let imageSize = imagePixelSize
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGPoint(x: normalized.x * containerSize.width, y: normalized.y * containerSize.height)
        }

        let fillScale = max(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let displayedSize = CGSize(width: imageSize.width * fillScale, height: imageSize.height * fillScale)
        let originX = (containerSize.width - displayedSize.width) / 2
        let originY = (containerSize.height - displayedSize.height) / 2

        return CGPoint(x: originX + normalized.x * displayedSize.width, y: originY + normalized.y * displayedSize.height)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    /// Crops a small pixel-aligned square out of the source image centered on
    /// `normalizedPoint`, using the exact same pixel-indexing as
    /// `sampleColor(in:atNormalizedPoint:)` so the loupe's center cell always
    /// lines up with the color actually being read.
    func loupeCrop(in image: UIImage, atNormalizedPoint normalizedPoint: CGPoint, pixelSize: Int) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let centerX = min(max(Int(normalizedPoint.x * CGFloat(width)), 0), width - 1)
        let centerY = min(max(Int(normalizedPoint.y * CGFloat(height)), 0), height - 1)

        let cropWidth = min(pixelSize, width)
        let cropHeight = min(pixelSize, height)
        let originX = min(max(centerX - cropWidth / 2, 0), width - cropWidth)
        let originY = min(max(centerY - cropHeight / 2, 0), height - cropHeight)

        let rect = CGRect(x: originX, y: originY, width: cropWidth, height: cropHeight)
        guard let cropped = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped)
    }

    // MARK: Photo loading

    func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let rawImage = UIImage(data: data) else { return }
            let image = rawImage.normalizedForSampling()

            await MainActor.run {
                selectedImage = image
                paletteMarkers = []
                totalZoom = 1
                currentZoomDelta = 0
                totalPan = .zero
                currentPanDelta = .zero

                let center = CGPoint(x: 0.5, y: 0.5)
                if let color = Self.sampleColor(in: image, atNormalizedPoint: center) {
                    activeMarker = PhotoColorMarker(id: UUID(), position: center, rgb: color)
                } else {
                    activeMarker = nil
                }
            }
        }
    }

    // MARK: Pixel sampling

    /// Reads the RGB color of the pixel at `normalizedPoint` (0...1 fractions,
    /// origin top-left) in `image`'s own native pixel buffer. `normalizedPoint`
    /// must already be expressed relative to the *image's* full extent, not
    /// whatever frame/aspect it happens to be displayed at — see
    /// `normalizedImagePoint(forContainerPoint:containerSize:)` for the piece
    /// that converts an on-screen point into this space.
    static func sampleColor(in image: UIImage, atNormalizedPoint normalizedPoint: CGPoint) -> RGBColor? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let x = min(max(Int(normalizedPoint.x * CGFloat(width)), 0), width - 1)
        let y = min(max(Int(normalizedPoint.y * CGFloat(height)), 0), height - 1)

        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return nil }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let offset = y * bytesPerRow + x * bytesPerPixel

        guard offset + 2 < CFDataGetLength(data) else { return nil }

        // `image` always comes from `normalizedForSampling()`, which forces
        // a fixed 8-bit, no-alpha, R-G-B byte layout regardless of what
        // format the original asset decoded into (Display P3 HEIC vs sRGB
        // JPEG vs premultiplied PNG all vary) — so there's exactly one
        // layout to read here, not several to branch on.
        let r = Int(bytes[offset])
        let g = Int(bytes[offset + 1])
        let b = Int(bytes[offset + 2])

        return RGBColor(r: r, g: g, b: b)
    }
}

// MARK: - UIImage normalization

private extension UIImage {
    /// Redraws the image upright into one fixed, fully-known pixel format —
    /// 8-bit, no alpha, R-G-B byte order, sRGB — instead of whatever format
    /// the source asset happened to decode into.
    ///
    /// This fixes two independent problems at once:
    /// - `imagePixelSize`/`sampleColor`/`loupeCrop` all read `cgImage`'s raw
    ///   (un-rotated) width/height and pixel buffer. Camera-roll photos are
    ///   very often stored rotated/mirrored via an orientation flag rather
    ///   than physically, so without baking that in here, the raw buffer
    ///   doesn't line up with what's actually displayed and the pipette
    ///   samples the wrong spot.
    /// - `sampleColor` parses raw bytes by hand. Leaving the source format
    ///   as-is meant it varied per photo (`.noneSkipLast` for a typical
    ///   JPEG/HEIC decode, `.premultipliedFirst`/little-endian for a
    ///   `UIGraphicsImageRenderer` redraw, etc.), which no single fixed byte
    ///   offset scheme can parse correctly for every case. Forcing one
    ///   explicit format here means `sampleColor` never has to branch on it.
    ///
    /// sRGB is a deliberate choice, not an accident: this app's hex/RGB/
    /// CMYK/RAL output are all sRGB-flavored, so a wide-gamut (Display P3)
    /// source is intentionally gamut-mapped down at this single point
    /// rather than sampled into color math that doesn't account for it.
    /// Dropping alpha is deliberate too — camera-roll photos have no
    /// meaningful transparency, so there's nothing to un-premultiply later.
    func normalizedForSampling() -> UIImage {
        let pixelWidth = Int((size.width * scale).rounded())
        let pixelHeight = Int((size.height * scale).rounded())
        guard pixelWidth > 0, pixelHeight > 0,
              let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: pixelWidth * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
              )
        else { return self }

        // A manually created CGContext has Core Graphics' native
        // bottom-left origin; `draw(in:)` is a UIKit drawing call that
        // expects the top-left-origin, y-flipped context
        // `UIGraphicsBeginImageContext` sets up automatically (and which is
        // what lets it apply `imageOrientation` correctly) — replicate that
        // flip by hand since this context bypasses that setup.
        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: scale, y: -scale)

        UIGraphicsPushContext(context)
        draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()

        guard let normalized = context.makeImage() else { return self }
        return UIImage(cgImage: normalized, scale: scale, orientation: .up)
    }
}
