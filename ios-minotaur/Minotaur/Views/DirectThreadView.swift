import SwiftUI

/// Simple one-to-one thread with the labyrinth owner.
struct DirectThreadView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let labyrinth: Labyrinth
    @State private var draft: String = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        MonoLabel(text: "Private thread preview · stored only on this device",
                                  size: 9,
                                  color: Ink.faint,
                                  icon: "lock")
                            .padding(.vertical, 10)
                        ForEach(state.thread(for: labyrinth)) { message in
                            bubble(message).id(message.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                .onChange(of: state.thread(for: labyrinth).count) { _, _ in
                    if let last = state.thread(for: labyrinth).last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            composer
        }
        .background(Ink.canvas)
    }

    private var header: some View {
        HStack(spacing: 12) {
            MediaBox(ref: labyrinth.ownerAvatar, height: 38)
                .frame(width: 38)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 3) {
                Text(labyrinth.ownerName)
                    .font(.system(size: 14, weight: .black))
                    .tracking(1)
                    .foregroundStyle(Ink.text)
                MonoLabel(text: labyrinth.ownerHandle, size: 9, color: Ink.faint)
            }
            Spacer()
            Button {
                Haptics.soft()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Ink.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Ink.canvas)
        .overlay(alignment: .bottom) { Rectangle().fill(Ink.hairline).frame(height: 1) }
    }

    private func bubble(_ message: DirectMessage) -> some View {
        HStack {
            if message.fromMe { Spacer(minLength: 50) }
            VStack(alignment: message.fromMe ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 14))
                    .foregroundStyle(message.fromMe ? .white : Ink.text)
                    .lineSpacing(3)
                MonoLabel(text: message.sentAt.shortAgo,
                          size: 8,
                          color: message.fromMe ? .white.opacity(0.85) : Ink.faint)
            }
            .padding(14)
            .background(message.fromMe ? Ink.blue : Ink.surface, in: RoundedRectangle(cornerRadius: 18))

            if !message.fromMe { Spacer(minLength: 50) }
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Ink.hairline).frame(height: 1)
            HStack(spacing: 10) {
                TextField("", text: $draft, prompt: Text("Write a message…")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Ink.faint), axis: .vertical)
                    .font(.system(size: 14))
                    .foregroundStyle(Ink.text)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Ink.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Button {
                    let value = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !value.isEmpty else { return }
                    Haptics.tap()
                    state.send(value, in: labyrinth)
                    draft = ""
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Ink.signal, in: Circle())
                }
                .buttonStyle(PressStyle()).accessibilityLabel("Send message")
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(16)
        }
        .background(Ink.canvas)
    }
}
