import Foundation
import CoreData

@MainActor
class GalleryScreenViewModel: ObservableObject {
    @Published var photoPaths: [String] = []
    
    func fetchAllPhotoPaths(context: NSManagedObjectContext) async {
        await context.perform {
            let fetchRequest: NSFetchRequest<ReceiptInfo> = ReceiptInfo.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ReceiptInfo.createdAt, ascending: false)]
            
            do {
                let receipts = try context.fetch(fetchRequest)
                
                var receiptsPaths: [String] = []
                for receipt in receipts {
                    guard let oldPath = receipt.imagePath else { continue }
                    
                    let imageName = String(oldPath.split(separator: "/").last ?? "")
                    let newPath = URL.documentsDirectory.appendingPathComponent(imageName)
                    receiptsPaths.append(newPath.path)
                }
                
                DispatchQueue.main.async {
                    self.photoPaths = receiptsPaths
                }
            } catch {
                print("Error fetching latest photo: \(error)")
            }
        }
    }
    
    func deletePhoto(at path: String, context: NSManagedObjectContext) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            print("File removal failed: \(error)")
        }

        let imageName = String(path.split(separator: "/").last ?? "")
    
        let fetchRequest: NSFetchRequest<ReceiptInfo> = ReceiptInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imagePath CONTAINS %@", imageName)

        do {
            let matches = try context.fetch(fetchRequest)
            matches.forEach(context.delete)
            try context.save()
        } catch {
            context.rollback()
            print("CoreData delete error: \(error)")
        }

        if let index = photoPaths.firstIndex(of: path) {
            photoPaths.remove(at: index)
        }
    }
}
