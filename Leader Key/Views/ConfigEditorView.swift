import SwiftUI

let generalPadding: CGFloat = 8

struct AddButtons: View {
  let onAddAction: () -> Void
  let onAddGroup: () -> Void

  var body: some View {
    HStack(spacing: generalPadding) {
      Button(action: onAddAction) {
        Image(systemName: "rays")
        Text("Add action")
      }
      Button(action: onAddGroup) {
        Image(systemName: "folder")
        Text("Add group")
      }
      Spacer()
    }
  }
}

struct GroupContentView: View {
  @Binding var group: Group
  var isRoot: Bool = false

  var body: some View {
    VStack(spacing: generalPadding) {
      ForEach(group.actions.indices, id: \.self) { index in
        ActionOrGroupRow(
          item: binding(for: index),
          onDelete: { group.actions.remove(at: index) },
          onDuplicate: { group.actions.insert(group.actions[index], at: index) }
        )
        .id(index)
      }

      AddButtons(
        onAddAction: {
          withAnimation {
            group.actions.append(
              .action(Action(key: "", type: .application, value: "")))
          }
        },
        onAddGroup: {
          withAnimation {
            group.actions.append(.group(Group(key: "", actions: [])))
          }
        }
      )
      .padding(.top, generalPadding * 0.5)
    }
  }

  private func binding(for index: Int) -> Binding<ActionOrGroup> {
    Binding(
      get: { group.actions[index] },
      set: { group.actions[index] = $0 }
    )
  }
}

struct ConfigEditorView: View {
  @Binding var group: Group
  var isRoot: Bool = true

  var body: some View {
    ScrollView {
      GroupContentView(group: $group, isRoot: isRoot)
        .padding(
          EdgeInsets(
            top: generalPadding, leading: generalPadding,
            bottom: generalPadding, trailing: 0))
    }
  }
}

struct ActionOrGroupRow: View {
  @Binding var item: ActionOrGroup
  let onDelete: () -> Void
  let onDuplicate: () -> Void

  var body: some View {
    switch item {
    case .action:
      ActionRow(
        action: Binding(
          get: {
            if case .action(let action) = item { return action }
            fatalError("Unexpected state")
          },
          set: { newAction in
            item = .action(newAction)
          }
        ),
        onDelete: onDelete,
        onDuplicate: onDuplicate
      )
    case .group:
      GroupRow(
        group: Binding(
          get: {
            if case .group(let group) = item { return group }
            fatalError("Unexpected state")
          },
          set: { newGroup in
            item = .group(newGroup)
          }
        ),
        onDelete: onDelete,
        onDuplicate: onDuplicate
      )
    }
  }
}

struct ActionRow: View {
  @Binding var action: Action
  let onDelete: () -> Void
  let onDuplicate: () -> Void
  @FocusState private var isKeyFocused: Bool

  var body: some View {
    HStack(spacing: generalPadding) {
      KeyField(
        text: Binding(
          get: { action.key ?? "" },
          set: { action.key = $0 }
        ), placeholder: "Key")

      Picker("Type", selection: $action.type) {
        Text("Application").tag(Type.application)
        Text("URL").tag(Type.url)
        Text("Command").tag(Type.command)
        Text("Folder").tag(Type.folder)
      }
      .frame(width: 110)
      .labelsHidden()

      switch action.type {
      case .application:
        Button("Choose…") {
          let panel = NSOpenPanel()
          panel.allowedContentTypes = [.applicationBundle, .application]
          panel.canChooseFiles = true
          panel.canChooseDirectories = true
          panel.allowsMultipleSelection = false
          panel.directoryURL = URL(fileURLWithPath: "/Applications")

          if panel.runModal() == .OK {
            action.value = panel.url?.path ?? ""
          }
        }
        Text(action.value).truncationMode(.middle).lineLimit(1)
      case .folder:
        Button("Choose…") {
          let panel = NSOpenPanel()
          panel.allowsMultipleSelection = false
          panel.canChooseDirectories = true
          panel.canChooseFiles = false
          panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

          if panel.runModal() == .OK {
            action.value = panel.url?.path ?? ""
          }
        }
        Text(action.value).truncationMode(.middle).lineLimit(1)
      default:
        TextField("Value", text: $action.value)
      }

      Spacer()

      TextField(action.bestGuessDisplayName, text: $action.label ?? "").frame(
        width: 120
      )
      .padding(.trailing, generalPadding)

      Button(role: .none, action: onDuplicate) {
        Image(systemName: "document.on.document")
      }
      Button(role: .destructive, action: onDelete) {
        Image(systemName: "trash")
      }
      .padding(.trailing, generalPadding)
    }
  }
}

struct GroupRow: View {
  @Binding var group: Group
  @State private var isExpanded = true
  @FocusState private var isKeyFocused: Bool
  let onDelete: () -> Void
  let onDuplicate: () -> Void

  var body: some View {
    VStack(spacing: generalPadding) {
      HStack(spacing: generalPadding) {
        KeyField(
          text: Binding(
            get: { group.key ?? "" },
            set: { group.key = $0 }
          ),
          placeholder: "Group Key"
        )

        Image(systemName: "chevron.right")
          .rotationEffect(.degrees(isExpanded ? 90 : 0))
          .onTapGesture {
            withAnimation(.easeOut(duration: 0.1)) {
              isExpanded.toggle()
            }
          }
          .padding(.leading, generalPadding / 3)

        Spacer(minLength: 0)

        TextField("Label", text: $group.label ?? "").frame(width: 120)
          .padding(.trailing, generalPadding)

        Button(role: .none, action: onDuplicate) {
          Image(systemName: "document.on.document")
        }
        Button(role: .destructive, action: onDelete) {
          Image(systemName: "trash")
        }
        .padding(.trailing, generalPadding)
      }

      if isExpanded {
        HStack(spacing: 0) {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 1)
            .padding(.leading, generalPadding)
            .padding(.trailing, generalPadding / 3)

          GroupContentView(group: $group)
            .padding(.leading, generalPadding)
        }
      }
    }
    .padding(.horizontal, 0)
  }
}

#Preview {
  let group = Group(
    key: "",
    actions: [
      // Level 1 actions
      .action(
        Action(key: "t", type: .application, value: "/Applications/WezTerm.app")
      ),
      .action(
        Action(key: "f", type: .application, value: "/Applications/Firefox.app")
      ),

      // Level 1 group with actions
      .group(
        Group(
          key: "b",
          actions: [
            .action(
              Action(
                key: "c", type: .application,
                value: "/Applications/Google Chrome.app")),
            .action(
              Action(
                key: "s", type: .application, value: "/Applications/Safari.app")
            ),
          ])),

      // Level 1 group with subgroups
      .group(
        Group(
          key: "r",
          actions: [
            .action(
              Action(
                key: "e", type: .url,
                value:
                  "raycast://extensions/raycast/emoji-symbols/search-emoji-symbols"
              )),
            .group(
              Group(
                key: "w",
                actions: [
                  .action(
                    Action(
                      key: "f", type: .url,
                      value: "raycast://window-management/maximize")),
                  .action(
                    Action(
                      key: "h", type: .url,
                      value: "raycast://window-management/left-half")),
                ])),
          ])),
    ])

  ConfigEditorView(group: .constant(group))
    .frame(width: 600, height: 500)
}
