import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    // FlutterViewController 가 만들어진 시점이라 binaryMessenger 안전하게 사용 가능.
    // AppDelegate 의 Live Activity 핸들러에 위임.
    guard let controller = window?.rootViewController as? FlutterViewController,
          let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "seoul_prism/live_activity",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak appDelegate] (call, result) in
      appDelegate?.handleLiveActivityCall(call, result: result)
    }
  }
}
