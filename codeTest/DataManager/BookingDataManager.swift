import Foundation
import Combine

@MainActor
class BookingDataManager: ObservableObject {
    
    //待监听的属性
    @Published var bookingData: BookingData?
    @Published var isLoading = false
    @Published var error: BookingError?
    @Published var lastUpdated: Date?
    
    private let service: BookingServiceProtocol
    private let cache: BookingCacheProtocol
    private var cancellables = Set<AnyCancellable>()
     
    init(service: BookingServiceProtocol = MockBookingService(), 
         cache: BookingCacheProtocol = UserDefaultsBookingCache()) {
        self.service = service
        self.cache = cache
        
        // 初始化时尝试加载缓存数据
        loadCachedDataIfAvailable()
    }
    
    /// 获取booking数据 统一接口
    func fetchBookingData(forceRefresh: Bool = false) async {
        print("DataManager: Starting to fetch booking data (forceRefresh: \(forceRefresh))")
        
        isLoading = true
        error = nil
        
        do {
            // 如果不强制刷新，先检查缓存
            if !forceRefresh {
                if let cachedData = try? cache.load(), !cachedData.isExpired {
                    print("DataManager: Using cached data")
                    bookingData = cachedData.data
                    lastUpdated = Date(timeIntervalSince1970: cachedData.timestamp)
                    isLoading = false
                    
                    // 如果缓存数据过期但未完全失效，在后台刷新 重新显示
                    if cachedData.isStale {
                        print("DataManager: Cached data is stale, refreshing in background")
                        Task {
                            await refreshDataInBackground()
                        }
                    }
                    return
                }
            }
            
            let freshData = try await service.fetchBookingData()
            
            // 保存到缓存
            try cache.save(freshData)
            
            // 更新UI
            bookingData = freshData
            lastUpdated = Date()
   
            //打印最新获得的data
            print("DataManager: result: \(freshData)")
            
        } catch {
            print("DataManager: Failed to fetch booking data - \(error)")
            self.error = error as? BookingError ?? BookingError.networkError(error.localizedDescription)
            
            // 如果网络请求失败，尝试使用缓存数据
            if let cachedData = try? cache.load() {
                bookingData = cachedData.data
                lastUpdated = Date(timeIntervalSince1970: cachedData.timestamp)
            }
        }
        
        isLoading = false
    }
    
    /// 刷新数据
    func refresh() async {
        await fetchBookingData(forceRefresh: true)
    }
    
    /// 清除缓存
    func clearCache() {
        do {
            try cache.clear()
            bookingData = nil
            lastUpdated = nil
            print("DataManager: Cache cleared")
        } catch {
            print("DataManager: Failed to clear cache - \(error)")
        }
    }
    
    /// 检查数据是否有效
    func isDataValid() -> Bool {
        return cache.isDataValid()
    }
    
    private func loadCachedDataIfAvailable() {
        do {
            if let cachedData = try cache.load(), !cachedData.isExpired {
                print("DataManager: Loading cached data on initialization")
                bookingData = cachedData.data
                lastUpdated = Date(timeIntervalSince1970: cachedData.timestamp)
            }
        } catch {
            print("DataManager: Failed to load cached data on initialization - \(error)")
        }
    }
    
    private func refreshDataInBackground() async {
        do {
            let freshData = try await service.fetchBookingData()
            try cache.save(freshData)
            
            await MainActor.run {
                bookingData = freshData
                lastUpdated = Date()
                print("DataManager: Background refresh completed")
            }
        } catch {
            print("DataManager: Background refresh failed - \(error)")
        }
    }
}

// MARK: - Data Manager Extensions

extension BookingDataManager {
    
    /// 获取数据状态描述
    var dataStatusDescription: String {
        if isLoading {
            return "Loading..."
        } else if let error = error {
            return "Error: \(error.localizedDescription)"
        } else if let lastUpdated = lastUpdated {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "Last updated: \(formatter.string(from: lastUpdated))"
        } else {
            return "No data available"
        }
    }
    
    /// 检查是否有有效数据
    var hasValidData: Bool {
        return bookingData != nil && error == nil
    }
    
    /// 获取segments数量
    var segmentsCount: Int {
        return bookingData?.segments.count ?? 0
    }
    
    /// 获取ship reference
    var shipReference: String {
        return bookingData?.shipReference ?? "N/A"
    }
    
    /// 获取duration描述
    var durationDescription: String {
        guard let duration = bookingData?.duration else { return "N/A" }
        let hours = duration / 60
        let minutes = duration % 60
        return "\(hours)h \(minutes)m"
    }
}

