import SwiftUI

enum Mini {
  static let size = 36.0
  static let margin = 8.0

  class Window: MainWindow {
    required init(controller: Controller) {
      let rect = NSRect(x: 0, y: 0, width: Mini.size, height: Mini.size)
      super.init(controller: controller, contentRect: rect)
      let view = MainView().environmentObject(self.controller.userState)
      contentView = NSHostingView(rootView: view)
    }

    override func show(on screen: NSScreen, after: (() -> Void)? = nil) {
      let viewOffset = NSPoint(x: self.frame.width + Mini.margin, y: Mini.margin)
      let newOriginX = screen.visibleFrame.minX + screen.visibleFrame.width - viewOffset.x
      let newOriginY = screen.visibleFrame.minY + viewOffset.y
      self.setFrameOrigin(NSPoint(x: newOriginX, y: newOriginY))

      makeKeyAndOrderFront(nil)

      fadeIn {
        after?()
      }
    }

    override func hide(after: (() -> Void)? = nil) {
      fadeOut {
        super.hide(after: after)
      }
    }

    override func notFound() {
      shake()
    }

    override func cheatsheetOrigin(cheatsheetSize: NSSize) -> NSPoint {
      return NSPoint(
        x: self.frame.maxX - cheatsheetSize.width,
        y: self.frame.maxY + Mini.margin,
      )
    }
  }

  struct MainView: View {
    @EnvironmentObject var userState: UserState

    var body: some View {
      ZStack {
        let text = Text(userState.currentGroup?.key ?? userState.display ?? "●")
          .fontDesign(.rounded)
          .fontWeight(.bold)

        if userState.isShowingRefreshState {
          text.pulsate()
        } else {
          text
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .font(.system(size: 16, weight: .semibold, design: .rounded))
      .foregroundStyle(userState.currentGroup?.key == nil ? .secondary : .primary)
      .background(
        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
      )
    }
  }
}

struct Invisible_MainView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      MysteryBox.MainView().environmentObject(
        UserState(userConfig: UserConfig()))
    }.frame(width: Mini.size, height: Mini.size, alignment: .center)
  }
}
