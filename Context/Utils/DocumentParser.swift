//
//  DocumentParser.swift
//  Context
//
//  Created by David Harwardt on 25.06.26.
//

import Foundation
import PDFKit
import Vision

class DocumentParser {
    
    func extractTextFromPDF(at fileURL: URL) -> String? {
        
        guard let pdfDocument = PDFDocument(url: fileURL) else { return nil }
        
        var extractedText = ""
        
        for pageIndex in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: pageIndex), let pageString = page.string {
                extractedText += pageString + "\n"
            }
        }
        
        return extractedText.isEmpty ? nil : extractedText
    }
    
    func extractTextFromImage(at imageURL: URL, completion: @escaping (String?) -> Void) {
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else {
                print("Vision OCR error: \(error!.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            completion(recognizedStrings.joined(separator: "\n"))
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(url: imageURL, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Failed to initiate Vision request: \(error)")
                completion(nil)
            }
        }
    }
}

