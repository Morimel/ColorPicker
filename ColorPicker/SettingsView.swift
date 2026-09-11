import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SettingsViewModel()
    @State private var showsPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Button {
                    showsPaywall = true
                } label: {
                    Text("Перейти на Premium")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 58)
                        .background(Color(hex: "EF7400"), in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(SoftPressButtonStyle())
                .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(SettingsAction.rows) { action in
                        Button {
                            handleTap(on: action)
                        } label: {
                            HStack {
                                Text(action.title)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 12)
                                if action == .restore && viewModel.isRestoring {
                                    ProgressView()
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Color(.tertiaryLabel))
                                }
                            }
                            .padding(.trailing, 16)
                            .frame(minHeight: 46)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(SoftPressButtonStyle())
                        .disabled(action == .restore && viewModel.isRestoring)

                        Divider()
                    }
                }
                .padding(.leading, 16)
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(Color.appAccent)
                }
                .accessibilityLabel("Назад")
            }
        }
        .alert(item: $viewModel.selectedAction) { action in
            // Destinations can be connected once the app's support links are
            // available. Restore is handled separately, via the real flow.
            Alert(
                title: Text(action.title),
                message: Text("Этот раздел пока недоступен. Попробуйте позже."),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Восстановить покупки", isPresented: Binding(
            get: { viewModel.restoreResultMessage != nil },
            set: { if !$0 { viewModel.restoreResultMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(viewModel.restoreResultMessage ?? "")
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView()
        }
    }

    private func handleTap(on action: SettingsAction) {
        if action == .restore {
            Task { await viewModel.restorePurchases() }
        } else {
            viewModel.selectedAction = action
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
