import Foundation

// 缓存协议
protocol BookingCacheProtocol {
    func save(_ data: BookingData) throws
    func load() throws -> CachedBookingData?
    func clear() throws
    func isDataValid() -> Bool
}

 //用Userdefault实现, 也可以用文件系统 等方式

class UserDefaultsBookingCache: BookingCacheProtocol {
    
    private let userDefaults: UserDefaults
    private let cacheKey = "cached_booking_data"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save(_ data: BookingData) throws {
        let expiryTime = Date().timeIntervalSince1970 + Double(data.duration)
        let cachedData = CachedBookingData(
            data: data,
            timestamp: Date().timeIntervalSince1970,
            expiryTime: expiryTime
        )
        
        do {
            let encodedData = try JSONEncoder().encode(cachedData)
            userDefaults.set(encodedData, forKey: cacheKey)
            print("Cache: Successfully saved booking data")
        } catch {
            print("Cache: Failed to save booking data - \(error)")
            throw BookingError.cacheError("Failed to encode data: \(error.localizedDescription)")
        }
    }
    
    func load() throws -> CachedBookingData? {
        guard let data = userDefaults.data(forKey: cacheKey) else {
            print("Cache: No cached data found")
            return nil
        }
        
        do {
            let cachedData = try JSONDecoder().decode(CachedBookingData.self, from: data)
            print("Cache: Successfully loaded cached booking data")
            return cachedData
        } catch {
            print("Cache: Failed to decode cached data - \(error)")
            throw BookingError.cacheError("Failed to decode data: \(error.localizedDescription)")
        }
    }
    
    func clear() throws {
        userDefaults.removeObject(forKey: cacheKey)
        print("Cache: Cleared cached booking data")
    }
    
    func isDataValid() -> Bool {
        guard let cachedData = try? load() else {
            return false
        }
        
        let isValid = !cachedData.isExpired && !cachedData.isStale
        print("Cache: Data validity check - \(isValid ? "Valid" : "Invalid")")
        return isValid
    }
}



