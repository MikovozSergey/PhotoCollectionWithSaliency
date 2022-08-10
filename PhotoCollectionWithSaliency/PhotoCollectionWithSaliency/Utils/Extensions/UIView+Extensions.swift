import UIKit

extension UIView {
    convenience init(_ closure: (Self) -> Void) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        closure(self)
    }
}
