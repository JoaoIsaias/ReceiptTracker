import XCTest
import CoreData
import Combine
@testable import ReceiptTracker

final class ReceiptTrackerTests: XCTestCase {
    var viewContext: NSManagedObjectContext!
    var mockCameraManager: MockCameraManager!
    
    var cameraScreenViewModel: CameraScreenViewModel!
    var cancellables: Set<AnyCancellable> = []
    
    var detailsScreenViewModel: DetailsScreenViewModel!
    
    var galleryScreenViewModel: GalleryScreenViewModel!

    func makeMockReceipt(context: NSManagedObjectContext) -> ReceiptInfo {
        let receiptInfo = ReceiptInfo(context: context)
        receiptInfo.id = UUID()
        receiptInfo.imagePath = "/path/image123.jpg"
        receiptInfo.createdAt = Date()
        receiptInfo.date = Date()
        receiptInfo.amount = 10.0
        receiptInfo.currency = "EUR"
        receiptInfo.vendor = "Vendor A"
        receiptInfo.notes = "Notes"
        return receiptInfo
    }
    
    //MARK: - Setup
    override func setUpWithError() throws {
        try super.setUpWithError()

        mockCameraManager = MockCameraManager()
        
        let container = NSPersistentContainer(name: "ReceiptTracker")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }

