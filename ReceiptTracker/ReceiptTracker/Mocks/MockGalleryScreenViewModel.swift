import Foundation
import CoreData

@MainActor
class MockGalleryScreenViewModel: GalleryScreenViewModel {
    override init() {
        super.init()
        
        if let testImagePath = Bundle.main.path(forResource: "testImage", ofType: "jpg") {
            self.photoPaths = [testImagePath]
        }
    }
    
    override func fetchAllPhotoPaths(context: NSManagedObjectContext) async { }
    
    override func deletePhoto(at path: String, context: NSManagedObjectContext) {
        if let index = photoPaths.firstIndex(of: path) {
            photoPaths.remove(at: index)
        }
    }
}
