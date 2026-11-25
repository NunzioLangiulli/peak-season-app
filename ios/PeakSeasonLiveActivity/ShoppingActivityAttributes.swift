// Shared by the app (Runner, which starts and updates the Live Activity) and
// the widget extension (which draws it). Both targets compile this file.
import ActivityKit
import Foundation

/// A piece of text in one line, plain or bold.
struct ShoppingRun: Codable, Hashable {
  var t: String
  var b: Bool
}

/// The "shopping mode" Live Activity: same lines as the Android notification
/// (shopping list, then the seasonal produce), built by the Dart code.
@available(iOS 16.1, *)
struct ShoppingActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var lines: [[ShoppingRun]]
  }
}

/// Link opened by a tap on the Live Activity: the app shows its shopping list.
enum ShoppingLink {
  static let url = URL(string: "peakseason://shopping")!

  static func matches(_ url: URL) -> Bool {
    url.scheme == "peakseason" && url.host == "shopping"
  }
}
