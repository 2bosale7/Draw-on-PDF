//
//  PDFDocumentView.swift
//  Draw on a Pdf using OverlayView with PencilKit
//
//  Created by Mohammed Saleh on 15/04/2025.
//

import Foundation
import PDFKit

class PDFDocumentView: PDFView {
    
    //MARK: - Variables
    private(set) var currentPageIndex: Int = 0
    private var pdfDocument: PDFKitDocument?
    private var overlay = PDFDocumentOverlay()
    
    //MARK: - . Init
    required init? (coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init (frame: CGRect) {
        super.init (frame: frame)
        self.configure()
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    func loadPDF(url: URL?) {
        guard let url = url else { return }
        self.pdfDocument = .init(fileURL: url, pdf: self)
        self.pdfDocument?.open { [weak self] success in
            guard let self = self else { return }
            self.configureDocumentLoading(success: success)
        }
    }
    
    func drawing(isEnable: Bool) {
        self.startDrawing (isEnable: isEnable)
        self.isScrollEnabled = !isEnable
    }
    
    func saveTo(url: URL, fileName: String) {
        guard let document = self.pdfDocument else { return }
        let file = url.appendingPathComponent(fileName)
        
        document.close {
            switch $0 {
            case true:
                document.save(to: file, for: .forOverwriting) { _ in print(" 2.4 - Saved at \(file)") }
            case false:
                print ("Sorry, error !")
            }
        }
    }
}

//MARK: - Helper private extension
private extension PDFDocumentView {
    private var privateScrollView: UIScrollView? {
        return subviews.first as? UIScrollView
    }
    
    var isScrollEnabled: Bool? {
        set {
            if let newValue {
                privateScrollView?.isScrollEnabled = newValue
            }
        }
        get {
            privateScrollView?.isScrollEnabled
        }
    }
    
    func configure() {
        autoScales = true
        displayMode = .singlePageContinuous
        pageShadowsEnabled = false
        displaysPageBreaks = true
        isInMarkupMode = true
        displayBox = .mediaBox
        interpolationQuality = .high
        usePageViewController (false)
    }
    
    func configureDocumentLoading (success: Bool) {
        guard success == true else { return }
        self.pdfDocument?.pdfDocument?.delegate = self
        self.pageOverlayViewProvider = self.overlay
        self.document = self.pdfDocument?.pdfDocument
        self.minScaleFactor = self.scaleFactorForSizeToFit
        self.maxScaleFactor = 4.0
        self.scaleFactor = self.scaleFactorForSizeToFit
        self.autoScales = true
    }
    
    func scrollView() -> UIScrollView? {
        guard let pdfScrollView = self.subviews.first?.subviews.first as? UIScrollView else { return nil }
        pdfScrollView.showsHorizontalScrollIndicator = false
        pdfScrollView.showsVerticalScrollIndicator = false
        return pdfScrollView
    }
}


//MARK: - Signature & Drawing

private extension PDFDocumentView {
    func startDrawing (isEnable: Bool) {
        guard let pdfPage = currentPage as? PDFDocumentPage else { return }
        if pdfPage.resizableContainerView == nil {
            pdfPage.resizableContainerView = overlay.pageToViewMapping[pdfPage]
        }
        guard let resView = pdfPage.resizableContainerView else { return }
        resView.enable(mode: isEnable ? .drawing : .defualt)
        
        PDFKitToolPicker.shared.toolPicker.setVisible(isEnable, forFirstResponder: resView.canvasView)
        switch isEnable {
        case true:
            PDFKitToolPicker.shared.toolPicker.addObserver(resView.canvasView)
            resView.canvasView.becomeFirstResponder()
        case false:
            PDFKitToolPicker.shared.toolPicker.removeObserver(resView.canvasView)
            resView.canvasView.resignFirstResponder()
        }
    }
}


//MARK: - PDFDocumentDelegate extension

extension PDFDocumentView: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return PDFDocumentPage.self
    }
}

//MARK: - UIScrollViewDelegate extension

extension PDFDocumentView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let page = self.currentPage, let index = self.document?.index(for: page) else { return }
        currentPageIndex = index
    }
}
