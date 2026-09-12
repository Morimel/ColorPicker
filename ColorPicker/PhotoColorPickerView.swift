//
//  PhotoColorPickerView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI
import PhotosUI
import UIKit

// MARK: - PhotoColorPickerView

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns the store outright rather
/// than receiving it per call — is created once here and handed down.
struct PhotoColorPickerView: View {
    @Environment(PaletteStore.self) private var paletteStore
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @State private var viewModel: PhotoPickerViewModel?

    var body: some View {
        Group {
            if let viewModel {
                PhotoColorPickerContent(viewModel: viewModel)
            } else {
                // Never let this render as a truly empty view: inside a
                // NavigationStack, a view whose first frame has zero content
                // doesn't get `.task`/`.onAppear` delivered, so `viewModel`
                // would stay nil forever and the screen would stay blank.
                Color.clear
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PhotoPickerViewModel(paletteStore: paletteStore, savedColorsStore: savedColorsStore)
            }
        }
    }
}

// MARK: - PhotoColorPickerContent

private struct PhotoColorPickerContent: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Bindable var viewModel: PhotoPickerViewModel
    @State private var showsCapturedColorsSheet = false

    var body: some View {
        GeometryReader { geometry in
            // Landscape (or an iPad's regular width) puts the image and the
            // result side by side instead of stacking them, so the picking
            // flow keeps working when there isn't much vertical room.
            let isSideBySide = geometry.size.width > geometry.size.height || horizontalSizeClass == .regular

            Group {
                if isSideBySide {
                    HStack(spacing: 0) {
                        imageSection
                            .frame(width: geometry.size.width * 0.6)
                        ScrollView {
                            resultSection
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        imageSection
                            .frame(height: geometry.size.height * 0.6)
                        ScrollView {
                            resultSection
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
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
                Button(action: viewModel.savePalette) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .foregroundStyle(viewModel.paletteMarkers.isEmpty ? .tertiary : .primary)
                }
                .disabled(viewModel.paletteMarkers.isEmpty)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Сравнение с каталогами", selection: $viewModel.catalogMatchMode) {
                        Text("Сравнивать со всеми брендами").tag(CatalogMatchMode.allBrands)
                        Text("Сравнивать с одним брендом").tag(CatalogMatchMode.singleBrand)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.primary)
                }
            }
        }
        .photosPicker(isPresented: $viewModel.isPickerPresented, selection: $viewModel.selectedItem, matching: .images)
        .onChange(of: viewModel.selectedItem) { _, newItem in
            viewModel.loadImage(from: newItem)
        }
        .savedToast(isPresented: $viewModel.showSavedToast, text: "Палитра сохранена")
        .sheet(isPresented: $showsCapturedColorsSheet) {
            CapturedColorsSheet(entries: viewModel.paletteMarkers.map { (rgb: $0.rgb, ral: RALPalette.nearestRALColor(to: $0.rgb)) })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Image section

    private var imageSection: some View {
        GeometryReader { geometry in
            let containerSize = geometry.size

            ZStack(alignment: .bottomLeading) {
                Group {
                    if viewModel.selectedImage != nil {
                        transformableContent(containerSize: containerSize)
                            .frame(width: containerSize.width, height: containerSize.height)
                            .clipped()
                            .contentShape(Rectangle())
                            .gesture(viewModel.imageDragGesture(containerSize: containerSize))
                            .gesture(viewModel.magnificationGesture)
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded { viewModel.resetZoom() }
                                    .exclusively(before: viewModel.tapGesture(containerSize: containerSize))
                            )
                    } else {
                        emptyPlaceholder(containerSize: containerSize)
                    }
                }

                pickImageButton
                    .padding(16)

                if viewModel.activeDragMode == .moveMarker, let activeMarker = viewModel.activeMarker, let selectedImage = viewModel.selectedImage {
                    let point = viewModel.screenPosition(for: activeMarker.position, containerSize: containerSize)
                    let loupeCenter = CGPoint(x: point.x, y: point.y - viewModel.loupeVerticalOffset)

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
                        crop: viewModel.loupeCrop(in: selectedImage, atNormalizedPoint: activeMarker.position, pixelSize: Int(LoupeView.cropPixelSize)),
                        tint: Color(hex: activeMarker.rgb.hexString)
                    )
                    .position(x: loupeCenter.x, y: loupeCenter.y)
                    .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .top) {
                if viewModel.catalogMatchMode == .singleBrand {
                    BrandFilterRow(selectedCatalog: $viewModel.selectedCatalog)
                        .padding(.top, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func transformableContent(containerSize: CGSize) -> some View {
        ZStack {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: containerSize.width, height: containerSize.height)
                    .clipped()
            }

            ForEach(viewModel.paletteMarkers) { marker in
                let point = viewModel.containerPoint(forNormalizedPoint: marker.position, containerSize: containerSize)
                SavedMarkerView()
                    .position(x: point.x, y: point.y)
            }

            // Hidden while the loupe is up (drawn separately, in unscaled
            // container coordinates, over in `imageSection`) so the finger
            // isn't left resting on a duplicate indicator underneath it.
            if let activeMarker = viewModel.activeMarker, viewModel.activeDragMode != .moveMarker {
                let point = viewModel.containerPoint(forNormalizedPoint: activeMarker.position, containerSize: containerSize)
                ActiveMarkerView()
                    .position(x: point.x, y: point.y)
            }
        }
        .scaleEffect(viewModel.zoomScale)
        .offset(viewModel.panOffset)
    }

    private func emptyPlaceholder(containerSize: CGSize) -> some View {
        ZStack {
            Color(.secondarySystemBackground)
            ActiveMarkerView()
        }
        .frame(width: containerSize.width, height: containerSize.height)
    }

    private var pickImageButton: some View {
        Button(action: { viewModel.isPickerPresented = true }) {
            CameraOverlayButton(systemImage: "photo")
        }
    }

    // MARK: Result section

    @ViewBuilder
    private var resultSection: some View {
        VStack(spacing: 14) {
            if let activeMarker = viewModel.activeMarker {
                activeColorCard(for: activeMarker)
                if let match = viewModel.nearestCatalogMatch(for: activeMarker.rgb) {
                    CatalogMatchCard(match: match, locksWhenFree: true)
                }
            } else {
                emptySwatch
            }

            TextField("Заметка (необязательно)", text: $viewModel.note)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

            if !viewModel.paletteMarkers.isEmpty {
                paletteStrip
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : AppMotion.spring, value: viewModel.paletteMarkers.count)
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
            trailingAction: viewModel.saveActivePoint,
            locksWhenFree: true
        )
    }

    private var paletteStrip: some View {
        ColorStripView(colors: viewModel.paletteMarkers.map(\.rgb))
            .contentShape(Rectangle())
            .onTapGesture { showsCapturedColorsSheet = true }
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

// MARK: - Preview

#Preview {
    NavigationStack {
        PhotoColorPickerView()
            .environment(SavedColorsStore())
            .environment(PaletteStore())
    }
}
