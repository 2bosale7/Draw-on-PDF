//
//  PDFDocumentOverlay.swift
//  Draw on a Pdf using OverlayView with PencilKit
//
//  Created by Mohammed Saleh on 15/04/2025.
//

import Foundation
import PDFKit

class PDFDocumentOverlay: NSObject, PDFPageOverlayViewProvider {
    var pageToViewMapping = [PDFDocumentPage: PDFKitDrawingView]()
    
    func pdfView(_ view: PDFView, overlayViewFor page: PDFPage) -> UIView? {
        var resultView: PDFKitDrawingView? = nil
        guard let page = page as? PDFDocumentPage else { return nil }
        
        if let overlayView = self.pageToViewMapping[page] {
            overlayView.page = page
            resultView = overlayView
        } else {
            let canvasView = PDFKitDrawingView(frame: .zero)
            canvasView.backgroundColor = UIColor.clear
            canvasView.page = page
            self.pageToViewMapping[page] = canvasView
            resultView = canvasView
        }
        
        if let container = page.resizableContainerView {
            resultView?.canvasView.drawing = container.canvasView.drawing
            resultView?.page = page
            page.resizableContainerView = resultView
        }
        return resultView
    }
    
    func pdfView(_ pdfView: PDFView, willDisplayOverlayView overlayView: UIView, for page: PDFPage) { }
    
    func pdfView(_ pdfView: PDFView, willEndDisplayingOverlayView overlayView: UIView, for page: PDFPage) {
        let overlayView = overlayView as! PDFKitDrawingView
        let page = page as! PDFDocumentPage
        page.resizableContainerView?.canvasView.drawing = overlayView.canvasView.drawing
        pageToViewMapping.removeValue(forKey: page)
    }
    
}
