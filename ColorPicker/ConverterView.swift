//
//  ConverterView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI
import UIKit

// MARK: - ConverterField

fileprivate enum ConverterField: Hashable {
    case hex, r, g, b, c, m, y, k
}

// MARK: - ConverterView

struct ConverterView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(SavedColorsStore.self) private var savedColorsStore

    @State private var currentColor = RGBColor(r: 0, g: 0, b: 0)
    @State private var hasEnteredColor = false
    @State private var showSavedToast = false
    @State private var showsColorPicker = false

    @State private var hexText = "#000000"
    @State private var rText = "0"
    @State private var gText = "0"
    @State private var bText = "0"
    @State private var cText = "0"
    @State private var mText = "0"
    @State private var yText = "0"
    @State private var kText = "0"

    @FocusState private var focusedField: ConverterField?

    private var nearestRAL: RALColor { RALPalette.nearestRALColor(to: currentColor) }

    var body: some View {
        VStack(spacing: 20) {
            hexField

            rgbRow

            cmykRow

            colorPickerRow

            ColorInfoCard(rgb: currentColor, ral: nearestRAL, showsBorder: true)

            Spacer(minLength: 12)

            saveButton
        }
        .padding(16)
        .background(Color(.systemBackground))
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
                Text("Конвертер")
                    .font(.headline)
            }
        }
        .onChange(of: focusedField) { oldValue, _ in
            commit(field: oldValue)
        }
        .savedToast(isPresented: $showSavedToast, text: "Сохранено")
        .sheet(isPresented: $showsColorPicker) {
            NavigationStack {
                ConverterColorPicker(color: Binding(
                    get: { currentColor },
                    set: {
                        currentColor = $0
                        hasEnteredColor = true
                        syncFields(skipping: nil)
                    }
                ))
                .navigationTitle("Выбрать цвет")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") { showsColorPicker = false }
                    }
                }
            }
        }
    }

    // MARK: Fields

    private var hexField: some View {
        BorderedField(label: "Hex", text: $hexText, focus: $focusedField, field: .hex)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .onChange(of: hexText) { _, newValue in
                hexText = newValue.uppercased()
            }
    }

    private var rgbRow: some View {
        HStack(spacing: 12) {
            BorderedField(label: "R", text: $rText, focus: $focusedField, field: .r)
                .keyboardType(.numberPad)
            BorderedField(label: "G", text: $gText, focus: $focusedField, field: .g)
                .keyboardType(.numberPad)
            BorderedField(label: "B", text: $bText, focus: $focusedField, field: .b)
                .keyboardType(.numberPad)
        }
    }

    private var cmykRow: some View {
        HStack(spacing: 12) {
            BorderedField(label: "C", text: $cText, focus: $focusedField, field: .c)
                .keyboardType(.numberPad)
            BorderedField(label: "M", text: $mText, focus: $focusedField, field: .m)
                .keyboardType(.numberPad)
            BorderedField(label: "Y", text: $yText, focus: $focusedField, field: .y)
                .keyboardType(.numberPad)
            BorderedField(label: "K", text: $kText, focus: $focusedField, field: .k)
                .keyboardType(.numberPad)
        }
    }

    private var colorPickerRow: some View {
        HStack(spacing: 12) {
            Text("Выбрать цвет:")
            Button {
                commit(field: focusedField)
                focusedField = nil
                showsColorPicker = true
            } label: {
                Circle()
                    .fill(Color(hex: currentColor.hexString))
                    .frame(width: 28, height: 28)
                    .padding(4)
                    .overlay {
                        Circle().strokeBorder(
                            AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], center: .center),
                            lineWidth: 3
                        )
                    }
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Выбрать цвет")
            .accessibilityValue(currentColor.hexString)
            Spacer(minLength: 0)
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Сохранить")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(hasEnteredColor ? Color.tealAccent : Color(.systemGray4))
                )
        }
        .disabled(!hasEnteredColor)
    }

    // MARK: Sync logic

    private func commit(field: ConverterField?) {
        guard let field else { return }
        switch field {
        case .hex:
            commitHex()
        case .r, .g, .b:
            commitRGB()
        case .c, .m, .y, .k:
            commitCMYK()
        }
    }

    private func commitHex() {
        guard let parsed = RGBColor(hex: hexText) else {
            syncFields(skipping: .hex)
            return
        }
        currentColor = parsed
        hasEnteredColor = true
        syncFields(skipping: .hex)
    }

    private func commitRGB() {
        let r = RGBColor.clampChannel(Int(rText) ?? currentColor.r)
        let g = RGBColor.clampChannel(Int(gText) ?? currentColor.g)
        let b = RGBColor.clampChannel(Int(bText) ?? currentColor.b)
        currentColor = RGBColor(r: r, g: g, b: b)
        hasEnteredColor = true
        syncFields(skipping: nil)
    }

    private func commitCMYK() {
        let existing = currentColor.cmyk
        let c = RGBColor.clampPercent(Int(cText) ?? existing.c)
        let m = RGBColor.clampPercent(Int(mText) ?? existing.m)
        let y = RGBColor.clampPercent(Int(yText) ?? existing.y)
        let k = RGBColor.clampPercent(Int(kText) ?? existing.k)
        currentColor = RGBColor(c: c, m: m, y: y, k: k)
        hasEnteredColor = true
        syncFields(skipping: nil)
    }

    /// Refreshes every field from `currentColor`, except the field the user
    /// is still actively editing (so we don't stomp on the exact text they
    /// typed until they move on).
    private func syncFields(skipping field: ConverterField?) {
        if field != .hex { hexText = currentColor.hexString }
        if field != .r { rText = "\(currentColor.r)" }
        if field != .g { gText = "\(currentColor.g)" }
        if field != .b { bText = "\(currentColor.b)" }

        let cmyk = currentColor.cmyk
        if field != .c { cText = "\(cmyk.c)" }
        if field != .m { mText = "\(cmyk.m)" }
        if field != .y { yText = "\(cmyk.y)" }
        if field != .k { kText = "\(cmyk.k)" }
    }

    // MARK: Save

    private func save() {
        savedColorsStore.add(rgb: currentColor, note: "")
        showSavedToast = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            dismiss()
        }
    }
}

