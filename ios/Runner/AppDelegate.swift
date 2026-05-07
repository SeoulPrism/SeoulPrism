import Flutter
import UIKit
import ActivityKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  // 다이나믹 아일랜드/잠금화면 Live Activity 핸들러.
  // Dart 측 LiveActivityService 가 'seoul_prism/live_activity' MethodChannel 로 호출.
  private var routeActivity: Any? = nil  // Activity<RouteActivityAttributes> — Widget Extension 추가 후 타입 활성화

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      let channel = FlutterMethodChannel(
        name: "seoul_prism/live_activity",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] (call, result) in
        self?.handleLiveActivityCall(call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleLiveActivityCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.1, *) else {
      result(nil)  // 미지원 OS — silent no-op
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 아래 함수들은 Widget Extension target 을 추가한 후 활성화.
  // 그 전에는 LiveActivityService 호출이 silent no-op 으로 동작.
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  @available(iOS 16.1, *)
  private func startActivity(args: [String: Any], result: @escaping FlutterResult) {
    /*
    // ── Widget Extension target 추가 후 주석 해제 ──
    // RouteActivityAttributes / ContentState 는 Widget Extension 측에서 정의 필요.
    let attributes = RouteActivityAttributes(destination: args["destination"] as? String ?? "")
    let state = RouteActivityAttributes.ContentState(
      headline: args["headline"] as? String ?? "",
      detail: args["detail"] as? String ?? "",
      etaMinutes: args["etaMinutes"] as? Int ?? 0,
      lineColorHex: args["lineColorHex"] as? String,
      totalMinutes: args["totalMinutes"] as? Int ?? 0
    )
    do {
      let activity = try Activity<RouteActivityAttributes>.request(
        attributes: attributes,
        contentState: state,
        pushType: nil
      )
      self.routeActivity = activity
      result(activity.id)
    } catch {
      result(FlutterError(code: "start_failed", message: error.localizedDescription, details: nil))
    }
    */
    result(nil)
  }

  @available(iOS 16.1, *)
  private func updateActivity(args: [String: Any], result: @escaping FlutterResult) {
    /*
    // ── Widget Extension target 추가 후 주석 해제 ──
    guard let activity = self.routeActivity as? Activity<RouteActivityAttributes> else {
      result(nil); return
    }
    let state = RouteActivityAttributes.ContentState(
      headline: args["headline"] as? String ?? "",
      detail: args["detail"] as? String ?? "",
      etaMinutes: args["etaMinutes"] as? Int ?? 0,
      lineColorHex: args["lineColorHex"] as? String,
      totalMinutes: args["totalMinutes"] as? Int ?? 0
    )
    Task {
      await activity.update(using: state)
      result(nil)
    }
    */
    result(nil)
  }

  @available(iOS 16.1, *)
  private func stopActivity(args: [String: Any], result: @escaping FlutterResult) {
    /*
    // ── Widget Extension target 추가 후 주석 해제 ──
    guard let activity = self.routeActivity as? Activity<RouteActivityAttributes> else {
      result(nil); return
    }
    Task {
      await activity.end(dismissalPolicy: .immediate)
      self.routeActivity = nil
      result(nil)
    }
    */
    result(nil)
  }
}
