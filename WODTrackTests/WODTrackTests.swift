import XCTest
import UIKit
@testable import WODTrack

final class WODTrackTests: XCTestCase {
    func testWODTypeScorePlaceholder() {
        XCTAssertEqual(WODType.forTime.scorePlaceholder, "MM:SS，例如 04:32")
        XCTAssertEqual(WODType.maxLoad.displayName, "Max Load")
    }

    func testDefaultRecordUsesFreeStyle() {
        let record = WODRecord()
        XCTAssertEqual(record.cardStyleId, "style_basic_dark")
    }

    func testRecordFlowStartsAtOCRStepAfterSelectingWhiteboard() {
        let viewModel = RecordFlowViewModel(ocrService: ImmediateOCRService())

        viewModel.startFlow(with: UIImage())

        XCTAssertEqual(viewModel.step, .ocrResult)
    }

    func testRecordFlowTransitionsDoNotLoopBackToOCRAfterCheckinPhotos() {
        let viewModel = RecordFlowViewModel(ocrService: ImmediateOCRService())

        viewModel.goToCheckinPhotos()
        viewModel.goToScoreInput()

        XCTAssertEqual(viewModel.step, .scoreInput)
    }

    func testRecordFlowGoesToCardEditorAfterScoreStep() {
        let viewModel = RecordFlowViewModel(ocrService: ImmediateOCRService())

        viewModel.goToScoreInput()
        viewModel.goToCardEditor()

        XCTAssertEqual(viewModel.step, .cardEditor)
    }

    func testRecordFlowCanGoBackFromPreviewToCheckinPhotos() {
        let viewModel = RecordFlowViewModel(ocrService: ImmediateOCRService())

        viewModel.goToCardPreview()
        viewModel.goBack()

        XCTAssertEqual(viewModel.step, .checkinPhotos)
    }

    func testRecordFlowCanGoBackFromCheckinPhotosToWODContent() {
        let viewModel = RecordFlowViewModel(ocrService: ImmediateOCRService())

        viewModel.goToCheckinPhotos()
        viewModel.goBack()

        XCTAssertEqual(viewModel.step, .ocrResult)
    }

    func testRecordFlowCanGoBackFromWODContentToEntryChoice() {
        let viewModel = RecordFlowViewModel(ocrService: ImmediateOCRService())

        viewModel.goToOCRReview()
        viewModel.goBack()

        XCTAssertEqual(viewModel.step, .whiteboard)
    }
}

private struct ImmediateOCRService: OCRServicing {
    func recognize(image: UIImage) async throws -> OCRResult {
        OCRResult(wodType: .forTime, wodContent: ["21-15-9"], confidence: 1)
    }
}
