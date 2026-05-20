import UIKit
import SwiftUI
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private var vm: ShareViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        extractURL { [weak self] url in
            guard let self else { return }
            let viewModel = ShareViewModel(url: url, extensionContext: self.extensionContext)
            self.vm = viewModel
            let hostingController = UIHostingController(rootView: ShareView(vm: viewModel))
            hostingController.view.backgroundColor = UIColor.systemBackground
            self.addChild(hostingController)
            self.view.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            hostingController.didMove(toParent: self)
        }
    }

    private func extractURL(completion: @escaping (URL?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty else {
            completion(nil)
            return
        }
        tryLoadURL(from: attachments, index: 0, completion: completion)
    }

    private func tryLoadURL(from attachments: [NSItemProvider], index: Int,
                            completion: @escaping (URL?) -> Void) {
        guard index < attachments.count else {
            completion(nil)
            return
        }
        let attachment = attachments[index]

        if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    DispatchQueue.main.async { completion(url) }
                } else {
                    self.tryLoadURL(from: attachments, index: index + 1, completion: completion)
                }
            }
        } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                let url = (item as? String).flatMap { URL(string: $0) }
                DispatchQueue.main.async { completion(url) }
            }
        } else {
            tryLoadURL(from: attachments, index: index + 1, completion: completion)
        }
    }
}
