import Foundation

// MARK: - 数据协议

protocol BookingServiceProtocol {
    func fetchBookingData() async throws -> BookingData
}

// MARK: - Mock 数据 service层

class MockBookingService: BookingServiceProtocol {
    
    private let mockDelay: TimeInterval
    
    init(mockDelay: TimeInterval = 1.0) {
        self.mockDelay = mockDelay
    }
    
    func fetchBookingData() async throws -> BookingData {
        // 模拟一下 网络延迟
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1))
        
        // 模拟网络错误
        if Int.random(in: 1...10) == 3 {
            throw BookingError.networkError("Simulated network error")
        }
        
        // 读取json
        guard let path = Bundle.main.path(forResource: "booking", ofType: "json") else {
            throw BookingError.networkError("Booking JSON file not found")
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let bookingData = try JSONDecoder().decode(BookingData.self, from: data)
            
            // 做一些随机数据变化 并记录最新更新时间 和设置过期时间
            let updatedData = BookingData(
                shipReference: bookingData.shipReference,
                shipToken: generateRandomToken(),
                canIssueTicketChecking: Bool.random(),
                expiryTime: String(Int(Date().timeIntervalSince1970) + 3600), // 1小时后过期
                duration: bookingData.duration + Int.random(in: -100...100),
                segments: bookingData.segments
            )
            return updatedData
            
        } catch {
            print("Service: Failed to parse booking data - \(error)")
            throw BookingError.parsingError(error.localizedDescription)
        }
    }
    
    //随机token
    private func generateRandomToken() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<15).map { _ in characters.randomElement()! })
    }
}
