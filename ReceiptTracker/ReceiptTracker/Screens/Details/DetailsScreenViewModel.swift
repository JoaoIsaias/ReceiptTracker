import Foundation
import CoreData

@MainActor
class DetailsScreenViewModel: ObservableObject {
    @Published var existingReceipt: ReceiptInfo?
    
    func fetchReceipt(context: NSManagedObjectContext, imagePath: String) async -> ReceiptInfo? {
        let imageName = String(imagePath.split(separator: "/").last ?? "")
        
        let fetchRequest: NSFetchRequest<ReceiptInfo> = ReceiptInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imagePath CONTAINS %@", imageName)
        fetchRequest.fetchLimit = 1

        do {
            let receipt = try context.fetch(fetchRequest).first
            
            DispatchQueue.main.async {
                self.existingReceipt = receipt
            }
            
            return receipt
        } catch {
            print("CoreData fetch error: \(error)")
            return nil
        }
    }
    
    func saveOnCoreData(context: NSManagedObjectContext, imagePath: String, date: Date, amount: Double, currency: String, vendor: String? = nil, notes: String? = nil) async throws {
        let receipt: ReceiptInfo
        
        if let existingReceipt = existingReceipt {
            receipt = existingReceipt
        } else {
            receipt = ReceiptInfo(context: context)
            receipt.id = UUID()
            receipt.imagePath = imagePath
            receipt.createdAt = Date()
        }
        
        receipt.date = date
        receipt.amount = amount
        receipt.currency = currency
        receipt.vendor = vendor
        receipt.notes = notes

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
    
    func deleteImageFromDisk(imagePath: String) {
        let fileURL = URL(fileURLWithPath: imagePath)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Image deleted successfully.")
        } catch {
            print("Error deleting image: \(error)")
        }
    }
}
