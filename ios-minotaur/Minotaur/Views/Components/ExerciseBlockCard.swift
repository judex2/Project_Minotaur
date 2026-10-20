import SwiftUI

struct ExerciseBlockCard: View {
    let block: ExerciseBlock
    let position: Int
    let canMoveUp: Bool
    let canMoveDown: Bool
    var fill: Color = Ink.surface
    var edit: () -> Void
    var moveUp: () -> Void
    var moveDown: () -> Void
    var remove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: edit) {
                HStack(alignment: .top, spacing: 12) {
                    Text("\(position)").font(.subheadline.bold()).foregroundStyle(Ink.blue)
                        .frame(width: 28, height: 28).background(Ink.blueWash, in: RoutePanelShape(cut: 5))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(block.name).font(.headline).foregroundStyle(Ink.text)
                        Text(block.summary).font(.subheadline).foregroundStyle(Ink.muted)
                        Text("Edit exercise").font(.caption.weight(.medium)).foregroundStyle(Ink.blue)
                    }
                    Spacer(minLength: 0)
                }.frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(PressStyle())
            Menu {
                Button("Edit exercise", systemImage: "pencil", action: edit)
                Button("Move up", systemImage: "arrow.up", action: moveUp).disabled(!canMoveUp)
                Button("Move down", systemImage: "arrow.down", action: moveDown).disabled(!canMoveDown)
                Button("Remove exercise", systemImage: "trash", role: .destructive, action: remove)
            } label: { Image(systemName: "ellipsis").frame(width: 44, height: 44) }
                .accessibilityLabel("Options for \(block.name)")
        }.padding(16).modifier(RouteSurface(fill: fill))
    }
}
