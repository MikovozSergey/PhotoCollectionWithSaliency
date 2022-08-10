import UIKit

extension UICollectionViewFlowLayout {

    static func setupFlowLayout(in window: CGSize) -> UICollectionViewFlowLayout {
        
        let width = min(window.width, window.height)
        let layout = UICollectionViewFlowLayout()

        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 4

        let imageSize = width / 4 - layout.minimumInteritemSpacing * 3
        layout.itemSize = CGSize(width: imageSize, height: imageSize)

        return layout
    }
}
