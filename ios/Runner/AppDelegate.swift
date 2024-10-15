import UIKit
import Flutter
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback{ (registry) in GeneratedPluginRegistrant.register(with: registry) }
    GeneratedPluginRegistrant.register(with: self)
    UNUserNotificationCenter.current().delegate = self

    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: "dev.flutter.background.refresh", using: nil) { task in
        self.handleAppRefresh(task: task as! BGAppRefreshTask) // Implementieren Sie Ihre Taskbehandlung
      }
    }

    return true
  }

  @available(iOS 13.0, *)
  func handleAppRefresh(task: BGAppRefreshTask) {
    task.setTaskCompleted(success: true)
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    completionHandler([.alert, .sound, .badge])
  }
}
