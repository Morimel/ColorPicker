import Foundation
import AVFoundation

/// Owns all camera-capture state and logic for `CameraColorPickerView`, so the
/// view itself is limited to layout and bindings.
@Observable
final class CameraViewModel {
    private let store: SavedColorsStore
    private let paletteStore: PaletteStore

    private(set) var cameraController = CameraFrameController()
    var permissionStatus: AVAuthorizationStatus
    var detectedColor = RGBColor(r: 204, g: 197, b: 143)
    var note: String = ""
    var isFlashOn = false

    /// Colors captured with "+" during this session, kept in memory only
    /// until "Save" commits them all to `SavedColorsStore` at once.
    var stagedColors: [SavedColor] = []
    var showSavedToast = false

    /// Defaults to showing the brand row and matching within just one
    /// catalog — see `CatalogMatchMode`.
    var catalogMatchMode: CatalogMatchMode = .singleBrand
    var selectedCatalog: ColorCatalog = .ral

    private var sampleTimer: Timer?

    var nearestRAL: RALColor { RALPalette.nearestRALColor(to: detectedColor) }
    var nearestCatalogMatch: NearestCatalogMatch? {
        switch catalogMatchMode {
        case .allBrands:
            NearestCatalogColor.find(for: detectedColor)
        case .singleBrand:
            NearestCatalogColor.find(for: detectedColor, in: selectedCatalog)
        }
    }

    init(store: SavedColorsStore, paletteStore: PaletteStore) {
        self.store = store
        self.paletteStore = paletteStore
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermissionIfNeeded() {
        switch permissionStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionStatus = granted ? .authorized : .denied
                }
            }
        default:
            break
        }
    }

    func startSampling() {
        sampleTimer?.invalidate()
        sampleTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let color = cameraController.centerPixelColor() else { return }
            detectedColor = color
        }
    }

    func toggleFlash() {
        isFlashOn.toggle()
        cameraController.setTorchEnabled(isFlashOn)
    }

    func addCurrentColor() {
        let entry = SavedColor(rgb: detectedColor, ral: nearestRAL, note: note, createdAt: Date())
        stagedColors.append(entry)
    }

    /// Commits the staged colors both individually (so they show up in the
    /// Saved tab's "Цвета" grid) and grouped as one new palette (so they also
    /// show up in its "Палитры" segment) — the same dual save Photo's
    /// `savePalette()` does.
    func saveStagedColors() {
        guard !stagedColors.isEmpty, store.add(stagedColors) else { return }
        paletteStore.add(colors: stagedColors)
        stagedColors.removeAll()
        showSavedToast = true
    }

    /// Called from the view's `onDisappear` to release the camera session.
    func onDisappear() {
        sampleTimer?.invalidate()
        cameraController.setTorchEnabled(false)
        cameraController.stop()
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
