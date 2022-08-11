import CoreGraphics

final class AppConfigure {
    
    let sizeOfWindow: CGSize
    let photoService: PhotoServiceProtocol
    let saliencyService: SaliencyServiceProtocol
    
    init(sizeOfWindow: CGSize, photoService: PhotoServiceProtocol, saliencyService: SaliencyServiceProtocol) {
        self.sizeOfWindow = sizeOfWindow
        self.photoService = photoService
        self.saliencyService = saliencyService
    }
}
