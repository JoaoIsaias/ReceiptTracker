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
        app.launchArguments = ["-UITestCameraScreen", "-CameraPermissionGranted"]
        app.launch()
        
        let capture = app.buttons["CameraScreenCaptureButton"]
        XCTAssertTrue(capture.waitForExistence(timeout: 2))
    }

    func testThumbnailNavigatesToGallery() {
        app.launchArguments = ["-UITestCameraScreen", "-CameraPermissionGranted"]
        app.launch()
        
        let thumbnail = app.images["ThumbnailImage"]
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 2))
        
        thumbnail.tap()
        
        let gallery = app.scrollViews["GalleryScreenView"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 2))
    }
    
    func testCapturePhotoNavigatesToDetails() {
        app.launchArguments = ["-UITestCameraScreen", "-CameraPermissionGranted"]
        app.launch()
        
        let capture = app.buttons["CameraScreenCaptureButton"]
        XCTAssertTrue(capture.waitForExistence(timeout: 2))
        
        capture.tap()
        
        let details = app.scrollViews["DetailsScreenView"]
        XCTAssertTrue(details.waitForExistence(timeout: 2))
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
    
    //MARK: - DetailsScreenViewModel
    
    func testFullScreen() {
        app.launchArguments = ["-UITestDetailsScreen"]
        app.launch()
        
        let image = app.images["DetailsScreenImage"]
        XCTAssertTrue(image.waitForExistence(timeout: 2))
        
        image.tap()
        
        let fullScreenImage = app.images["FullScreenImage"]
        XCTAssertTrue(fullScreenImage.waitForExistence(timeout: 2))
        
        let fullScreenImageCloseButton = app.buttons["FullScreenImageCloseButton"]
        XCTAssertTrue(fullScreenImageCloseButton.waitForExistence(timeout: 2))
        
        fullScreenImageCloseButton.tap()
        
        XCTAssertFalse(fullScreenImage.exists)
        XCTAssertFalse(fullScreenImageCloseButton.exists)
    }
    
    func testEditAmountAndSaveButtonBecomesEnabled() {
        app.launchArguments = ["-UITestDetailsScreen", "-AmountIsZero"]
        app.launch()

        let amountField = app.textFields["AmountTextField"]
        XCTAssertTrue(amountField.exists)
        
        let saveButton = app.buttons["SaveButton"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertFalse(saveButton.isEnabled)
        
        amountField.tap()
        amountField.clearAndEnterText(text: "20.00")

        XCTAssertTrue(saveButton.isEnabled)
    }
}

extension XCUIElement {
    func clearAndEnterText(text: String) {
        guard let currentValue = self.value as? String else { return }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