private struct ConverterColorPicker: View {
    @Binding var color: RGBColor

    var body: some View {
        if #available(iOS 26.0, *) {
            NativeConverterColorPicker(color: $color)
        } else {
            // Earlier iOS versions cannot disable the native eyedropper.
            Form {
                ColorInfoCard(rgb: color, ral: RALPalette.nearestRALColor(to: color))
                channel("R", keyPath: \.r)
                channel("G", keyPath: \.g)
                channel("B", keyPath: \.b)
            }
        }
    }

    private func channel(_ label: String, keyPath: WritableKeyPath<RGBColor, Int>) -> some View {
        VStack(alignment: .leading) {
            Text("\(label): \(color[keyPath: keyPath])")
            Slider(value: Binding(
                get: { Double(color[keyPath: keyPath]) },
                set: { color[keyPath: keyPath] = Int($0.rounded()) }
            ), in: 0...255, step: 1)
            .accessibilityLabel(label)
        }
    }
}

@available(iOS 26.0, *)
private struct NativeConverterColorPicker: UIViewControllerRepresentable {
    @Binding var color: RGBColor

    func makeUIViewController(context: Context) -> UIColorPickerViewController {
        let picker = UIColorPickerViewController()
        picker.supportsAlpha = false
        picker.supportsEyedropper = false
        picker.selectedColor = UIColor(Color(hex: color.hexString))
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIColorPickerViewController, context: Context) {
        context.coordinator.parent = self
        let selected = UIColor(Color(hex: color.hexString))
        if !picker.selectedColor.isEqual(selected) {
            picker.selectedColor = selected
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIColorPickerViewControllerDelegate {
        var parent: NativeConverterColorPicker

        init(parent: NativeConverterColorPicker) { self.parent = parent }

        func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            guard color.getRed(&r, green: &g, blue: &b, alpha: &a) else { return }
            parent.color = RGBColor(
                r: RGBColor.clampChannel(Int((r * 255).rounded())),
                g: RGBColor.clampChannel(Int((g * 255).rounded())),
                b: RGBColor.clampChannel(Int((b * 255).rounded()))
            )
        }
    }
}

// MARK: - BorderedField

private struct BorderedField: View {
    let label: String
    @Binding var text: String
    var focus: FocusState<ConverterField?>.Binding
    let field: ConverterField

    var body: some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .foregroundStyle(.secondary)
            TextField("", text: $text)
                .focused(focus, equals: field)
                .submitLabel(.done)
                .onSubmit { focus.wrappedValue = nil }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConverterView()
            .environment(SavedColorsStore())
    }
}
