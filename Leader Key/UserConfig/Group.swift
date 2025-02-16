struct Group: Codable {
  var key: String?
  var type: Type = .group
  var label: String?
  var actions: [ActionOrGroup]

  var displayName: String {
    guard let labelValue = label else { return "Group" }
    if labelValue.isEmpty { return "Group" }
    return labelValue
  }
}
