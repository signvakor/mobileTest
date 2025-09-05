import UIKit
import Combine
@_exported import SnapKit
// MARK: - Booking List View Controller

class BookingListViewController: UIViewController {

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BookingSegmentCell.self, forCellReuseIdentifier: BookingSegmentCell.identifier)
        tableView.register(BookingHeaderView.self, forHeaderFooterViewReuseIdentifier: BookingHeaderView.identifier)
        tableView.backgroundColor = .systemGroupedBackground
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return control
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let dataManager = BookingDataManager()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // 页面出现时调用数据提供者接口 可以先显示缓存
        Task {
            await dataManager.fetchBookingData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 每次页面出现时都调用数据提供者接口 刷新
        print("BookingListViewController: viewWillAppear - calling data provider")
        Task {
            await dataManager.fetchBookingData()
        }
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = "Booking data Infos"
        view.backgroundColor = .systemGroupedBackground
        
        // 添加导航栏按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshData)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Clear Cache",
            style: .plain,
            target: self,
            action: #selector(clearCache)
        )
        
        // 添加子视图
        view.addSubview(tableView)
        view.addSubview(statusLabel)
        view.addSubview(loadingIndicator)
        
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(statusLabel.snp.top).offset(-8)
        }

        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.leading).offset(16)
            make.trailing.equalTo(view.snp.trailing).offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        // 添加刷新控制
        tableView.refreshControl = refreshControl
    }
    
    private func setupBindings() {
        // 监听数据变化
        dataManager.$bookingData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        // 监听加载状态
        dataManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        // 监听错误状态
        dataManager.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.showErrorAlert(error)
                }
            }
            .store(in: &cancellables)
        
        // 监听状态更新
        dataManager.$lastUpdated
            .combineLatest(dataManager.$isLoading, dataManager.$error)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lastUpdated, isLoading, error in
                self?.updateStatusLabel(lastUpdated: lastUpdated, isLoading: isLoading, error: error)
            }
            .store(in: &cancellables)
    }
    
    @objc private func refreshData() {
        Task {
            await dataManager.refresh()
        }
    }
    
    @objc private func clearCache() {
        dataManager.clearCache()
        tableView.reloadData()
    }

    private func updateStatusLabel(lastUpdated: Date?, isLoading: Bool, error: BookingError?) {
        if isLoading {
            statusLabel.text = "Loading booking data..."
        } else if let error = error {
            statusLabel.text = "Error: \(error.localizedDescription)"
            statusLabel.textColor = .systemRed
        } else if let lastUpdated = lastUpdated {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            statusLabel.text = "Last updated: \(formatter.string(from: lastUpdated))"
            statusLabel.textColor = .systemGray
        } else {
            statusLabel.text = "No data available"
            statusLabel.textColor = .systemGray
        }
    }
    
    private func showErrorAlert(_ error: BookingError) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            Task {
                await self?.dataManager.refresh()
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension BookingListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataManager.hasValidData ? 2 : 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4 //4个基本属性
        case 1:
            return dataManager.segmentsCount
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell") ?? UITableViewCell(style: .value1, reuseIdentifier: "BasicCell")
        
        guard let bookingData = dataManager.bookingData else {
            return cell
        }
        
        switch indexPath.section {
        case 0:
            //显示 BookingData 的 基本信息
            configureShipInfoCell(cell, at: indexPath, with: bookingData)
        case 1:
            //显示 BookingData 的 segments
            if let segmentCell = tableView.dequeueReusableCell(withIdentifier: BookingSegmentCell.identifier, for: indexPath) as? BookingSegmentCell {
                segmentCell.configure(with: bookingData.segments[indexPath.row])
                return segmentCell
            }
        default:
            break
        }
        
        return cell
    }
    
    private func configureShipInfoCell(_ cell: UITableViewCell, at indexPath: IndexPath, with data: BookingData) {
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Ship Reference"
            cell.detailTextLabel?.text = data.shipReference
        case 1:
            cell.textLabel?.text = "Duration"
            //格式化秒转 h m
            cell.detailTextLabel?.text = dataManager.durationDescription
        case 2:
            cell.textLabel?.text = "Can Issue Ticket"
            cell.detailTextLabel?.text = data.canIssueTicketChecking ? "Yes" : "No"
        case 3:
            cell.textLabel?.text = "Expiry Time"
            if let expiryTime = Double(data.expiryTime) {
                let date = Date(timeIntervalSince1970: expiryTime)
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                cell.detailTextLabel?.text = formatter.string(from: date)
            } else {
                cell.detailTextLabel?.text = "Invalid"
            }
        default:
            break
        }
    }
}


extension BookingListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Ship Information"
        case 1:
            return "Segments (\(dataManager.segmentsCount))"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 120
        }
        return UITableView.automaticDimension
    }
}

