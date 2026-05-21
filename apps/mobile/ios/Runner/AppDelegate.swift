import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private func pushDebugLog(_ message: String) {
    #if DEBUG
    print("[Push:iOS] \(message)")
    #endif
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerPeriodicTask(
        withIdentifier: "offline-regions-refresh",
        frequency: NSNumber(value: 24 * 60 * 60)
      )
      WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "chisto.reportOutbox.drain")
    }
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Required before FCM can obtain an APNS token on iOS.
    application.registerForRemoteNotifications()
    #if DEBUG
    if let entitlements = Bundle.main.object(forInfoDictionaryKey: "Entitlements") as? [String: Any],
       let aps = entitlements["aps-environment"] as? String {
      pushDebugLog("aps-environment (Info.plist) = \(aps)")
    } else if let url = Bundle.main.url(forResource: "Runner", withExtension: "entitlements"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let aps = plist["aps-environment"] as? String {
      pushDebugLog("aps-environment (entitlements file) = \(aps)")
    } else {
      pushDebugLog("aps-environment unknown — verify Debug uses RunnerDebug.entitlements (development)")
    }
    #endif
    return didFinish
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let suffix = deviceToken.map { String(format: "%02x", $0) }.joined().suffix(8)
    pushDebugLog("APNS device token registered (…\(suffix))")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    pushDebugLog("APNS registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    let messageId = userInfo["gcm.message_id"] as? String ?? userInfo["messageId"] as? String ?? "?"
    pushDebugLog("didReceiveRemoteNotification messageId=\(messageId)")
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
