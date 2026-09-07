//
//  PhotoColorPickerView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - PhotoColorMarker

/// A point the user has picked on the photo. `position` is in unit space
/// (0...1 fractions of the image), so it stays meaningful across zoom/pan.
private struct PhotoColorMarker: Identifiable {
    let id: UUID
    var position: CGPoint
    var rgb: RGBColor
}

// MARK: - PhotoColorPickerView

struct PhotoColorPickerView: View {

    private enum DragMode {
        case pan, moveMarker
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(PaletteStore.self) private var paletteStore

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isPickerPresented = false

    /// Permanent small dots, in save order — this list is also the palette
    /// strip's source of colors.
    @State private var paletteMarkers: [PhotoColorMarker] = []
    /// The point currently under review (big ring). May or may not already
    /// be one of `paletteMarkers` (re-selecting an existing dot sets this
    /// without duplicating it).
    @State private var activeMarker: PhotoColorMarker?

    @State private var totalZoom: CGFloat = 1
    @State private var currentZoomDelta: CGFloat = 0
    @State private var totalPan: CGSize = .zero
    @State private var currentPanDelta: CGSize = .zero
    @State private var activeDragMode: DragMode?

    @State private var note: String = ""
    @State private var showSavedToast = false

    /// How far above the touch point the loupe floats, so the finger doesn't
    /// block the view of what's being magnified (mirrors iOS's own
    /// text-selection loupe).
    private let loupeVerticalOffset: CGFloat = 70

    private var zoomScale: CGFloat {
        min(max(totalZoom + currentZoomDelta, 1), 5)
    }

    private var panOffset: CGSize {
        CGSize(width: totalPan.width + currentPanDelta.width, height: totalPan.height + currentPanDelta.height)
    }

    /// The image's native pixel dimensions (not its displayed point size).
    private var imagePixelSize: CGSize {
        guard let cgImage = selectedImage?.cgImage else { return .zero }
        return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
    }

