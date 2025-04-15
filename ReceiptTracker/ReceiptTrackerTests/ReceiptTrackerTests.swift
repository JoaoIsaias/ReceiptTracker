import XCTest
import CoreData
import Combine
@testable import ReceiptTracker

final class ReceiptTrackerTests: XCTestCase {
    var viewContext: NSManagedObjectContext!
    var mockCameraManager: MockCameraManager!
    
    var cameraScreenViewModel: CameraScreenViewModel!
    var cancellables: Set<AnyCancellable> = []

    //Added to setUpWithError()
//    override func setUp() {
//        super.setUp()
//        
//        mockCameraManager = MockCameraManager()
//    }

    override func tearDown() {
        mockCameraManager = nil
        
        cameraScreenViewModel = nil
        cancellables.removeAll()
        
        super.tearDown()
    }
    
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
        
        cameraScreenViewModel = nil
    }
    
    //MainActors cant be setUp in normal setUp, so their setUp function must be called each time they have to be used
    @MainActor
    func setupCameraScreenViewModel() {
        cameraScreenViewModel = CameraScreenViewModel(cameraManager: mockCameraManager)
    }
    
    //MARK: - CameraScreenViewModel
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
        mockCameraManager.mockCapturedPhotoPath = "/mock/path.jpg"
        
        let result = await cameraScreenViewModel.capturePhoto()
        
        XCTAssertEqual(result, "/mock/path.jpg")
        XCTAssertTrue(mockCameraManager.didCapturePhoto)
    }

    func testCapturePhotoFailure() async {
        await setupCameraScreenViewModel()
        mockCameraManager.shouldThrowOnCapture = true
        
        let result = await cameraScreenViewModel.capturePhoto()
        
        XCTAssertNil(result)
    }
    
    func testFetchLatestPhotoPath_updatesLastPhotoPath() async {
        await setupCameraScreenViewModel()
        
        let receiptInfo = ReceiptInfo(context: viewContext)
        receiptInfo.createdAt = Date()
        receiptInfo.imagePath = "/random/path/image123.jpg"

        try? viewContext.save()

        await cameraScreenViewModel.fetchLatestPhotoPath(context: viewContext)

        let expectedPath = URL.documentsDirectory.appendingPathComponent("image123.jpg").path
        let lastPhotoPath = await MainActor.run { cameraScreenViewModel.lastPhotoPath }

        XCTAssertEqual(lastPhotoPath, expectedPath)
    }
}
