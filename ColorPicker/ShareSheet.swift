import SwiftUI

/// Presents the system share sheet for a file generated on-demand (e.g. a PDF export).
/// `ShareLink` can't be used for this: its `item` must be available up front, but a PDF
/// export is only generated when the user asks for it.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
