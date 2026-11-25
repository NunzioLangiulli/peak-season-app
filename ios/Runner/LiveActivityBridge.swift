// Bridge between the Dart code (lib/notifications/live_activity.dart) and
// ActivityKit: starts, updates and ends the "shopping mode" Live Activity, and
// tells Dart when the app was opened by tapping it.
import ActivityKit
import Flutter
import UIKit

final class LiveActivityBridge: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
  private var channel: FlutterMethodChannel?

  /// The app was opened from the Live Activity before Dart was listening.
  private var pendingOpen = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LiveActivityBridge()
    let channel = FlutterMethodChannel(name: "peak_season/live_activity", binaryMessenger: registrar.messenger())
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    registrar.addSceneDelegate(instance)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSupported":
      if #available(iOS 16.1, *) {
        result(ActivityAuthorizationInfo().areActivitiesEnabled)
      } else {
        result(false)
      }
    case "show":
      guard #available(iOS 16.1, *) else { return result(false) }
      guard let args = call.arguments as? [String: Any], let raw = args["lines"] as? [[[String: Any]]] else {
        return result(false)
      }
      let lines = raw.map { line in
        line.map { ShoppingRun(t: $0["t"] as? String ?? "", b: $0["b"] as? Bool ?? false) }
      }
      Task { @MainActor in
        result(await Self.show(ShoppingActivityAttributes.ContentState(lines: lines)))
      }
    case "end":
      guard #available(iOS 16.1, *) else { return result(nil) }
      Task { @MainActor in
        await Self.endAll()
        result(nil)
      }
    case "isActive":
      if #available(iOS 16.1, *) {
        result(Activity<ShoppingActivityAttributes>.activities.contains { $0.activityState == .active })
      } else {
        result(false)
      }
    case "takePendingOpen":
      result(pendingOpen)
      pendingOpen = false
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @available(iOS 16.1, *)
  private static func show(_ state: ShoppingActivityAttributes.ContentState) async -> Bool {
    let running = Activity<ShoppingActivityAttributes>.activities.filter { $0.activityState == .active }
    if let current = running.first {
      if #available(iOS 16.2, *) {
        await current.update(ActivityContent(state: state, staleDate: nil))
      } else {
        await current.update(using: state)
      }
      for extra in running.dropFirst() {
        await end(extra)
      }
      return true
    }
    do {
      if #available(iOS 16.2, *) {
        _ = try Activity.request(
          attributes: ShoppingActivityAttributes(),
          content: ActivityContent(state: state, staleDate: nil),
          pushType: nil
        )
      } else {
        _ = try Activity.request(attributes: ShoppingActivityAttributes(), contentState: state, pushType: nil)
      }
      return true
    } catch {
      return false
    }
  }

  @available(iOS 16.1, *)
  private static func endAll() async {
    for activity in Activity<ShoppingActivityAttributes>.activities {
      await end(activity)
    }
  }

  @available(iOS 16.1, *)
  private static func end(_ activity: Activity<ShoppingActivityAttributes>) async {
    if #available(iOS 16.2, *) {
      await activity.end(nil, dismissalPolicy: .immediate)
    } else {
      await activity.end(dismissalPolicy: .immediate)
    }
  }

  // MARK: - Opening from the Live Activity

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts else { return false }
    return open(contexts.map(\.url))
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    open(URLContexts.map(\.url))
  }

  private func open(_ urls: [URL]) -> Bool {
    guard urls.contains(where: ShoppingLink.matches) else { return false }
    pendingOpen = true
    // If Dart is already listening it opens the list now; otherwise it asks
    // with "takePendingOpen" when it starts.
    channel?.invokeMethod("openShopping", arguments: nil) { [weak self] reply in
      if !(reply is FlutterError) && (reply as? NSObject) !== FlutterMethodNotImplemented {
        self?.pendingOpen = false
      }
    }
    return true
  }
}