        viewContext = container.viewContext
    }

    override func tearDownWithError() throws {
        viewContext = nil
        mockCameraManager = nil
        cancellables.removeAll()
        
        cameraScreenViewModel = nil
        detailsScreenViewModel = nil
        galleryScreenViewModel = nil
        
        try super.tearDownWithError()
    }
    
    //MARK: - CameraScreenViewModel
    
    //MainActors cant be setup in normal setUp, so their setUp function must be called each time they have to be used
    @MainActor
    func setupCameraScreenViewModel() {
        cameraScreenViewModel = CameraScreenViewModel(cameraManager: mockCameraManager)
    }
    
    func testCameraPermissionGranted() async {
        await setupCameraScreenViewModel()
        mockCameraManager.permissionGranted = true
        
        await cameraScreenViewModel.requestCameraPermission()
        
        let isCameraPermissionGranted = await MainActor.run { cameraScreenViewModel.isCameraPermissionGranted }

        XCTAssertEqual(isCameraPermissionGranted, true)
        XCTAssertTrue(mockCameraManager.didRequestPermission)
    }

    func testStartAndStopSession() async {
        await setupCameraScreenViewModel()
        await cameraScreenViewModel.startCameraSession()
        XCTAssertTrue(mockCameraManager.didStartSession)

        await cameraScreenViewModel.stopCameraSession()
        XCTAssertTrue(mockCameraManager.didStopSession)
    }

    func testCapturePhotoSuccess() async {
        await setupCameraScreenViewModel()
        mockCameraManager.mockCapturedPhotoPath = "/path/image123.jpg"
        
        let result = await cameraScreenViewModel.capturePhoto()
        
        XCTAssertEqual(result, "/path/image123.jpg")
        XCTAssertTrue(mockCameraManager.didCapturePhoto)
    }

    func testCapturePhotoFailure() async {
        await setupCameraScreenViewModel()
        mockCameraManager.shouldThrowOnCapture = true
        
        let result = await cameraScreenViewModel.capturePhoto()
        
        XCTAssertNil(result)
    }
    
    func testFetchUpdatesLastPhotoPath() async {
        await setupCameraScreenViewModel()
        
        _ = makeMockReceipt(context: viewContext)

        try? viewContext.save()

        await cameraScreenViewModel.fetchLatestPhotoPath(context: viewContext)

        let expectedPath = URL.documentsDirectory.appendingPathComponent("image123.jpg").path
        let lastPhotoPath = await MainActor.run { cameraScreenViewModel.lastPhotoPath }

        XCTAssertEqual(lastPhotoPath, expectedPath)
    }
    
    // MARK: - DetailsScreenViewModel

    @MainActor
    func setupDetailsScreenViewModel() async {
        detailsScreenViewModel = DetailsScreenViewModel()
    }

    func testFetchFindsMatchingReceipt() async throws {
        await setupDetailsScreenViewModel()
        
        _ = makeMockReceipt(context: viewContext)

        try viewContext.save()

        let receipt = await detailsScreenViewModel.fetchReceipt(context: viewContext, imagePath: "/path/image123.jpg")
        
        XCTAssertNotNil(receipt)
        XCTAssertEqual(receipt?.imagePath, "/path/image123.jpg")
        
        let existingReceipt = await MainActor.run { detailsScreenViewModel.existingReceipt }
        XCTAssertEqual(existingReceipt?.imagePath, "/path/image123.jpg")
    }

    func testFetchReturnsNilWhenNotFound() async {
        await setupDetailsScreenViewModel()
        
        let receipt = await detailsScreenViewModel.fetchReceipt(context: viewContext, imagePath: "/wrongPath/image123.jpg")
        
        XCTAssertNil(receipt)
        let existingReceipt = await MainActor.run { detailsScreenViewModel.existingReceipt }
        XCTAssertNil(existingReceipt)
    }

    func testSaveOnCoreDataNewReceipt() async throws {
        await setupDetailsScreenViewModel()
        
        try await detailsScreenViewModel.saveOnCoreData(
            context: viewContext,
            imagePath: "/path/image123.jpg",
            date: Date(),
            amount: 10.0,
            currency: "EUR",
            vendor: "Vendor A",
            notes: "Notes"
        )

        let fetchRequest: NSFetchRequest<ReceiptInfo> = ReceiptInfo.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "imagePath == %@", "/path/image123.jpg")

        let results = try viewContext.fetch(fetchRequest)

        XCTAssertEqual(results.count, 1)
        let receipt = results.first!
        
        XCTAssertEqual(receipt.amount, 10.0)
        XCTAssertEqual(receipt.currency, "EUR")
        XCTAssertEqual(receipt.vendor, "Vendor A")
        XCTAssertEqual(receipt.notes, "Notes")
    }

    func testSaveOnCoreDataExistingReceipt() async throws {
        await setupDetailsScreenViewModel()
        
        let receiptInfo = makeMockReceipt(context: viewContext)
        
        try viewContext.save()

        await MainActor.run { detailsScreenViewModel.existingReceipt = receiptInfo }

        try await detailsScreenViewModel.saveOnCoreData(
            context: viewContext,
            imagePath: "/path/image123.jpg",
            date: Date(),
            amount: 20.0,
            currency: "USD",
            vendor: "Vendor B",
            notes: "New Notes"
        )

        let receipt = try viewContext.fetch(ReceiptInfo.fetchRequest()).first!
        XCTAssertEqual(receipt.amount, 20.0)
        XCTAssertEqual(receipt.currency, "USD")
        XCTAssertEqual(receipt.vendor, "Vendor B")
        XCTAssertEqual(receipt.notes, "New Notes")
    }

    func testDeleteImageFromDisk() async throws {
        await setupDetailsScreenViewModel()

        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("image123.jpg")
        try "test".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        await detailsScreenViewModel.deleteImageFromDisk(imagePath: url.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
    
    // MARK: - GalleryScreenViewModel
    
    @MainActor
    func setupGalleryScreenViewModel() async {
        galleryScreenViewModel = GalleryScreenViewModel()
    }
    
    func testFetchAllPhotoPaths() async throws {
        await setupGalleryScreenViewModel()

        _ = makeMockReceipt(context: viewContext)

        try viewContext.save()

        await galleryScreenViewModel.fetchAllPhotoPaths(context: viewContext)

        let path = URL.documentsDirectory.appendingPathComponent("image123.jpg").path
        let photoPaths = await MainActor.run { galleryScreenViewModel.photoPaths }

        XCTAssertEqual(photoPaths, [path])
    }
    
    func testDeletePhoto() async throws {
        await setupGalleryScreenViewModel()

        let photoName = "image123.jpg"
        let photoPath = URL.documentsDirectory.appendingPathComponent(photoName).path

        FileManager.default.createFile(atPath: photoPath, contents: Data())

        _ = makeMockReceipt(context: viewContext)
        try viewContext.save()

        await MainActor.run { galleryScreenViewModel.photoPaths = [photoPath] }
        
        await galleryScreenViewModel.deletePhoto(at: photoPath, context: viewContext)

        XCTAssertFalse(FileManager.default.fileExists(atPath: photoPath))
        
        let photoPaths = await MainActor.run { galleryScreenViewModel.photoPaths }
        XCTAssertTrue(photoPaths.isEmpty)

        let results = try viewContext.fetch(ReceiptInfo.fetchRequest())
        XCTAssertTrue(results.isEmpty)
    }


}
