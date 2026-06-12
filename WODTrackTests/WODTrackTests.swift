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

        viewModel.recognizeWODContent(from: UIImage())

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

        XCTAssertEqual(viewModel.step, .ocrResult)
    }

    func testLegalDocumentURLs() {
        XCTAssertEqual(LegalDocument.userAgreement.url.absoluteString, "https://docs.qq.com/doc/DUk5pRVREYWVqeUNn")
        XCTAssertEqual(LegalDocument.privacyPolicy.url.absoluteString, "https://docs.qq.com/doc/DUklUeGFVdGFQVm9a")
        XCTAssertEqual(LegalDocument.supportFAQ.url.absoluteString, "https://docs.qq.com/doc/DUkVISGZTcW1sT3Bz")
        XCTAssertEqual(LegalDocument.accountDeletion.url.absoluteString, "https://docs.qq.com/doc/DUmhtT0RIUHZDU1hC")
        XCTAssertEqual(LegalDocument.feedback.url.absoluteString, "https://docs.qq.com/form/page/DUmh6S25LcFNZZXBS")
    }

    func testLegalTermsAcceptancePersists() {
        let key = "wt.legalTermsAccepted"
        let defaults = UserDefaults.standard
        let previous = defaults.object(forKey: key)
        defer {
            if let previous {
                defaults.set(previous, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.removeObject(forKey: key)
        let appState = AppState()

        XCTAssertFalse(appState.hasAcceptedLegalTerms)

        appState.acceptLegalTerms()

        XCTAssertTrue(appState.hasAcceptedLegalTerms)
        XCTAssertTrue(defaults.bool(forKey: key))
    }
}

private struct ImmediateOCRService: OCRServicing {
    func recognize(image: UIImage) async throws -> OCRResult {
        OCRResult(wodContent: ["21-15-9"], confidence: 1)
    }
}
