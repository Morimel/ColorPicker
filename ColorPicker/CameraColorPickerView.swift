//
//  CameraColorPickerView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI
import AVFoundation

// MARK: - CameraColorPickerView

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns the store outright rather
/// than receiving it per call — is created once here and handed down.
struct CameraColorPickerView: View {
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @State private var viewModel: CameraViewModel?

    var body: some View {
        Group {
            if let viewModel {
                CameraColorPickerContent(viewModel: viewModel)
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
                viewModel = CameraViewModel(store: savedColorsStore)
            }
        }
    }
}

// MARK: - CameraColorPickerContent

private struct CameraColorPickerContent: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Bindable var viewModel: CameraViewModel
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            // Landscape (or an iPad's regular width) puts the preview and the
            // result side by side instead of stacking them, so the capture
            // flow keeps working when there isn't much vertical room.
            let isSideBySide = geometry.size.width > geometry.size.height || horizontalSizeClass == .regular

            Group {
                if isSideBySide {
                    HStack(spacing: 0) {
                        cameraContent
                            .frame(width: geometry.size.width * 0.55)
                        ScrollView {
                            resultSection
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        cameraContent
                            .frame(height: geometry.size.height * 0.46)
                        ScrollView {
                            resultSection
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            isNoteFocused = false
        }
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
                Text("Камера")
                    .font(.headline)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: viewModel.saveStagedColors) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .foregroundStyle(viewModel.stagedColors.isEmpty ? .tertiary : .primary)
                }
                .disabled(viewModel.stagedColors.isEmpty)
            }
        }
        .onAppear(perform: viewModel.requestPermissionIfNeeded)
        .onDisappear(perform: viewModel.onDisappear)
        .savedToast(isPresented: $viewModel.showSavedToast, text: "Сохранено")
    }

    @ViewBuilder
    private var cameraContent: some View {
        switch viewModel.permissionStatus {
        case .authorized:
            ZStack {
                CameraPreviewView(controller: viewModel.cameraController)
                    .onAppear {
                        viewModel.cameraController.start()
                        viewModel.startSampling()
                    }

                Reticle()

                HStack {
                    Button(action: viewModel.toggleFlash) {
                        CameraOverlayButton(systemImage: viewModel.isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    }

                    Spacer()

                    NavigationLink(value: HomeDestination.photo) {
                        CameraOverlayButton(systemImage: "photo.on.rectangle")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.secondarySystemBackground))
        case .notDetermined:
            placeholder(text: "Запрашиваем доступ к камере…")
        case .denied, .restricted:
            deniedPlaceholder
        @unknown default:
            placeholder(text: "Камера недоступна")
        }
    }

    private func placeholder(text: LocalizedStringKey) -> some View {
        ZStack {
            Color(.secondarySystemBackground)
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var deniedPlaceholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text("Нет доступа к камере")
                .font(.headline)
            Text("Разрешите доступ к камере в настройках, чтобы определять цвета в реальном времени.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Открыть настройки") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.tealAccent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
    }

    private var resultSection: some View {
        VStack(spacing: 14) {
            ColorInfoCard(
                rgb: viewModel.detectedColor,
                ral: viewModel.nearestRAL,
                trailingAction: viewModel.addCurrentColor
            )

            TextField("Заметка (необязательно)", text: $viewModel.note)
                .focused($isNoteFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

            if !viewModel.stagedColors.isEmpty {
                stagedColorsStrip
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : AppMotion.spring, value: viewModel.stagedColors.count)
        .padding(16)
    }

    @ViewBuilder
    private var stagedColorsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Захваченные цвета")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(viewModel.stagedColors) { color in
                    Color(hex: color.rgb.hexString)
                }
            }
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Reticle

/// A circular ring with a small crosshair centered inside it, so the user can
/// align the exact point sampled (the crosshair intersection) rather than
/// eyeballing the middle of an empty circle.
private struct Reticle: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 2.5)
                .frame(width: 36, height: 36)

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

// MARK: - CameraPreviewView

private struct CameraPreviewView: UIViewRepresentable {
    let controller: CameraFrameController

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = controller.session
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        override init(frame: CGRect) {
            super.init(frame: frame)
            previewLayer.videoGravity = .resizeAspectFill
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CameraColorPickerView()
            .environment(SavedColorsStore())
            .environment(PaletteStore())
    }
}
