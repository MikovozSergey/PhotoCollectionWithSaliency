import UIKit
import Photos

protocol PhotoViewControllerDelegate {
    func tapToPicture(photoAsset: PHAsset)
}

final class PhotoViewController: UIViewController {
    
    // MARK: - Constants
    
    private struct Constants {
        static let initFatalError: String = "PhotoVC don't installed"
        static let cellFatalError: String = "Wrong type of Cell"
        static let fetchFatalError: String = "Failed to fetch photoAsset "
        static let navigationTitle: String = "Recent"
    }
    
    // MARK: - Properties
    
    private var collectionView: UICollectionView { view as! UICollectionView }
    private lazy var collectionViewFlowLayout = UICollectionViewFlowLayout.setupFlowLayout(in: windowSize)
    private lazy var sizeOfPicture = collectionViewFlowLayout.itemSize
    private let windowSize: CGSize
    private var photoService: PhotoServiceProtocol?
    private var delegate: PhotoViewControllerDelegate?
    private var photoAssets = PHFetchResult<PHAsset>()
    
    // MARK: - Initialization
    
    init(windowSize: CGSize, photoService: PhotoServiceProtocol, delegate: PhotoViewControllerDelegate) {
        self.windowSize = windowSize
        self.photoService = photoService
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError(Constants.initFatalError)
    }
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PHPhotoLibrary.shared().register(self)
        setupUI()
        photoServiceFetchPhoto()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        self.title = Constants.navigationTitle
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
        self.view = collectionView
        
        collectionView.register(PhotoViewCell.self, forCellWithReuseIdentifier: PhotoViewCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.prefetchDataSource = self
    }
    
    private func photoServiceFetchPhoto() {
        photoService?.requestAuthorization { [weak self] isAuthorized in
            guard let self = self, isAuthorized else { return }
            self.fetchPhoto()
        }
    }
    
    private func fetchPhoto() {
        self.photoService?.requestToPhotoAssets(with: PhotoConstants.maximumCountOfPhotos) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let photoAssets):
                self.photoAssets = photoAssets
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}

// MARK: UICollectionViewDataSource + UICollectionViewDelegate

extension PhotoViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photoAssets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoViewCell.identifier,for: indexPath) as? PhotoViewCell else {
            fatalError(Constants.cellFatalError)
        }
        guard let photoService = photoService else { return UICollectionViewCell() }
        photoCell.setClearPicture()
        
        let photoAsset = photoAssets[indexPath.item]
        
        photoCell.localIdentifier = photoAsset.localIdentifier
        
        photoService.requestPicture(photoAsset: photoAsset, targetSize: sizeOfPicture) { result in
            switch result {
            case .success(let image):
                if let image = image, photoCell.localIdentifier == photoAsset.localIdentifier {
                    photoCell.setupPicture(with: image)
                }
            case .failure(let error):
                print(Constants.fetchFatalError + "\(error)")
            }
        }
        
        return photoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        guard let delegate = delegate else { return true }
        delegate.tapToPicture(photoAsset: photoAssets[indexPath.item])
        return false
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension PhotoViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let photoService = photoService else { return }
        let photoAsset = indexPaths.map { indexPath in
            photoAssets[indexPath.item]
        }
        photoService.startCaching(photoAsset: photoAsset, size: sizeOfPicture)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        guard let photoService = photoService else { return }
        let phAssets = indexPaths.map { indexPath in
            photoAssets[indexPath.item]
        }
        photoService.stopCaching(photoAsset: phAssets, size: sizeOfPicture)
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension PhotoViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changeInstance = changeInstance.changeDetails(for: photoAssets) else { return }
        
        if changeInstance.hasMoves || changeInstance.fetchResultBeforeChanges.count != changeInstance.fetchResultAfterChanges.count {
            fetchPhoto()
        }
    }
}