    var body: some View {
        VStack(spacing: 0) {
            imageSection

            resultSection
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.primary)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Фотогалерея")
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: savePalette) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .foregroundStyle(paletteMarkers.isEmpty ? .tertiary : .primary)
                }
                .disabled(paletteMarkers.isEmpty)
            }
        }
        .photosPicker(isPresented: $isPickerPresented, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
        .savedToast(isPresented: $showSavedToast, text: "Палитра сохранена")
    }

    // MARK: Image section

    private var imageSection: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size

            ZStack(alignment: .bottomLeading) {
                Group {
                    if selectedImage != nil {
                        transformableContent(containerSize: containerSize)
                            .frame(width: containerSize.width, height: containerSize.height)
                            .clipped()
                            .contentShape(Rectangle())
                            .gesture(imageDragGesture(containerSize: containerSize))
                            .gesture(magnificationGesture)
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded { resetZoom() }
                                    .exclusively(before: tapGesture(containerSize: containerSize))
                            )
                    } else {
                        emptyPlaceholder(containerSize: containerSize)
                    }
                }

                pickImageButton
                    .padding(16)

                if activeDragMode == .moveMarker, let activeMarker, let selectedImage {
                    let point = screenPosition(for: activeMarker.position, containerSize: containerSize)
                    let loupeCenter = CGPoint(x: point.x, y: point.y - loupeVerticalOffset)

                    // A thin stem from the loupe down to the actual sampled
                    // point, drawn under the loupe (which covers the segment
                    // that overlaps its own circle) — makes it visually
                    // unambiguous which point is being magnified, the same
                    // way iOS's own text-selection loupe stays tethered to
                    // the touch it's magnifying.
                    Path { path in
                        path.move(to: loupeCenter)
                        path.addLine(to: point)
                    }
                    .stroke(Color.white, lineWidth: 3)
                    .shadow(color: .black.opacity(0.3), radius: 2)
                    .allowsHitTesting(false)

                    LoupeView(
                        crop: loupeCrop(in: selectedImage, atNormalizedPoint: activeMarker.position, pixelSize: Int(LoupeView.cropPixelSize)),
                        tint: Color(hex: activeMarker.rgb.hexString)
                    )
                    .position(x: loupeCenter.x, y: loupeCenter.y)
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.6)
    }

    @ViewBuilder
    private func transformableContent(containerSize: CGSize) -> some View {
        ZStack {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .clipped()
            }

            ForEach(paletteMarkers) { marker in
                let point = containerPoint(forNormalizedPoint: marker.position, containerSize: containerSize)
                SavedMarkerView()
                    .position(x: point.x, y: point.y)
            }

            // Hidden while the loupe is up (drawn separately, in unscaled
            // container coordinates, over in `imageSection`) so the finger
            // isn't left resting on a duplicate indicator underneath it.
            if let activeMarker, activeDragMode != .moveMarker {
                let point = containerPoint(forNormalizedPoint: activeMarker.position, containerSize: containerSize)
                ActiveMarkerView()
                    .position(x: point.x, y: point.y)
            }
        }
        .scaleEffect(zoomScale)
        .offset(panOffset)
    }

    private func emptyPlaceholder(containerSize: CGSize) -> some View {
        ZStack {
            Color(.secondarySystemBackground)
            ActiveMarkerView()
        }
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private var pickImageButton: some View {
        Button(action: { isPickerPresented = true }) {
            CameraOverlayButton(systemImage: "photo")
        }
    }

    // MARK: Result section

    @ViewBuilder
    private var resultSection: some View {
        VStack(spacing: 14) {
            if let activeMarker {
                activeColorCard(for: activeMarker)
            } else {
                emptySwatch
            }

            TextField("Заметка (необязательно)", text: $note)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

            if !paletteMarkers.isEmpty {
                paletteStrip
            }
        }
        .padding(16)
    }

    private var emptySwatch: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(.systemGray5))
            .frame(width: 56, height: 56)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activeColorCard(for marker: PhotoColorMarker) -> some View {
        let match = RALPalette.displayMatch(for: marker.rgb)
        return ColorInfoCard(
            swatch: Color(hex: marker.rgb.hexString),
            ralName: match.name,
            ralCode: match.code,
            hex: marker.rgb.hexString,
            cmyk: marker.rgb.cmykString,
            rgb: marker.rgb.rgbString,
            trailingAction: saveActivePoint
        )
    }

    private var paletteStrip: some View {
        ColorStripView(colors: paletteMarkers.map(\.rgb))
    }

    private func savePalette() {
        guard !paletteMarkers.isEmpty else { return }
        let colors = paletteMarkers.map { marker in
            SavedColor(rgb: marker.rgb, ral: RALPalette.nearestRALColor(to: marker.rgb), note: "", createdAt: Date())
        }
        paletteStore.add(colors: colors)
        paletteMarkers = []
        showSavedToast = true
    }

    // MARK: Marker actions

    private func saveActivePoint() {
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

    private func handleTap(at point: CGPoint, containerSize: CGSize) {
        let hitRadius: CGFloat = 24

        if let hit = paletteMarkers.first(where: { distance(point, screenPosition(for: $0.position, containerSize: containerSize)) <= hitRadius }) {
            activeMarker = hit
            return
        }

        let unit = clampedUnitPoint(fromScreen: point, containerSize: containerSize)
        guard let image = selectedImage, let color = sampleColor(in: image, atNormalizedPoint: unit) else { return }
        activeMarker = PhotoColorMarker(id: UUID(), position: unit, rgb: color)
    }

    /// Moves the active reticle only. Never writes into `paletteMarkers` —
    /// an already-saved point can only change via an explicit "+" tap
    /// (`saveActivePoint`), never as a side effect of the reticle moving.
    private func moveActiveMarker(to unit: CGPoint) {
        guard var marker = activeMarker else { return }
        marker.position = unit
        if let image = selectedImage, let color = sampleColor(in: image, atNormalizedPoint: unit) {
            marker.rgb = color
        }
        activeMarker = marker
    }

    // MARK: Gestures

    private func tapGesture(containerSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                handleTap(at: value.location, containerSize: containerSize)
            }
    }

    private func imageDragGesture(containerSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
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
            .onEnded { value in
                if activeDragMode == .pan {
                    totalPan.width += value.translation.width
                    totalPan.height += value.translation.height
                }
                currentPanDelta = .zero
                activeDragMode = nil
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                currentZoomDelta = value - 1
            }
            .onEnded { value in
                totalZoom = min(max(totalZoom + (value - 1), 1), 5)
                currentZoomDelta = 0
            }
    }

    private func dragMode(forStart point: CGPoint, containerSize: CGSize) -> DragMode {
        guard let activeMarker else { return .pan }
        let screen = screenPosition(for: activeMarker.position, containerSize: containerSize)
        return distance(point, screen) <= 32 ? .moveMarker : .pan
    }

    private func resetZoom() {
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
    private func screenPosition(for unit: CGPoint, containerSize: CGSize) -> CGPoint {
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
    private func clampedUnitPoint(fromScreen point: CGPoint, containerSize: CGSize) -> CGPoint {
        let center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
        let unscaledX = (point.x - panOffset.width - center.x) / zoomScale + center.x
        let unscaledY = (point.y - panOffset.height - center.y) / zoomScale + center.y
        return normalizedImagePoint(forContainerPoint: CGPoint(x: unscaledX, y: unscaledY), containerSize: containerSize)
    }

    /// Converts a point in the container's own (untransformed by zoom/pan)
    /// coordinate space into a normalized (0...1) fraction of the image's
    /// full extent, accounting for the overflow that `.aspectRatio(.fill)`
    /// crops off when the image's aspect ratio doesn't match the container's.
    private func normalizedImagePoint(forContainerPoint point: CGPoint, containerSize: CGSize) -> CGPoint {
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
    private func containerPoint(forNormalizedPoint normalized: CGPoint, containerSize: CGSize) -> CGPoint {
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
    private func loupeCrop(in image: UIImage, atNormalizedPoint normalizedPoint: CGPoint, pixelSize: Int) -> UIImage? {
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

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }

            await MainActor.run {
                selectedImage = image
                paletteMarkers = []
                totalZoom = 1
                currentZoomDelta = 0
                totalPan = .zero
                currentPanDelta = .zero

                let center = CGPoint(x: 0.5, y: 0.5)
                if let color = sampleColor(in: image, atNormalizedPoint: center) {
                    activeMarker = PhotoColorMarker(id: UUID(), position: center, rgb: color)
                } else {
                    activeMarker = nil
                }
            }
        }
    }
}

// MARK: - Markers

/// The point currently under review, shown only while it's NOT being
/// dragged (dragging shows the magnifying `LoupeView` instead) — a small
/// precise ring+crosshair, matching the reticle used on the Camera screen.
private struct ActiveMarkerView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 32, height: 32)
            Rectangle()
                .fill(Color.white)
                .frame(width: 10, height: 1.5)
            Rectangle()
                .fill(Color.white)
                .frame(width: 1.5, height: 10)
        }
        .shadow(color: .black.opacity(0.3), radius: 3)
    }
}

