import SwiftUI
import UIKit

/// Enveloppe SwiftUI de `UIActivityViewController` pour partager des fichiers
/// (PDF, sauvegarde JSON, …) via la feuille de partage iOS.
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
