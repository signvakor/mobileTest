import UIKit

// MARK: - Booking Segment Cell

class BookingSegmentCell: UITableViewCell {
    
    static let identifier = "BookingSegmentCell"

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private lazy var segmentIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textColor = .label
        return label
    }()
    
    private lazy var originView: LocationView = {
        let view = LocationView()
        return view
    }()
    
    private lazy var destinationView: LocationView = {
        let view = LocationView()
        return view
    }()
    
    private lazy var arrowImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "arrow.right")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(segmentIdLabel)
        containerView.addSubview(originView)
        containerView.addSubview(arrowImageView)
        containerView.addSubview(destinationView)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-8)
            make.height.greaterThanOrEqualTo(100)
        }
        
        segmentIdLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        }
        
        originView.snp.makeConstraints { make in
            make.top.equalTo(segmentIdLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(arrowImageView).offset(-8)
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalTo(originView)
            make.centerX.equalToSuperview()
            make.height.width.equalTo(24)
        }
        
        destinationView.snp.makeConstraints { make in
            make.top.equalTo(originView.snp.top)
            make.left.equalTo(arrowImageView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(originView.snp.bottom)
        }
    }
    
    func configure(with segment: Segment) {
        segmentIdLabel.text = "Segment \(segment.id)"
        originView.configure(with: segment.originAndDestinationPair.origin, city: segment.originAndDestinationPair.originCity)
        destinationView.configure(with: segment.originAndDestinationPair.destination, city: segment.originAndDestinationPair.destinationCity)
    }
}

// MARK: - Location View

class LocationView: UIView {
    
    private lazy var codeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .systemBlue
        label.textAlignment = .center
        return label
    }()
    
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(codeLabel)
        addSubview(nameLabel)
        addSubview(cityLabel)
        
        codeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(codeLabel.snp.bottom).offset(4)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        cityLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    func configure(with location: Location, city: String) {
        codeLabel.text = location.code
        nameLabel.text = location.displayName
        cityLabel.text = city
    }
}
