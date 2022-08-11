import UIKit
import Photos
import AVFoundation

final class PhotoDetailsViewController: UIViewController {
    
    // MARK: - Constants
    
    private struct Constants {
        static let initFatalError: String = "PhotoDetailsVC don't installed"
        static let lowFetchFatalError: String = "Failed to fetch low image "
        static let highFetchFatalError: String = "Failed to fetch high image "
        static let getSaliencyFramesFatalError: String = "Failed to get saliency frames "
        static let progressViewCenterYConstraint: CGFloat = -20.0
        static let progressViewWidth: CGFloat = 200.0
        static let rectangleLineWidth: CGFloat = 0.01
        static let progressZeroValue: Float = 0.0
        static let animateTimeInterval: TimeInterval = 1.0
    }
    
    // MARK: - Properties
    
    private let photoAsset: PHAsset
    private var photoService: PhotoServiceProtocol?
    private var saliencyService: SaliencyServiceProtocol?
    private lazy var imageView = UIImageView {
        $0.contentMode = .scaleAspectFit
    }
    private lazy var progressView = UIProgressView {
        $0.isHidden = true
    }
    
    // MARK: - Initialization
    
    init(photoAsset: PHAsset, photoService: PhotoServiceProtocol, saliencyService: SaliencyServiceProtocol) {
        self.photoAsset = photoAsset
        self.photoService = photoService
        self.saliencyService = saliencyService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError(Constants.initFatalError)
    }
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        addSubviews()
        fetchImage(for: photoAsset)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: PhotoConstants.nameOfMagnifyingGlassSymbol), style: .plain, target: self, action: #selector(tappedZoom))
        view.backgroundColor = .white
    }
    
    private func addSubviews() {
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        view.addSubview(progressView)
        progressView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: Constants.progressViewCenterYConstraint).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: Constants.progressViewWidth).isActive = true
    }
    
    private func fetchImage(for photoAsset: PHAsset) {
        guard let photoService = photoService else { return }
        self.progressView.isHidden = false
        
        photoService.requestPicture(photoAsset: photoAsset, targetSize: PHImageManagerMaximumSize) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let image):
                self.imageView.image = image
            case .failure(let error):
                print(Constants.lowFetchFatalError + "\(error)")
            }
            
            photoService.requestImage(photoAsset: photoAsset) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success((let progress, let image)):
                    if let image = image {
                        self.resetProgress()
                        self.imageView.image = image
                        self.drawSaliencyFrames()
                    } else {
                        self.progressView.progress = Float(progress)
                    }
                case .failure(let error):
                    self.resetProgress()
                    print(Constants.highFetchFatalError + "\(error)")
                }
            }
        }
    }
    
    private func drawSaliencyFrames(type: TypeOfSaliency = .attention) {
        guard let saliencyService = saliencyService else { return }
        guard let image = imageView.image else { return }
        
        saliencyService.getSaliencyRectangles(image: image, type: type) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let saliencyFrames):
                saliencyFrames.forEach { rect in
                    self.drawRectangle(color: .red, lineWidth: Constants.rectangleLineWidth * image.size.width, rect: CGRect(origin: rect.origin, size: rect.size))
                }
            case .failure(let error):
                print(Constants.getSaliencyFramesFatalError + "\(error.localizedDescription)")
            }
        }
        
    }
    
    private func drawRectangle(color: UIColor, lineWidth: CGFloat, rect: CGRect) {
        guard let image = self.imageView.image else { return }
        
        UIGraphicsBeginImageContext(image.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        defer { UIGraphicsEndImageContext() }
        
        image.draw(at: CGPoint.zero)
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(color.cgColor)
        context.stroke(rect)
        
        if let imageWithRect = UIGraphicsGetImageFromCurrentImageContext() {
            self.imageView.image = imageWithRect
        }
    }
    
    private func animateZoom(with scale: CGAffineTransform) {
        UIView.animate(withDuration: Constants.animateTimeInterval) {
            self.imageView.transform = scale
        } completion: { completed in
            if completed {
                self.imageView.transform = .identity
                
                if self.imageView.contentMode == .scaleAspectFit {
                    self.imageView.contentMode = .scaleAspectFill
                } else {
                    self.imageView.contentMode = .scaleAspectFit
                }
            }
        }
    }
    
    private func resetProgress() {
        self.progressView.progress = Constants.progressZeroValue
        self.progressView.isHidden = true
    }
    
    @objc private func tappedZoom() {
        guard let image = imageView.image else { return }
        
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: imageView.bounds)
        let scaleRatio: CGFloat
        
        if view.bounds.width > view.bounds.height {
            scaleRatio = view.bounds.width / frame.width
        } else {
            scaleRatio = view.bounds.height / frame.height
        }
        
        let scaleXandY = 1 / scaleRatio
        let scaleTransform: CGAffineTransform
        switch imageView.contentMode {
        case .scaleAspectFit:
            scaleTransform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
        case .scaleAspectFill:
            scaleTransform = CGAffineTransform(scaleX: scaleXandY, y: scaleXandY)
        default:
            return
        }
        
        animateZoom(with: scaleTransform)
    }
}
