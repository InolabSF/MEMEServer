import UIKit


/// MARK: - AppDelegate
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// MARK: - properties
    
    var window: UIWindow?

    
    /// MARK: - life cycle

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        MEMEBridge.sharedInstance().start()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
        MEMEBridge.sharedInstance().stop()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        MEMEBridge.sharedInstance().start()
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }


}

