//
//  OnboardingView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI

// MARK: - Pages

enum OnboardingPage: String, Identifiable, CaseIterable {
    case colorScan
    case inspireCreate
    case quickFind

    var id: String { rawValue }
}

// MARK: - OnboardingView

struct OnboardingView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isOnboardingVisible: Bool

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(OnboardingPage.allCases) { page in
                            pageContent(for: page)
                                .containerRelativeFrame(.horizontal)
                                .id(page.id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                // Navigation only happens via the Continue button, never by swiping.
                .scrollDisabled(true)

                pageDots
                    .padding(.top, 12)

                continueButton(proxy: proxy)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
            }
            .background(Color(.systemBackground))
            .onAppear {
                // Make sure we always start from the first page.
                proxy.scrollTo(viewModel.currentPage.id, anchor: .leading)
            }
        }
    }

    @ViewBuilder
    private func pageContent(for page: OnboardingPage) -> some View {
        switch page {
        case .colorScan:
            ColorScanPage(isActive: viewModel.currentPage == .colorScan)
        case .inspireCreate:
            InspireCreatePage(isActive: viewModel.currentPage == .inspireCreate)
        case .quickFind:
            QuickFindPage(isActive: viewModel.currentPage == .quickFind)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingPage.allCases) { page in
                Circle()
                    .fill(page == viewModel.currentPage ? Color.tealAccent : Color(.systemGray4))
                    .frame(width: 8, height: 8)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.currentPage)
    }

    private func continueButton(proxy: ScrollViewProxy) -> some View {
        Button(action: { handleContinue(proxy: proxy) }) {
            Text("Продолжить")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.tealAccent)
                )
        }
        .buttonStyle(SoftPressButtonStyle())
        .padding(.horizontal, 24)
    }

    private func handleContinue(proxy: ScrollViewProxy) {
        if let nextPage = viewModel.nextPage() {
            withAnimation(reduceMotion ? nil : AppMotion.spring) {
                proxy.scrollTo(nextPage.id, anchor: .leading)
                viewModel.currentPage = nextPage
            }
        } else {
            // Last page: finish onboarding instead of scrolling further.
            hasCompletedOnboarding = true
            withAnimation(reduceMotion ? nil : AppMotion.spring) {
                isOnboardingVisible = false
            }
        }
    }
}

// MARK: - Shared page pieces

private struct OnboardingHeader: View {
    let headline: LocalizedStringKey
    let subtext: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Text(headline)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(subtext)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }
}

/// Displays one of the Lottie illustrations, large — filling the same slot
/// the static onboarding mockups used to occupy, instead of playing as a
/// small corner badge on top of them.
private struct OnboardingVisual: View {
    let animation: LottieArtwork.Asset
    let isActive: Bool

    var body: some View {
        LottieArtwork(asset: animation, isActive: isActive)
            .aspectRatio(343.0 / 409.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
    }
}

// MARK: - Screen 1: Color Scan

struct ColorScanPage: View {
    var isActive = true
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                headline: "Мгновенное определение цветов",
                subtext: "Наведите камеру — получите точный код цвета за секунду!"
            )

            OnboardingVisual(animation: .scan, isActive: isActive)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Screen 2: Inspire & Create

struct InspireCreatePage: View {
    var isActive = true
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                headline: "Вдохновляйтесь и создавайте",
                subtext: "Подбирайте идеальные цветовые решения для ваших творческих проектов в один клик"
            )

            OnboardingVisual(animation: .palette, isActive: isActive)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Screen 3: Quick Find

struct QuickFindPage: View {
    var isActive = true
    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(
                headline: "Простой способ найти нужный цвет",
                subtext: "Мгновенный доступ к названиям и цветовым кодам в любых форматах — HEX, RGB, CMYK"
            )

            OnboardingVisual(animation: .search, isActive: isActive)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Helpers

extension Color {
    static let tealAccent = Color(hex: "3E8E9E")

    init(hex: String) {
        let hexString = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isOnboardingVisible: .constant(true))
}
