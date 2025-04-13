import Foundation
import AVFoundation
import Combine

enum CameraManagerError: Error {
    case savingImageFailed
    case unknown
}

public protocol CameraManagerProtocol {
    var isSessionRunningPublisher: AnyPublisher<Bool, Never> { get }
    
    func requestPermission() async -> Bool
    func configureSession()
    func startSession()
    func stopSession()
    func capturePhoto() async throws -> String?
}

public class CameraManager: NSObject, CameraManagerProtocol {
    
    static let shared = CameraManager()
    // MARK: - Variables
    public let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var currentInput: AVCaptureDeviceInput?
    
    private var continuation: CheckedContinuation<String?, Error>?
    
    private var isSessionRunningSubject = CurrentValueSubject<Bool, Never>(false)
        
    public var isSessionRunningPublisher: AnyPublisher<Bool, Never> {
        return isSessionRunningSubject.eraseToAnyPublisher()
    }
    
    private override init() {
        super.init()
        configureSession()
    }
    
    // MARK: - Permissions (Async)
    public func requestPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    continuation.resume(returning: granted)
                }
            }
        case .restricted, .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Configuration
    public func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        currentInput = input

        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }

        session.addOutput(output)
        session.commitConfiguration()
    }

    // MARK: - Start / Stop
    public func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunningSubject.send(true)
                }
            }
        }
    }

    public func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.session.isRunning {
                self.session.stopRunning()
                
                DispatchQueue.main.async {
                    self.isSessionRunningSubject.send(false)
                }
            }
        }
    }

    // MARK: - Capture
    public func capturePhoto() async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)

            // Store the continuation so we can resume it once the photo is processed
            self.continuation = continuation
        }
    }

    private func saveImageToDisk(_ data: Data) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = directory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let continuation = self.continuation else { return }
        
        if let error = error {
            continuation.resume(throwing: error)
        } else {
            guard
                let data = photo.fileDataRepresentation(),
                let imagePath = saveImageToDisk(data)
            else {
                continuation.resume(throwing: CameraManagerError.savingImageFailed)
                return
            }
            
            continuation.resume(returning: imagePath)
        }

        self.continuation = nil
    }
}
