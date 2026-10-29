import SwiftUI
import UIKit

struct NavigationPopGestureControl: UIViewControllerRepresentable {
    let isEnabled: Bool

    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {
        uiViewController.isEnabled = isEnabled
        uiViewController.apply()
    }

    final class Controller: UIViewController {
        var isEnabled = true

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            apply()
        }

        func apply() {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = isEnabled
        }
    }
}
