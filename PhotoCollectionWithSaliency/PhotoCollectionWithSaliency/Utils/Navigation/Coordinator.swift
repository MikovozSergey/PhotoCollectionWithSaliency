import UIKit

class Coordinator: NSObject {
    
    private(set) var navigationController: UINavigationController
    private(set) var coordinator: Coordinator?
    
    init(parent coordinator: Coordinator? = nil) {
        self.coordinator = coordinator
        self.navigationController = UINavigationController()
        super.init()
        navigationController.delegate = self
    }
}

extension Coordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    }
}

