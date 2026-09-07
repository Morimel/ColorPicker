//
//  CameraColorPickerView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI
import AVFoundation

// MARK: - CameraColorPickerView

struct CameraColorPickerView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SavedColorsStore.self) private var savedColorsStore

    @State private var cameraController = CameraFrameController()
    @State private var permissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var detectedColor = RGBColor(r: 204, g: 197, b: 143)
    @State private var note: String = ""
    @State private var sampleTimer: Timer?
    @State private var isFlashOn = false
    @FocusState private var isNoteFocused: Bool

    /// Colors captured with "+" during this session, kept in memory only
    /// until "Save" commits them all to `SavedColorsStore` at once.
    @State private var stagedColors: [SavedColor] = []
    @State private var showSavedToast = false

    private var nearestRAL: RALColor { RALPalette.nearestRALColor(to: detectedColor) }

    var body: some View {
        VStack(spacing: 0) {
            cameraContent

            resultSection
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
                Button(action: saveStagedColors) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .foregroundStyle(stagedColors.isEmpty ? .tertiary : .primary)
                }
                .disabled(stagedColors.isEmpty)
            }
        }
        .onAppear(perform: requestPermissionIfNeeded)
        .onDisappear {
            sampleTimer?.invalidate()
            cameraController.setTorchEnabled(false)
            cameraController.stop()
        }
        .savedToast(isPresented: $showSavedToast, text: "Сохранено")
    }

    @ViewBuilder
    private var cameraContent: some View {
        switch permissionStatus {
        case .authorized:
            ZStack {
                CameraPreviewView(controller: cameraController)
                    .onAppear {
                        cameraController.start()
                        startSampling()
                    }

                Reticle()

                HStack {
                    Button(action: toggleFlash) {
                        CameraOverlayButton(systemImage: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    }

                    Spacer()

                    NavigationLink(value: HomeDestination.photo) {
                        CameraOverlayButton(systemImage: "photo.on.rectangle")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            .background(Color(.secondarySystemBackground))
        case .notDetermined:
            placeholder(text: "Запрашиваем доступ к камере…")
        case .denied, .restricted:
            deniedPlaceholder
        @unknown default:
            placeholder(text: "Камера недоступна")
        }
    }

    private func placeholder(text: String) -> some View {
        ZStack {
            Color(.secondarySystemBackground)
            Text(text)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
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
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .background(Color(.secondarySystemBackground))
    }

    private var resultSection: some View {
        VStack(spacing: 14) {
            ColorInfoCard(
                rgb: detectedColor,
                ral: nearestRAL,
                trailingAction: addCurrentColor
            )

            TextField("Заметка (необязательно)", text: $note)
                .focused($isNoteFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )

            if !stagedColors.isEmpty {
                stagedColorsStrip
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var stagedColorsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Захваченные цвета")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(stagedColors) { color in
                    Color(hex: color.rgb.hexString)
                }
            }
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func toggleFlash() {
        isFlashOn.toggle()
        cameraController.setTorchEnabled(isFlashOn)
    }

    private func addCurrentColor() {
        let entry = SavedColor(rgb: detectedColor, ral: nearestRAL, note: note, createdAt: Date())
        stagedColors.append(entry)
    }

    private func saveStagedColors() {
        guard !stagedColors.isEmpty else { return }
        for color in stagedColors {
            savedColorsStore.add(rgb: color.rgb, note: color.note)
        }
        stagedColors.removeAll()
        showSavedToast = true
    }

    private func requestPermissionIfNeeded() {
        switch permissionStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    permissionStatus = granted ? .authorized : .denied
                }
            }
        default:
            break
        }
    }

    private func startSampling() {
        sampleTimer?.invalidate()
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if let color = cameraController.centerPixelColor() {
                detectedColor = color
            }
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

// MARK: - CameraFrameController

/// Owns the capture session and exposes the pixel color at the center of the
/// current video frame, sampled from the live buffer (not the preview layer).
@Observable
final class CameraFrameController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sampleQueue = DispatchQueue(label: "camera.frame.sample.queue")
    private var latestPixelBuffer: CVPixelBuffer?
    private let bufferLock = NSLock()
    private var captureDevice: AVCaptureDevice?

    override init() {
        super.init()
        configureSession()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .medium

        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            captureDevice = device
        }

        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    func start() {
        guard !session.isRunning else { return }
        sampleQueue.async { [session] in
            session.startRunning()
        }
    }

    func stop() {
        guard session.isRunning else { return }
        sampleQueue.async { [session] in
            session.stopRunning()
        }
    }

    /// Controls the torch (flashlight) for the live preview — not a photo
    /// capture flash, since we're continuously sampling color, not shooting.
    func setTorchEnabled(_ enabled: Bool) {
        guard let captureDevice, captureDevice.hasTorch else { return }
        guard (try? captureDevice.lockForConfiguration()) != nil else { return }
        captureDevice.torchMode = enabled ? .on : .off
        captureDevice.unlockForConfiguration()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        bufferLock.lock()
        latestPixelBuffer = pixelBuffer
        bufferLock.unlock()
    }

    /// Samples the pixel at the center of the most recent video frame.
    func centerPixelColor() -> RGBColor? {
        bufferLock.lock()
        let buffer = latestPixelBuffer
        bufferLock.unlock()

        guard let buffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }

        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)

        let x = width / 2
        let y = height / 2

        let pixelPointer = base.advanced(by: y * bytesPerRow + x * 4)
        let pixel = pixelPointer.assumingMemoryBound(to: UInt8.self)

        // kCVPixelFormatType_32BGRA byte order: B, G, R, A.
        let b = Int(pixel[0])
        let g = Int(pixel[1])
        let r = Int(pixel[2])

        return RGBColor(r: r, g: g, b: b)
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
