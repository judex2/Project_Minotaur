import PhotosUI
import SwiftUI

/// Post composer with the progress-pairing flow.
struct ComposePostView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let labyrinth: Labyrinth
    var prefill: String = ""
    var initialTag: PostTag = .update

    @State private var initialized = false
    @State private var text: String = ""
    @State private var tag: PostTag = .update
    @State private var photo: PhotoRef?
    @State private var sharePublicly = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    private var baseline: PhotoRef? { state.membership(for: labyrinth)?.baseline }
    private var daysIn: Int { state.membership(for: labyrinth)?.daysIn ?? 1 }
    private var willPair: Bool { tag == .progress && photo != nil && baseline != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                editor
                tagPicker
                photoSection
                if photo != nil { pairingSection }
                SlabButton(title: "Post to community") {
                    state.addPost(to: labyrinth,
                                  text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                                  tag: tag,
                                  photo: photo,
                                  sharePublicly: sharePublicly)
                    Haptics.success()
                    dismiss()
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                Color.clear.frame(height: 30)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
        }
        .scrollIndicators(.hidden)
        .background(Ink.canvas)
        .onAppear { if !initialized { text = prefill; tag = initialTag; initialized = true } }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let compressed = UIImage(data: data)?.jpegData(compressionQuality: 0.7) {
                    photo = .data(compressed)
                    Haptics.soft()
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            PhotoCaptureView(title: "Progress Capture") { image in
                if let data = image.jpegData(compressionQuality: 0.7) { photo = .data(data) }
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                MonoLabel(text: labyrinth.name, size: 9, color: Ink.faint)
                Display(text: "Share an update", size: 24)
            }
            Spacer()
            Button {
                Haptics.soft()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Ink.muted)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }

    private var editor: some View {
        Panel(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                MonoLabel(text: "Message", size: 9, color: Ink.faint)
                TextEditor(text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(Ink.text)
                    .scrollContentBackground(.hidden)
                    .frame(height: 120)
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Log an update, a question, or a win…")
                                .font(.system(size: 15))
                                .foregroundStyle(Ink.faint)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }

    private var tagPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoLabel(text: "Tag", size: 9, color: Ink.faint)
            HStack(spacing: 8) {
                ForEach([PostTag.update, .question, .progress], id: \.self) { item in
                    Button {
                        Haptics.soft()
                        withAnimation(.easeOut(duration: 0.15)) { tag = item }
                    } label: {
                        Text(item.label)
                            .font(.subheadline.weight(.semibold))

                            .foregroundStyle(tag == item ? .white : Ink.muted)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(tag == item ? Ink.signal : Ink.raised, in: Capsule())

                    }
                    .buttonStyle(PressStyle())
                }
                Spacer()
            }
            if tag == .question {
                MonoLabel(text: "Flagged for \(labyrinth.ownerHandle)", size: 9, color: Ink.faint, icon: "questionmark.circle")
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            MonoLabel(text: "Attachment", size: 9, color: Ink.faint)
            if let photo {
                MediaBox(ref: photo, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            Haptics.soft()
                            self.photo = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 30, height: 30)
                                .background(Color.white)
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
            } else {
                HStack(spacing: 8) {
                    Button {
                        Haptics.tap()
                        showCamera = true
                    } label: {
                        attachTile(icon: "camera", title: "Camera")
                    }
                    .buttonStyle(PressStyle())

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        attachTile(icon: "photo.on.rectangle", title: "Library")
                    }
                    .buttonStyle(PressStyle())
                }
            }
        }
    }

    private func attachTile(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Ink.text)
            MonoLabel(text: title, size: 9, color: Ink.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 96)
        .background(Ink.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var pairingSection: some View {
        Panel(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        MonoLabel(text: "Share publicly", size: 10, color: Ink.text)
                        Text(labyrinth.isPublic ? "Allow this photo to appear in discovery, outside this community. Off by default." : "This is a private Labyrinth. Your post stays inside its community.")
                            .font(.system(size: 12))
                            .foregroundStyle(Ink.faint)
                    }
                    Spacer()
                    Toggle("Allow public discovery", isOn: $sharePublicly)
                        .labelsHidden()
                        .tint(Ink.signal)
                        .disabled(!labyrinth.isPublic)
                }

                if willPair, let baseline, let photo {
                    HStack(spacing: 2) {
                        MediaBox(ref: baseline, height: 150)
                            .overlay(alignment: .bottomLeading) { Chip(text: "Baseline").padding(6) }
                        MediaBox(ref: photo, height: 150)
                            .overlay(alignment: .bottomLeading) { Chip(text: "Day \(daysIn)", inverted: true).padding(6) }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    MonoLabel(text: "\(daysIn) days inside this labyrinth", size: 9, color: Ink.faint, icon: "calendar")
                }
            }
        }
    }
}
