//
//  ContentView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 2/9/26.
//

import SwiftUI

struct ContentView: View {

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // Note: an @State default value can't reference a sibling @AppStorage property
    // (property initializers run before `self` exists), so we read the same key
    // straight out of UserDefaults here to seed the initial value.
    @State private var isOnboardingVisible = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    @State private var savedColorsStore = SavedColorsStore()
    @State private var paletteStore = PaletteStore()

    var body: some View {
        HomeView()
            .environment(savedColorsStore)
            .environment(paletteStore)
            .overlay {
                if isOnboardingVisible {
                    OnboardingView(isOnboardingVisible: $isOnboardingVisible)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut, value: isOnboardingVisible)
    }
}

#Preview {
    ContentView()
}
