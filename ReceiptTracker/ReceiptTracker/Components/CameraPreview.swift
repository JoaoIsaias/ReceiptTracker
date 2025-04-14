import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @Binding var isSessionRunning: Bool //Adding a binding makes swiftui update the view correctly with the screen using it
    let session: AVCaptureSession?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let session = session {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
            
            context.coordinator.previewLayer = previewLayer
        }
        
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}
