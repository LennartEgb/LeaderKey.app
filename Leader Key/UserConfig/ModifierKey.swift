import AppKit
import Defaults

enum ModifierKey: String, Codable, Defaults.Serializable, CaseIterable, Identifiable {
  case none
  case control
  case option

  var id: Self { self }

  var flag: NSEvent.ModifierFlags? {
    switch self {
    case .control: return .control
    case .option: return .option
    default: return nil
    }
  }
}
