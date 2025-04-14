import Foundation
import CoreData
import AVFoundation
import Combine

@MainActor
class CameraScreenViewModel: ObservableObject {
    @Published var isCameraPermissionGranted: Bool? = nil
    @Published var isCameraSessionRunning = false
    
    @Published var lastPhotoPath: String? = nil
    
    private let cameraManager: CameraManagerProtocol

    init(cameraManager: CameraManagerProtocol = CameraManager.shared) {
        self.cameraManager = cameraManager
        
        cameraManager.isSessionRunningPublisher
            .receive(on: DispatchQueue.main) // Make sure to update UI on the main thread
            .assign(to: &$isCameraSessionRunning)
    }
    
    //MARK: - Camera
    func getCameraSession() -> AVCaptureSession? {
        if let cameraManager = cameraManager as? CameraManager {
            return cameraManager.session
        } else {
            return nil
        }
    }

    func requestCameraPermission() async {
        isCameraPermissionGranted = await cameraManager.requestPermission()
    }

    func startCameraSession() {
        cameraManager.startSession()
    }

    func stopCameraSession() {
        cameraManager.stopSession()
    }

    func capturePhoto() async -> String? {
        do {
            return try await cameraManager.capturePhoto()
        } catch {
            print("Error capturing photo: \(error)")
            return nil
        }
    }
    
    //MARK: - CoreData
    func fetchLatestPhotoPath(context: NSManagedObjectContext) async {
        await context.perform {
            let fetchRequest: NSFetchRequest<ReceiptInfo> = ReceiptInfo.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReceiptInfo.createdAt, ascending: false)]
            fetchRequest.fetchLimit = 1
            
            do {
                let receipts = try context.fetch(fetchRequest)
                if let latestReceipt = receipts.first, let oldPath = latestReceipt.imagePath {
                    let imageName = String(oldPath.split(separator: "/").last ?? "")
                    let newPath = URL.documentsDirectory.appendingPathComponent(imageName)
                    
                    DispatchQueue.main.async {
                        self.lastPhotoPath = newPath.path
                    }
                    
                }
            } catch {
                print("Error fetching latest photo: \(error)")
            }
        }
    }
}

