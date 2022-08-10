import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene( _ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: scene)
        guard let window = window else { return }

        let context = AppConfigure(sizeOfWindow: window.bounds.size, photoService: PHCachingImageManagerService(), saliencyService: VisionService())
        
        appCoordinator = AppCoordinator(appConfigure: context)
        guard let appCoordinator = appCoordinator else { return }
        appCoordinator.start(in: window)
    }
}
