import Foundation
import CoreData

class DetailsScreenViewModel: ObservableObject {
    func saveOnCoreData(context: NSManagedObjectContext, imagePath: String, date: Date, amount: Double, currency: String, vendor: String? = nil, notes: String? = nil) async throws {
        let newReceipt = ReceiptInfo(context: context)
        
        newReceipt.id = UUID()
        newReceipt.date = date
        newReceipt.amount = amount
        newReceipt.currency = currency
        newReceipt.vendor = vendor
        newReceipt.notes = notes
        
        newReceipt.createdAt = Date()
        newReceipt.imagePath = imagePath
        
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
