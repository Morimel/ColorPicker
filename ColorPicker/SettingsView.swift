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
                            viewModel.selectedAction = action
                        } label: {
                            HStack {
                                Text(action.title)
                                    .font(.system(size: 18))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 12)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                            .padding(.trailing, 16)
                            .frame(minHeight: 46)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(SoftPressButtonStyle())

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
                        .foregroundStyle(Color.tealAccent)
                }
                .accessibilityLabel("Назад")
            }
        }
        .alert(item: $viewModel.selectedAction) { action in
            // Destinations can be connected when the app's support links and
            // purchase flow are available. Never report an unperformed restore.
            Alert(
                title: Text(action.title),
                message: Text(action == .restore
                    ? "Покупки пока недоступны. Попробуйте позже."
                    : "Этот раздел пока недоступен. Попробуйте позже."),
                dismissButton: .default(Text("OK"))
            )
        }
        .fullScreenCover(isPresented: $showsPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
