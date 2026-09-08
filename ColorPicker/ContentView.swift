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

    var body: some View {
        HomeView(incomingURL: $viewModel.incomingURL)
            .environment(viewModel.savedColorsStore)
            .environment(viewModel.paletteStore)
            .overlay {
                if viewModel.isOnboardingVisible {
                    OnboardingView(isOnboardingVisible: $viewModel.isOnboardingVisible)
                        .transition(.opacity)
                }
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
    }
}

#Preview {
    ContentView()
}