/// A previously-saved point, marked permanently on the image.
private struct SavedMarkerView: View {
    var body: some View {
        Circle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: 28, height: 28)
            .shadow(color: .black.opacity(0.3), radius: 2)
    }
}

// MARK: - LoupeView

/// A circular magnifier shown while dragging the active picking point: a
/// nearest-neighbor-scaled crop of the source image, so individual source
/// pixels read as a visible grid, with a thin square marking the exact
/// pixel being sampled and an outer ring tinted to the live sampled color.
private struct LoupeView: View {
    static let diameter: CGFloat = 130
    static let contentDiameter: CGFloat = 112
    static let ringWidth: CGFloat = 8
    static let cropPixelSize: CGFloat = 21

    let crop: UIImage?
    let tint: Color

    private var cellSize: CGFloat { Self.contentDiameter / Self.cropPixelSize }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: Self.diameter, height: Self.diameter)

            Group {
                if let crop {
                    Image(uiImage: crop)
                        .interpolation(.none)
                        .resizable()
                } else {
                    Color(.systemGray4)
                }
            }
            .frame(width: Self.contentDiameter, height: Self.contentDiameter)
            .clipShape(Circle())

            Rectangle()
                .stroke(Color.black.opacity(0.35), lineWidth: 1)
                .frame(width: cellSize, height: cellSize)

            Circle()
                .stroke(tint, lineWidth: Self.ringWidth)
                .frame(width: Self.diameter - Self.ringWidth, height: Self.diameter - Self.ringWidth)
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
    }
}

// MARK: - Pixel sampling

/// Reads the RGB color of the pixel at `normalizedPoint` (0...1 fractions,
/// origin top-left) in `image`'s own native pixel buffer. `normalizedPoint`
/// must already be expressed relative to the *image's* full extent, not
/// whatever frame/aspect it happens to be displayed at — see
/// `PhotoColorPickerView`'s `normalizedImagePoint(forContainerPoint:...)` for
/// the piece that converts an on-screen point into this space.
func sampleColor(in image: UIImage, atNormalizedPoint normalizedPoint: CGPoint) -> RGBColor? {
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

    // Most UIImage-backed CGImages are byte-order RGBA or BGRA; alphaInfo
    // tells us which. We handle the common premultiplied-first/last cases.
    let alphaInfo = cgImage.alphaInfo
    let isBGRFirst = alphaInfo == .premultipliedFirst || alphaInfo == .first || alphaInfo == .noneSkipFirst

    let r: Int
    let g: Int
    let b: Int
    if isBGRFirst {
        b = Int(bytes[offset + 1])
        g = Int(bytes[offset + 2])
        r = Int(bytes[offset + 3])
    } else {
        r = Int(bytes[offset])
        g = Int(bytes[offset + 1])
        b = Int(bytes[offset + 2])
    }

    return RGBColor(r: r, g: g, b: b)
}

// MARK: - Preview

#Preview {
    NavigationStack {
        PhotoColorPickerView()
            .environment(SavedColorsStore())
            .environment(PaletteStore())
    }
}
