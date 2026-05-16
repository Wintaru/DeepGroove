import SwiftUI
import AVFoundation

struct BarcodeView: UIViewControllerRepresentable {
    let onBarcode: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: BarcodeScannerDelegate {
        let parent: BarcodeView
        init(_ parent: BarcodeView) { self.parent = parent }
        func didScan(barcode: String) { parent.onBarcode(barcode) }
        func didCancel() { parent.onCancel() }
    }
}

// MARK: - Scanner View Controller

protocol BarcodeScannerDelegate: AnyObject {
    func didScan(barcode: String)
    func didCancel()
}

final class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: BarcodeScannerDelegate?

    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupSession()
        addCancelButton()
        addOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in self?.session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupSession() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input)
        else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        DispatchQueue.global(qos: .background).async { [weak self] in self?.session.startRunning() }
    }

    private func addCancelButton() {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func addOverlay() {
        let overlay = UIView()
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.layer.borderColor = UIColor.systemYellow.cgColor
        overlay.layer.borderWidth = 2
        overlay.layer.cornerRadius = 8
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            overlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            overlay.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.75),
            overlay.heightAnchor.constraint(equalToConstant: 120)
        ])

        let label = UILabel()
        label.text = "Align barcode within frame"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: overlay.bottomAnchor, constant: 16)
        ])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = objects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue
        else { return }
        hasScanned = true
        session.stopRunning()
        delegate?.didScan(barcode: value)
    }

    @objc private func cancelTapped() {
        session.stopRunning()
        delegate?.didCancel()
    }
}
