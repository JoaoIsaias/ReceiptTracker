import XCTest

final class ReceiptTrackerUITests: XCTestCase {

    let app = XCUIApplication()
        
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchArguments = ["-UITest"]
    }

    override func tearDownWithError() throws { }

    func testPermissionTextAppears() {
        app.launch()
        
        let text = app.staticTexts["CameraScreenPermissionText"]
        XCTAssertTrue(text.waitForExistence(timeout: 2))
    }

    func testSettingsButtonExists() {
        app.launch()
        
        let button = app.buttons["CameraScreenSettingsButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 2))
    }

    func testCaptureButtonVisible() {
        app.launchArguments.append("-CameraPermissionGranted")
        app.launch()
        
        let capture = app.buttons["CameraScreenCaptureButton"]
        XCTAssertTrue(capture.waitForExistence(timeout: 5))
    }

//    func testThumbnailNavigatesToGallery() {
//        app.launchArguments.append("-CameraPermissionGranted")
//        app.launch()
//        
//        let thumbnail = app.otherElements["ThumbnailImage"]
//        XCTAssertTrue(thumbnail.waitForExistence(timeout: 5))
//        
//        thumbnail.tap()
//        
//        let gallery = app.staticTexts["GalleryScreenView"]
//        XCTAssertTrue(gallery.waitForExistence(timeout: 2))
//    }
}
