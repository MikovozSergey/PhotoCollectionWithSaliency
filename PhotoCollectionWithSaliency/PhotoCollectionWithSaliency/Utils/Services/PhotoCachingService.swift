import UIKit
import Photos

enum PhotoServiceError: Error {
    case notAuthorized
    case failedFetch
}

protocol PhotoServiceProtocol {
    
    var isAuthorized: Bool { get }
    
    func requestAuthorization(with completion: @escaping (Bool) -> Void)
    func requestToPhotoAssets(with numberOfPHAssets: Int, with completion: @escaping (Result<PHFetchResult<PHAsset>, Error>) -> Void)
    func requestPicture(photoAsset: PHAsset, targetSize: CGSize, with completion: @escaping (Result<UIImage?, Error>) -> Void)
    func requestImage(photoAsset: PHAsset, with completion: @escaping (Result<(progress: Double, UIImage?), Error>) -> Void)
    func startCaching(photoAsset: [PHAsset], size: CGSize)
    func stopCaching(photoAsset: [PHAsset], size: CGSize)
}

final class PHCachingImageManagerService: PhotoServiceProtocol {
    
    private struct Constants {
        static let fetchFatalError: String = "Failed to fetch photoAsset "
        static let sortDescriptionKey: String = "creationDate"
    }
    
    private let phCachingImageManager = PHCachingImageManager()
    var isAuthorized: Bool {
        let authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch authorizationStatus {
        case .limited, .authorized:
            return true
        case .restricted, .notDetermined, .denied:
            return false
        @unknown default:
            fatalError("\(authorizationStatus)")
        }
    }
    
    func requestAuthorization(with completion: @escaping (Bool) -> Void) {
        if isAuthorized {
            completion(true)
        } else {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                completion(self.isAuthorized)
            }
        }
    }
    
    func requestToPhotoAssets(with fetchLimit: Int, with completion: @escaping (Result<PHFetchResult<PHAsset>, Error>) -> Void) {
        guard isAuthorized else {
            completion(.failure(PhotoServiceError.notAuthorized))
            return
        }
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.fetchLimit = fetchLimit
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: Constants.sortDescriptionKey, ascending: false)]
        
        DispatchQueue.main.async {
            let photoAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            completion(.success(photoAssets))
        }
    }
    
    func requestPicture(photoAsset: PHAsset, targetSize: CGSize, with completion: @escaping (Result<UIImage?, Error>) -> Void) {
        guard isAuthorized else {
            completion(.failure(PhotoServiceError.notAuthorized))
            return
        }
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .highQualityFormat
        
        DispatchQueue.main.async {
            PHCachingImageManager.default().requestImage(for: photoAsset, targetSize: targetSize, contentMode: .aspectFit, options: requestOptions) { uiImage, info in
                
                if let isIniCloud = info?[PHImageResultIsInCloudKey] as? Bool {
                    print(isIniCloud)
                }
                if let uiImage = uiImage {
                    completion(.success(uiImage))
                }
            }
        }
    }
    
    func requestImage(photoAsset: PHAsset, with completion: @escaping (Result<(progress: Double, UIImage?), Error>) -> Void) {
        guard isAuthorized else {
            completion(.failure(PhotoServiceError.notAuthorized))
            return
        }
        let phImageRequestOptions = PHImageRequestOptions()
        phImageRequestOptions.isNetworkAccessAllowed = true
        phImageRequestOptions.deliveryMode = .highQualityFormat
        
        phImageRequestOptions.progressHandler = { (progress, error, _, _) in
            DispatchQueue.main.async {
                if let error = error {
                    print(Constants.fetchFatalError + "\(error.localizedDescription)")
                    completion(.failure(PhotoServiceError.failedFetch))
                } else {
                    completion(.success((progress: progress, nil)))
                }
            }
        }
        
        DispatchQueue.global(qos: .userInteractive).async {
            PHCachingImageManager.default().requestImage(for: photoAsset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: phImageRequestOptions) { uiImage, _ in
                if let uiImage = uiImage {
                    completion(.success((progress: 1.0, uiImage)))
                }
            }
        }
    }
    
    func startCaching(photoAsset: [PHAsset], size: CGSize) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .fastFormat
        
        phCachingImageManager.startCachingImages(for: photoAsset, targetSize: size, contentMode: .aspectFit, options: requestOptions)
    }
    
    func stopCaching(photoAsset: [PHAsset], size: CGSize) {
        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .fastFormat
        
        phCachingImageManager.stopCachingImages(for: photoAsset, targetSize: size, contentMode: .aspectFit,options: requestOptions)
    }
}
