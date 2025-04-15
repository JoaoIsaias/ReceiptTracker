import XCTest

final class ReceiptTrackerUITests: XCTestCase {

    let app = XCUIApplication()
        
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws { }

    //MARK: - CameraScreenView
    
    func testPermissionTextAppears() {
        app.launchArguments = ["-UITestCameraScreen"]
        app.launch()
        
        let text = app.staticTexts["CameraScreenPermissionText"]
        XCTAssertTrue(text.waitForExistence(timeout: 2))
    }

    func testSettingsButtonExists() {
        app.launchArguments = ["-UITestCameraScreen"]
        app.launch()
        
        let button = app.buttons["CameraScreenSettingsButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 2))
    }

    func testCaptureButtonVisible() {
        app.launchArguments = ["-UITestCameraScreen"]
        app.launchArguments.append("-CameraPermissionGranted")
        app.launch()
        
        let capture = app.buttons["CameraScreenCaptureButton"]
        XCTAssertTrue(capture.waitForExistence(timeout: 2))
    }

    func testThumbnailNavigatesToGallery() {
        app.launchArguments = ["-UITestCameraScreen"]
        app.launchArguments.append("-CameraPermissionGranted")
        app.launch()
        
        let thumbnail = app.images["ThumbnailImage"]
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 2))
        
        thumbnail.tap()
        
        let gallery = app.scrollViews["GalleryScreenView"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 2))
    }
    
    //MARK: - GalleryScreenViewModel
    
    func testGalleryHasThumbnails() {
        app.launchArguments = ["-UITestGalleryScreen"]
        app.launch()

        let gallery = app.scrollViews["GalleryScreenView"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 2))

        let thumbnail = app.images["ThumbnailImage"]
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 2))
    }
    
    func testDeleteThumbnail() {
        app.launchArguments = ["-UITestGalleryScreen"]
        app.launch()
        
        let firstThumbnail = app.images["ThumbnailImage"].firstMatch
        
        XCTAssertTrue(firstThumbnail.exists)
        
        firstThumbnail.press(forDuration: 1.5)  // Press and hold to open context menu
        let deleteButton = app.buttons["Delete"]
        
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        deleteButton.tap()
        
        XCTAssertFalse(firstThumbnail.exists)
    }
    //Needs DetailsScreenView testable to work
//    func testThumbnailNavigatesToDetails() {
//        app.launchArguments = ["-UITestGalleryScreen"]
//        app.launch()
//        
//        let firstThumbnail = app.images["ThumbnailImage"].firstMatch
//        
//        XCTAssertTrue(firstThumbnail.exists)
//        
//        firstThumbnail.tap()
//        
//        let details = app.scrollViews["DetailsScreenView"]
//        XCTAssertTrue(details.waitForExistence(timeout: 2))
//    }
}
