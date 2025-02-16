import Cocoa
import Combine
import Defaults

let emptyRoot = Group(key: "🚫", label: "Config error", actions: [])

class UserConfig: ObservableObject {
  @Published var root = emptyRoot

  let fileName = "config.json"
  let fileMonitor = FileMonitor()

  var afterReload: ((_ success: Bool) -> Void)?

  func fileURL() -> URL {
    let dir = Defaults[.configDir]
    let filePath = (dir as NSString).appendingPathComponent(fileName)
    return URL(fileURLWithPath: filePath)
  }

  func loadAndWatch() {
    if !configExists() {
      do {
        try bootstrapConfig()
      } catch {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "\(error)"
        alert.runModal()
        root = emptyRoot
      }
    }

    loadConfig()
    startWatching()
  }

  func saveConfig() {
    fileMonitor.stopMonitoring()

    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys]
      let jsonData = try encoder.encode(root)
      try jsonData.write(to: fileURL())
    } catch {
      handleConfigError(error)
    }

    // Resume monitoring
    reloadConfig()
    startWatching()
  }

  func reloadConfig() {
    loadConfig()
    afterReload?(true)
  }

  private func configExists() -> Bool {
    let path = fileURL().path
    return FileManager.default.fileExists(atPath: path)
  }

  private func bootstrapConfig() throws {
    guard let data = defaultConfig.data(using: .utf8) else {
      throw NSError(
        domain: "UserConfig", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Failed to encode default config"])
    }
    let url = fileURL()
    try data.write(to: url, options: [.atomic])
  }

  private func readConfigFile() -> String {
    do {
      let path = fileURL().path
      let str = try String(contentsOfFile: path, encoding: .utf8)
      return str
    } catch {
      let alert = NSAlert()
      alert.alertStyle = .critical
      alert.messageText = "\(error)"
      alert.runModal()
      return "{}"
    }
  }

  private func startWatching() {
    self.fileMonitor.startMonitoring(fileURL: fileURL()) {
      self.reloadConfig()
    }
  }

  private func loadConfig() {
    if FileManager.default.fileExists(atPath: fileURL().path) {
      if let jsonData = readConfigFile().data(using: .utf8) {
        let decoder = JSONDecoder()
        do {
          let root_ = try decoder.decode(Group.self, from: jsonData)
          root = root_
        } catch {
          handleConfigError(error)
        }
      } else {
        root = emptyRoot
      }
    } else {
      root = emptyRoot
    }
  }

  private func handleConfigError(_ error: Error) {
    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = "\(error)"
    alert.runModal()
    root = emptyRoot
  }
}

extension UserConfig {
  static func defaultDirectory(fileManager: FileManager = FileManager.default) -> String {
    let appSupportDir = fileManager.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let path = (appSupportDir.path as NSString).appendingPathComponent("Leader Key")
    do {
      try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
    } catch {
      fatalError("Failed to create config directory")
    }
    return path
  }
}

let defaultConfig = """
  {
      "type": "group",
      "actions": [
          { "key": "t", "type": "application", "value": "/System/Applications/Utilities/Terminal.app" },
          {
              "key": "o",
              "type": "group",
              "actions": [
                  { "key": "s", "type": "application", "value": "/Applications/Safari.app" },
                  { "key": "e", "type": "application", "value": "/Applications/Mail.app" },
                  { "key": "i", "type": "application", "value": "/System/Applications/Music.app" },
                  { "key": "m", "type": "application", "value": "/Applications/Messages.app" }
              ]
          },
          {
              "key": "r",
              "type": "group",
              "actions": [
                  { "key": "e", "type": "url", "value": "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols" },
                  { "key": "p", "type": "url", "value": "raycast://confetti" },
                  { "key": "c", "type": "url", "value": "raycast://extensions/raycast/system/open-camera" }
              ]
          }
      ]
  }
  """
