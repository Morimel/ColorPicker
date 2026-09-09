//
//  ConverterView.swift
//  ColorPicker
//
//  Created by Isa Melsov on 4/9/26.
//

import SwiftUI
import UIKit

// MARK: - ConverterView

/// Thin wrapper: `@Environment` values aren't available until the view is in
/// the hierarchy, so the view model — which owns the store outright rather
/// than receiving it per call — is created once here and handed down.
struct ConverterView: View {
    @Environment(SavedColorsStore.self) private var savedColorsStore
    @State private var viewModel: ConverterViewModel?

    var body: some View {
        Group {
            if let viewModel {
                ConverterContent(viewModel: viewModel)
            } else {
                // Never let this render as a truly empty view: inside a
                // NavigationStack, a view whose first frame has zero content
                // doesn't get `.task`/`.onAppear` delivered, so `viewModel`
                // would stay nil forever and the screen would stay blank.
                Color.clear
            }
        }
        .task {
            if viewModel == nil {
                viewModel = ConverterViewModel(store: savedColorsStore)
            }
        }
    }
}

// MARK: - ConverterContent

private struct ConverterContent: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: ConverterViewModel
    @FocusState private var focusedField: ConverterField?

    var body: some View {
        VStack(spacing: 20) {
            hexField

            rgbRow

            cmykRow

            colorPickerRow

            ColorInfoCard(rgb: viewModel.currentColor, ral: viewModel.nearestRAL, showsBorder: true)

            if let match = viewModel.nearestCatalogMatch {
                CatalogMatchCard(match: match)
            }

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
            viewModel.commit(field: oldValue)
        }
        .savedToast(isPresented: $viewModel.showSavedToast, text: "Сохранено")
        .sheet(isPresented: $viewModel.showsColorPicker) {
            NavigationStack {
                ConverterColorPicker(color: Binding(
                    get: { viewModel.currentColor },
                    set: { viewModel.applyPickedColor($0) }
                ))
                .navigationTitle("Выбрать цвет")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Готово") { viewModel.showsColorPicker = false }
                    }
                }
            }
        }
    }

    // MARK: Fields

    private var hexField: some View {
        BorderedField(label: "Hex", text: $viewModel.hexText, focus: $focusedField, field: .hex)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .onChange(of: viewModel.hexText) { _, newValue in
                viewModel.hexText = newValue.uppercased()
            }
    }

    private var rgbRow: some View {
        HStack(spacing: 12) {
            BorderedField(label: "R", text: $viewModel.rText, focus: $focusedField, field: .r)
                .keyboardType(.numberPad)
            BorderedField(label: "G", text: $viewModel.gText, focus: $focusedField, field: .g)
                .keyboardType(.numberPad)
            BorderedField(label: "B", text: $viewModel.bText, focus: $focusedField, field: .b)
                .keyboardType(.numberPad)
        }
    }

    private var cmykRow: some View {
        HStack(spacing: 12) {
            BorderedField(label: "C", text: $viewModel.cText, focus: $focusedField, field: .c)
                .keyboardType(.numberPad)
            BorderedField(label: "M", text: $viewModel.mText, focus: $focusedField, field: .m)
                .keyboardType(.numberPad)
            BorderedField(label: "Y", text: $viewModel.yText, focus: $focusedField, field: .y)
                .keyboardType(.numberPad)
            BorderedField(label: "K", text: $viewModel.kText, focus: $focusedField, field: .k)
                .keyboardType(.numberPad)
        }
    }

    private var colorPickerRow: some View {
        HStack(spacing: 12) {
            Text("Выбрать цвет:")
            Button {
                viewModel.commit(field: focusedField)
                focusedField = nil
                viewModel.showsColorPicker = true
            } label: {
                Circle()
                    .fill(Color(hex: viewModel.currentColor.hexString))
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
            .accessibilityValue(viewModel.currentColor.hexString)
            Spacer(minLength: 0)
        }
    }

    private var saveButton: some View {
        Button(action: { viewModel.save(onSaved: { dismiss() }) }) {
            Text("Сохранить")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(viewModel.hasEnteredColor ? Color.tealAccent : Color(.systemGray4))
                )
        }
        .buttonStyle(SoftPressButtonStyle())
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.hasEnteredColor)
        .disabled(!viewModel.hasEnteredColor)
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
