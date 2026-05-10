import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // 다이나믹 아일랜드/잠금화면 Live Activity 상태.
  // SceneDelegate 가 'seoul_prism/live_activity' MethodChannel 을 등록해 이 메서드들로 위임.
  var routeActivity: Any?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase 는 Dart 측 Firebase.initializeApp(...) 가 담당.
    // APNs 등록은 firebase_messaging swizzle 이 자동으로 해야 하는데
    // 일부 환경에서 안 됨 → 명시 호출.
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      application.registerForRemoteNotifications()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    NSLog("[AppDelegate] APNs 등록 성공 — token len=\(token.count)")
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[AppDelegate] APNs 등록 실패: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // MARK: - Live Activity API (SceneDelegate 의 channel handler 가 호출)

  func handleLiveActivityCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "start":
      startActivity(args: args, result: result)
    case "update":
      updateActivity(args: args, result: result)
    case "stop":
      stopActivity(args: args, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.1, *)
  private func startActivity(args: [String: Any], result: @escaping FlutterResult) {
    let attributes = RouteLiveActivityAttributes(
      destination: args["destination"] as? String ?? ""
    )
    let state = RouteLiveActivityAttributes.ContentState(
      headline: args["headline"] as? String ?? "",
      detail: args["detail"] as? String ?? "",
      etaMinutes: args["etaMinutes"] as? Int ?? 0,
      lineColorHex: args["lineColorHex"] as? String,
      totalMinutes: args["totalMinutes"] as? Int ?? 0
    )
    do {
      let activity: Activity<RouteLiveActivityAttributes>
      if #available(iOS 16.2, *) {
        let content = ActivityContent(state: state, staleDate: nil)
        activity = try Activity<RouteLiveActivityAttributes>.request(
          attributes: attributes,
          content: content
        )
      } else {
        activity = try Activity<RouteLiveActivityAttributes>.request(
          attributes: attributes,
          contentState: state
        )
      }
      self.routeActivity = activity
      result(activity.id)
    } catch {
      result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
    }
  }

  @available(iOS 16.1, *)
  private func updateActivity(args: [String: Any], result: @escaping FlutterResult) {
    guard let activity = self.routeActivity as? Activity<RouteLiveActivityAttributes> else {
      result(nil); return
    }
    let state = RouteLiveActivityAttributes.ContentState(
      headline: args["headline"] as? String ?? "",
      detail: args["detail"] as? String ?? "",
      etaMinutes: args["etaMinutes"] as? Int ?? 0,
      lineColorHex: args["lineColorHex"] as? String,
      totalMinutes: args["totalMinutes"] as? Int ?? 0
    )
    Task {
      if #available(iOS 16.2, *) {
        let content = ActivityContent(state: state, staleDate: nil)
        await activity.update(content)
      } else {
        await activity.update(using: state)
      }
      result(nil)
    }
  }

  @available(iOS 16.1, *)
  private func stopActivity(args: [String: Any], result: @escaping FlutterResult) {
    guard let activity = self.routeActivity as? Activity<RouteLiveActivityAttributes> else {
      result(nil); return
    }
    Task {
      if #available(iOS 16.2, *) {
        await activity.end(nil, dismissalPolicy: ActivityUIDismissalPolicy.immediate)
      } else {
        await activity.end(dismissalPolicy: ActivityUIDismissalPolicy.immediate)
      }
      self.routeActivity = nil
      result(nil)
    }
  }
}
