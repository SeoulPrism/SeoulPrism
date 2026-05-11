import Flutter
import UIKit
import WidgetKit

class SceneDelegate: FlutterSceneDelegate {

  // 위젯 → 앱 진입 시 들어온 URL 을 Flutter 측이 처리할 수 있도록 보관.
  // 예: com.seoul.prism://route?dep=...&arr=...
  static let appGroupId = "group.com.seoul.prism.widget"
  static let widgetChannelName = "seoul_prism/widget_data"

  private var widgetChannel: FlutterMethodChannel?

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    guard let controller = window?.rootViewController as? FlutterViewController,
          let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }

    // ── Live Activity channel ──
    let liveChannel = FlutterMethodChannel(
      name: "seoul_prism/live_activity",
      binaryMessenger: controller.binaryMessenger
    )
    liveChannel.setMethodCallHandler { [weak appDelegate] (call, result) in
      appDelegate?.handleLiveActivityCall(call, result: result)
    }

    // ── Audio session channel (Gemini Live 진입/이탈 시 호출) ──
    let audioChannel = FlutterMethodChannel(
      name: "seoul_prism/audio_session",
      binaryMessenger: controller.binaryMessenger
    )
    audioChannel.setMethodCallHandler { [weak appDelegate] (call, result) in
      appDelegate?.handleAudioSessionCall(call, result: result)
    }

    // ── Widget data channel — App Group UserDefaults write ──
    widgetChannel = FlutterMethodChannel(
      name: SceneDelegate.widgetChannelName,
      binaryMessenger: controller.binaryMessenger
    )
    widgetChannel?.setMethodCallHandler { (call, result) in
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "setRecentRoute":
        let defaults = UserDefaults(suiteName: SceneDelegate.appGroupId)
        defaults?.set(args["departure"] as? String ?? "", forKey: "recent_dep")
        defaults?.set(args["arrival"] as? String ?? "", forKey: "recent_arr")
        defaults?.set(args["depLat"] as? Double, forKey: "recent_dep_lat")
        defaults?.set(args["depLng"] as? Double, forKey: "recent_dep_lng")
        defaults?.set(args["arrLat"] as? Double, forKey: "recent_arr_lat")
        defaults?.set(args["arrLng"] as? Double, forKey: "recent_arr_lng")
        // 홈화면 위젯 timeline 강제 갱신.
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // 위젯이 launch URL 을 들고 들어왔으면 처리.
    if let urlContext = connectionOptions.urlContexts.first {
      handleIncomingURL(urlContext.url, controller: controller)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    guard let url = URLContexts.first?.url,
          let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    handleIncomingURL(url, controller: controller)
  }

  /// 위젯 또는 외부에서 com.seoul.prism://... 으로 들어온 URL 을 Flutter 측에 전달.
  private func handleIncomingURL(_ url: URL, controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "seoul_prism/incoming_url",
      binaryMessenger: controller.binaryMessenger
    )
    channel.invokeMethod("handle", arguments: url.absoluteString)
  }
}
