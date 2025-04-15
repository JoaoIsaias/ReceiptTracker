import Foundation
import CoreData

@MainActor
class MockDetailsScreenViewModel: DetailsScreenViewModel {
    init(mockReceipt: ReceiptInfo? = nil) {
        super.init()
        self.existingReceipt = mockReceipt
    }

    override func fetchReceipt(context: NSManagedObjectContext, imagePath: String) async -> ReceiptInfo? {
        let mockReceiptInfo = ReceiptInfo(context: context)
        mockReceiptInfo.id = UUID()
        mockReceiptInfo.imagePath = Bundle.main.path(forResource: "testImage", ofType: "jpg")
        mockReceiptInfo.createdAt = Date()
        mockReceiptInfo.date = Date()
        
        if CommandLine.arguments.contains("-AmountIsZero") {
            mockReceiptInfo.amount = 0
        } else {
            mockReceiptInfo.amount = 10.0
        }
        
        mockReceiptInfo.currency = "Euro (€)"
        mockReceiptInfo.vendor = "Vendor A"
        mockReceiptInfo.notes = "Notes"

        self.existingReceipt = mockReceiptInfo
        return mockReceiptInfo
    }
    
    override func saveOnCoreData(context: NSManagedObjectContext, imagePath: String, date: Date, amount: Double, currency: String, vendor: String?, notes: String?) async throws { }
    
    override func deleteImageFromDisk(imagePath: String) { }
}
