import SwiftUI
import AVFoundation

// MARK: - PaywallView

/// Full-screen subscription pitch, presented from Settings' "Go Premium"
/// row. Purchases aren't wired to a real product yet — the CTA and the
/// footer links fall back to the same placeholder alert `SettingsView`
/// already uses for its other not-yet-available rows.
struct PaywallView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = PaywallViewModel()

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 22) {
                    header
                        .frame(height: min(280, geometry.size.height * 0.36))
                    featuresSection
                        .padding(.horizontal, 48)
                    pricingSection
                        .padding(.horizontal, 20)
                    Spacer(minLength: 24)
                }
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .overlay(alignment: .topLeading) { closeButton }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ctaSection
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .padding(.bottom, 16)
                .background(Color.black.ignoresSafeArea(edges: .bottom))
        }
        .background {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Color.black
                    LoopingVideoBackground()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .presentationBackground(Color.black)
        .preferredColorScheme(.dark)
        .alert("Перейти на Premium", isPresented: $viewModel.showsUnavailableAlert) {
            Button("OK") {}
        } message: {
            Text("Покупки пока недоступны. Попробуйте позже.")
        }
    }

    private var closeButton: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.7), radius: 3)
                .frame(width: 44, height: 44)
                .background(Color(hex: "222330"), in: Circle())
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Закрыть")
        .padding(.leading, 12)
        .padding(.top, 4)
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .bottom) {
            Text("Подберите цвет с первого раза")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.9), radius: 6, y: 2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(Color(hex: "222330"), in: RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    // MARK: Features

    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.features) { feature in
                FeatureRow(feature: feature)
            }
        }
    }

    // MARK: Pricing

    private var pricingSection: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.plans) { plan in
                PlanCard(plan: plan, isSelected: viewModel.selectedPlan == plan.kind) {
                    viewModel.selectedPlan = plan.kind
                }
            }
        }
        .padding(.top, 6)
    }

    // MARK: CTA

    private var ctaSection: some View {
        VStack(spacing: 18) {
            Button(action: viewModel.unlockTapped) {
                Text("Открыть Picker Pro")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "9784F5"), Color(hex: "7060DB")],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color(hex: "AC9CF8").opacity(0.6), lineWidth: 1)
                    }
                    .shadow(color: Color(hex: "8065EC").opacity(0.3), radius: 18, y: 4)
            }
            .buttonStyle(SoftPressButtonStyle())

            HStack(spacing: 6) {
                footerLink("Восстановить")
                Spacer(minLength: 4)
                footerLink("Условия")
                Spacer(minLength: 4)
                footerLink("Конфиденциальность")
            }
            .font(.system(size: 12))
        }
    }

    private func footerLink(_ title: LocalizedStringKey) -> some View {
        Button(action: viewModel.unlockTapped) {
            Text(title)
                .foregroundStyle(.white.opacity(0.45))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let feature: PaywallFeature

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 23, weight: .medium))
                .frame(width: 30, height: 30)
            Text(feature.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(hex: "222330"), in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - PlanCard

private struct PlanCard: View {
    let plan: PricingPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(plan.badge)
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(0.3)
                    .foregroundStyle(isSelected ? Color(hex: "8065EC") : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(isSelected ? Color.white : Color(hex: "727272"), in: Capsule())
                    .padding(6)

                VStack(spacing: 4) {
                    Text(plan.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(plan.detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(minHeight: 20)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 6)

                Rectangle()
                    .fill(.black.opacity(0.12))
                    .frame(height: 1)

                VStack(spacing: 4) {
                    Text(plan.price)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(plan.billingPeriod)
                        .font(.system(size: 13, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 5)
                .padding(.vertical, 10)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isSelected ? 6 : 0)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isSelected ? Color(hex: "8065EC") : Color(hex: "484848"))
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(isSelected ? Color(hex: "A995FF") : .white.opacity(0.1), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Looping video

private struct LoopingVideoBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        guard let asset = NSDataAsset(name: "paywall_video") else { return view }
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("paywall_video.mp4")
        // Refresh the cache so a replaced asset cannot leave an old recording playing.
        do {
            try asset.data.write(to: url, options: .atomic)
        } catch {
            return view
        }
        context.coordinator.play(url: url, in: view)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.stop()
        uiView.playerLayer.player = nil
    }

    final class Coordinator {
        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var preparationTask: Task<Void, Never>?

        func play(url: URL, in view: PlayerContainerView) {
            preparationTask = Task { @MainActor [weak self, weak view] in
                let asset = AVURLAsset(url: url)
                guard let track = try? await asset.loadTracks(withMediaType: .video).first,
                      let naturalSize = try? await track.load(.naturalSize),
                      let transform = try? await track.load(.preferredTransform),
                      !Task.isCancelled,
                      let self, let view else { return }
                let rect = CGRect(origin: .zero, size: naturalSize).applying(transform)
                view.videoSize = CGSize(width: abs(rect.width), height: abs(rect.height))
                view.setNeedsLayout()
                view.layoutIfNeeded()
                let player = AVQueuePlayer()
                player.isMuted = true
                self.looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: asset))
                self.player = player
                view.playerLayer.player = player
                player.play()
            }
        }

        func stop() {
            preparationTask?.cancel()
            preparationTask = nil
            player?.pause()
            looper?.disableLooping()
            player?.removeAllItems()
            looper = nil
            player = nil
        }
    }

    final class PlayerContainerView: UIView {
        let playerLayer = AVPlayerLayer()
        // Read from the asset before playback, independent of the looper's
        // asynchronously inserted/replaced current items.
        var videoSize: CGSize = .zero

        override func layoutSubviews() {
            super.layoutSubviews()
            let size = videoSize
            let height = size.width > 0 ? bounds.width * size.height / size.width : bounds.height
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: height)
            CATransaction.commit()
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .black
            isOpaque = true
            clipsToBounds = true
            playerLayer.videoGravity = .resizeAspect
            layer.addSublayer(playerLayer)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
