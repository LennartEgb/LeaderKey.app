import Testing
import XCTest

struct ActionTests {

  @Test func testDisplayName_withLabel() async throws {
    let action = Action(key: "testKey", type: .application, label: "Open App", value: "/Applications/MyApp.app")
    XCTAssertEqual(action.displayName, "Open App")
  }

  @Test func testDisplayName_withEmptyLabel() async {
    let action = Action(key: "testKey", type: .application, label: "", value: "/Applications/MyApp.app")
    XCTAssertEqual(action.displayName, "MyApp")
  }

  @Test func testDisplayName_withoutLabel() {
    let action = Action(key: "testKey", type: .application, label: nil, value: "/Applications/MyApp.app")
    XCTAssertEqual(action.displayName, "MyApp")
  }

  @Test func testBestGuessDisplayName_application() {
    let action = Action(key: "testKey", type: .application, label: nil, value: "/Applications/MyApp.app")
    XCTAssertEqual(action.bestGuessDisplayName, "MyApp")

    let action2 = Action(key: "testKey", type: .application, label: nil, value: "/Applications/AnotherApp.something.app")
    XCTAssertEqual(action2.bestGuessDisplayName, "AnotherApp.something")
  }

  @Test func testBestGuessDisplayName_command() {
    let action = Action(key: "testKey", type: .command, label: nil, value: "ls -l /tmp")
    XCTAssertEqual(action.bestGuessDisplayName, "ls")

    let action2 = Action(key: "testKey", type: .command, label: nil, value: "open /Applications/MyApp.app")
    XCTAssertEqual(action2.bestGuessDisplayName, "open")

    let action3 = Action(key: "testKey", type: .command, label: nil, value: "singleword")
    XCTAssertEqual(action3.bestGuessDisplayName, "singleword")
  }

  @Test func testBestGuessDisplayName_folder() {
    let action = Action(key: "testKey", type: .folder, label: nil, value: "/Users/testuser/Documents")
    XCTAssertEqual(action.bestGuessDisplayName, "Documents")
  }

  @Test func testBestGuessDisplayName_url() {
    let action = Action(key: "testKey", type: .url, label: nil, value: "https://www.google.com")
    XCTAssertEqual(action.bestGuessDisplayName, "URL")
  }

  @Test func testCodable() throws {
    let action = Action(key: "testKey", type: .application, label: "Open App", value: "/Applications/MyApp.app")
    let encoder = JSONEncoder()
    let data = try encoder.encode(action)

    let decoder = JSONDecoder()
    let decodedAction = try decoder.decode(Action.self, from: data)

    XCTAssertEqual(action.key, decodedAction.key)
    XCTAssertEqual(action.type, decodedAction.type)
    XCTAssertEqual(action.label, decodedAction.label)
    XCTAssertEqual(action.value, decodedAction.value)
  }
}
