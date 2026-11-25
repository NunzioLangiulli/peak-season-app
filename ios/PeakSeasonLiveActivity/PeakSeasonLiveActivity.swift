// Widget extension: draws the "shopping mode" Live Activity.
// - Lock screen (and banner on iPhones without Dynamic Island): the lines.
// - Dynamic Island, compact and minimal: only the app logo.
// - Dynamic Island, expanded (long press): the same lines as the lock screen.
// A tap anywhere opens the app on its shopping list.
import ActivityKit
import SwiftUI
import WidgetKit

@main
struct PeakSeasonWidgets: WidgetBundle {
  var body: some Widget {
    ShoppingLiveActivity()
  }
}

struct ShoppingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: ShoppingActivityAttributes.self) { context in
      ShoppingLinesView(lines: context.state.lines)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
        .widgetURL(ShoppingLink.url)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.bottom) {
          ShoppingLinesView(lines: context.state.lines)
            .padding(.horizontal, 4)
        }
      } compactLeading: {
        AppLogo()
      } compactTrailing: {
        EmptyView()
      } minimal: {
        AppLogo()
      }
      .widgetURL(ShoppingLink.url)
    }
  }
}

/// The app icon, small and rounded.
struct AppLogo: View {
  var body: some View {
    Image("AppLogo")
      .resizable()
      .scaledToFit()
      .frame(width: 22, height: 22)
      .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
  }
}

/// One text per line, with the bold parts (labels, shopping list items).
struct ShoppingLinesView: View {
  let lines: [[ShoppingRun]]

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      ForEach(Array(lines.enumerated()), id: \.offset) { _, runs in
        runs.reduce(Text("")) { text, run in
          text + (run.b ? Text(run.t).bold() : Text(run.t))
        }
        .font(.footnote)
        .foregroundColor(.white)
        .lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
