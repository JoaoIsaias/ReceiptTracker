import Foundation
import CoreData

class MockCameraScreenViewModel: CameraScreenViewModel {
    override init(cameraManager: CameraManagerProtocol = MockCameraManager()) {
        super.init(cameraManager: cameraManager)
       
        if CommandLine.arguments.contains("-CameraPermissionGranted") {
            self.isCameraPermissionGranted = true
        } else {
            self.isCameraPermissionGranted = false
        }
    }
    
    override func stopCameraSession() { }

    override func capturePhoto() async -> String? {
        return "/path/image123.jpg"
    }

    override func fetchLatestPhotoPath(context: NSManagedObjectContext) async {
        self.lastPhotoPath = "/path/image123.jpg"
    }
}
