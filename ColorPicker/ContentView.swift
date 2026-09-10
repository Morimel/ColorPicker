//
//  ContentView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI

struct ContentView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = RootViewModel()
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            HomeView(incomingURL: $viewModel.incomingURL)
                .environment(viewModel.savedColorsStore)
                .environment(viewModel.paletteStore)
                .overlay {
                    if viewModel.isOnboardingVisible {
                        OnboardingView(
                            isOnboardingVisible: $viewModel.isOnboardingVisible,
                            onFinished: {
                                guard !SubscriptionStore.shared.isSubscribed else { return }
                                viewModel.showsPostOnboardingPaywall = true
                            }
                        )
                        .transition(.opacity)
                    }
                }
                .fullScreenCover(isPresented: $viewModel.showsPostOnboardingPaywall) {
                    PaywallView()
                }
                .onOpenURL { url in
                    viewModel.handleOpenURL(url)
                }
                .alert("Сохранённые цвета", isPresented: Binding(
                    get: { viewModel.persistenceError != nil },
                    set: { if !$0 { viewModel.persistenceError = nil } }
                )) {
                    Button("OK") { viewModel.persistenceError = nil }
                } message: {
                    Text(viewModel.persistenceError ?? "")
                }
                .animation(reduceMotion ? nil : .easeInOut, value: viewModel.isOnboardingVisible)

            if showsSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                showsSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}
