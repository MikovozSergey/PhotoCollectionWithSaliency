import UIKit

class PhotoViewCell: UICollectionViewCell {
    
    // MARK: - Constants
    
    private struct Constants {
        static let nameOfIdentifier: String = "PhotoViewCell"
        static let initFatalError: String = "Photo cell is not installed"
    }
    
    // MARK: - Properties

    static let identifier = Constants.nameOfIdentifier
    var localIdentifier: String?
    private lazy var pictureView = UIImageView {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
    }

    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError(Constants.initFatalError)
    }

    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(pictureView)
        pictureView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        pictureView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        pictureView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        pictureView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    func setClearPicture() {
        pictureView.image = nil
        localIdentifier = nil
    }

    func setupPicture(with image: UIImage) {
        pictureView.image = image
    }
}
