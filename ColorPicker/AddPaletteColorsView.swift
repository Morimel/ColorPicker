import SwiftUI

struct AddPaletteColorsView: View {
    let paletteID: UUID

    @Environment(\.dismiss) private var dismiss
    @Environment(PaletteStore.self) private var paletteStore
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @State private var selectedIDs: Set<UUID> = []
    @State private var hexText = ""

    private var customRGB: RGBColor? {
        RGBColor(hex: hexText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var hasHexInput: Bool {
        !hexText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var colorsToAdd: [SavedColor] {
        var colors = savedColorsStore.savedColors.filter { selectedIDs.contains($0.id) }
        if let rgb = customRGB {
            colors.append(SavedColor(rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb),
                                     note: "", createdAt: Date()))
        }
        return colors
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Новый цвет") {
                    TextField("HEX, например #A6B32A", text: $hexText)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    if let rgb = customRGB {
                        ColorInfoCard(rgb: rgb, ral: RALPalette.nearestRALColor(to: rgb))
                    } else if hasHexInput {
                        Text("Введите HEX из 6 символов: 0–9, A–F.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Сохранённые цвета") {
                    if savedColorsStore.savedColors.isEmpty {
                        Text("Нет сохранённых цветов. Добавьте новый цвет по HEX выше.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(savedColorsStore.savedColors) { entry in
                        Button {
                            if selectedIDs.contains(entry.id) {
                                selectedIDs.remove(entry.id)
                            } else {
                                selectedIDs.insert(entry.id)
                            }
                        } label: {
                            HStack {
                                ColorInfoCard(rgb: entry.rgb, ral: entry.ral)
                                Image(systemName: selectedIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Color.tealAccent)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedIDs.contains(entry.id) ? .isSelected : [])
                    }
                }
            }
            .navigationTitle("Добавить цвета")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить (\(colorsToAdd.count))") {
                        paletteStore.add(colors: colorsToAdd, to: paletteID)
                        dismiss()
                    }
                    .disabled(colorsToAdd.isEmpty || (hasHexInput && customRGB == nil))
                }
            }
        }
    }
}
