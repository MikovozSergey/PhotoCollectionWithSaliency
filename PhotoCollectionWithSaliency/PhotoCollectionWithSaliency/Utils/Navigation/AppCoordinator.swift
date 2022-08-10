import UIKit
import Photos

final class AppCoordinator: Coordinator {

    private var appConfigure: AppConfigure

    init(appConfigure: AppConfigure) {
        self.appConfigure = appConfigure
        super.init()
        setupNavigationBarAppearance()
    }

    private func setupNavigationBarAppearance() {
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationController.navigationBar.standardAppearance = navigationBarAppearance
        navigationController.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        navigationController.navigationBar.tintColor = .label
    }

    func start(in window: UIWindow, animated: Bool = true) {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        let photoVC = PhotoViewController(windowSize: window.bounds.size, photoService: appConfigure.photoService, delegate: self)
        
        navigationController.pushViewController(photoVC, animated: animated)
    }
}

extension AppCoordinator: PhotoViewControllerDelegate {

    func tapToPicture(photoAsset: PHAsset) {
        let photoDetailsVC = PhotoDetailsViewController(photoAsset: photoAsset, photoService: appConfigure.photoService, saliencyService: appConfigure.saliencyService)
        navigationController.pushViewController(photoDetailsVC, animated: true)
    }
}
