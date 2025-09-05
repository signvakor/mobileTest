import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 创建窗口
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 创建导航控制器和主视图控制器
        let bookingListVC = BookingListViewController()
        let navigationController = UINavigationController(rootViewController: bookingListVC)
        
        // 设置根视图控制器
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
        
        print("Booking Demo App launched successfully")
        
        return true
    }
} 
