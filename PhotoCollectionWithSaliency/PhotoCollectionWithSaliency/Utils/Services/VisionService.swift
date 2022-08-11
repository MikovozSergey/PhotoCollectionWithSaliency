import UIKit
import Vision


enum SaliencyServiceError: Error {
    case cantRetrieveImage
    case noSaliencyResults
}

enum TypeOfSaliency {
    case attention
}

protocol SaliencyServiceProtocol {
    func getSaliencyRectangles(image: UIImage, type: TypeOfSaliency, with completion: @escaping (Result<[CGRect], Error>) -> Void
    )
}

final class VisionService: SaliencyServiceProtocol {
    
    func getSaliencyRectangles(image: UIImage, type: TypeOfSaliency, with completion: @escaping (Result<[CGRect], Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(SaliencyServiceError.cantRetrieveImage))
            return
        }
        let request: VNRequest
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)
        
        switch type {
        case .attention:
            request = VNGenerateAttentionBasedSaliencyImageRequest()
        }
        
#if targetEnvironment(simulator)
        request.usesCPUOnly = true
#endif
        
        try? requestHandler.perform([request])
        guard let result = request.results?.first as? VNSaliencyImageObservation, let salientObjects = result.salientObjects else {
            completion(.failure(SaliencyServiceError.noSaliencyResults))
            return
        }
        
        let sizeOfImage = CGSize(width: image.size.width, height: image.size.height)
        var saliencyFrames: [CGRect] = []
        
        salientObjects.forEach { object in
            let boundingBox = object.boundingBox
            let origin = CGPoint(x: boundingBox.origin.x * sizeOfImage.width, y: boundingBox.origin.y * sizeOfImage.height)
            let size = CGSize(width: boundingBox.width * sizeOfImage.width, height: boundingBox.height * sizeOfImage.height)
            saliencyFrames.append(CGRect(origin: origin, size: size))
        }
        completion(.success(saliencyFrames))
    }
}
