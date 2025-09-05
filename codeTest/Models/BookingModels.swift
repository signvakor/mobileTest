import Foundation

// MARK: - 数据映射的模型

struct BookingData: Codable {
    let shipReference: String
    let shipToken: String
    let canIssueTicketChecking: Bool
    let expiryTime: String
    let duration: Int
    let segments: [Segment]
}

struct Segment: Codable {
    let id: Int
    let originAndDestinationPair: OriginAndDestinationPair
}

struct OriginAndDestinationPair: Codable {
    let destination: Location
    let destinationCity: String
    let origin: Location
    let originCity: String
}

struct Location: Codable {
    let code: String
    let displayName: String
    let url: String
}

// MARK: - 缓存数据结构

let maxEffectiveCacheDuration: TimeInterval = 300

struct CachedBookingData: Codable {
    let data: BookingData
    let timestamp: TimeInterval
    let expiryTime: TimeInterval
    
    var isExpired: Bool {
        return Date().timeIntervalSince1970 > expiryTime
    }
    
    var isStale: Bool {
        // 数据超过5分钟认为过期
        return Date().timeIntervalSince1970 - timestamp > maxEffectiveCacheDuration
    }
}

// MARK: - 返回封装

enum BookingDataResult {
    case success(BookingData)
    case failure(BookingError)
    case cached(BookingData)
}

enum BookingError: Error, LocalizedError {
    case networkError(String)
    case parsingError(String)
    case cacheError(String)
    case expiredData
    case noData
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .parsingError(let message):
            return "Parsing Error: \(message)"
        case .cacheError(let message):
            return "Cache Error: \(message)"
        case .expiredData:
            return "Data has expired"
        case .noData:
            return "No data available"
        }
    }
}

