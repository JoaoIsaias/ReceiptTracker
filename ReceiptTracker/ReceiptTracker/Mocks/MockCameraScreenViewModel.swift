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
        
        if let testImagePath = Bundle.main.path(forResource: "testImage", ofType: "jpg") {
            self.lastPhotoPath = testImagePath
        }
    }
    
    override func stopCameraSession() { }

    override func capturePhoto() async -> String? {
        return Bundle.main.path(forResource: "testImage", ofType: "jpg")
    }

    override func fetchLatestPhotoPath(context: NSManagedObjectContext) async {
        self.lastPhotoPath = Bundle.main.path(forResource: "testImage", ofType: "jpg")
    }
}
