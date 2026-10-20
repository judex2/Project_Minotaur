import PhotosUI
import SwiftUI

/// Quiet baseline capture shown right after joining a labyrinth.
struct BaselineCaptureView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let labyrinth: Labyrinth

    @State private var photo: PhotoRef?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    MonoLabel(text: "Your starting point", size: 10, color: Ink.faint, icon: "camera.metering.center.weighted")
                    Display(text: "Start your progress journal", size: 26)
                    Text("One photo, stored privately on this device. It stays hidden until you choose to pair it with a future progress post.")
                        .font(.system(size: 14))
                        .foregroundStyle(Ink.muted)
                        .lineSpacing(4)
                }

                if let photo {
                    MediaBox(ref: photo, height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(alignment: .bottomLeading) { Chip(text: "Baseline · Day 0", inverted: true).padding(10) }
                } else {
                    HStack(spacing: 8) {
                        Button {
                            Haptics.tap()
                            showCamera = true
                        } label: {
                            tile(icon: "camera", title: "Capture")
                        }
                        .buttonStyle(PressStyle())

                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            tile(icon: "photo.on.rectangle", title: "Library")
                        }
                        .buttonStyle(PressStyle())
                    }
                }

                Panel(padding: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Ink.text)
                        Text("Private by default. Nobody in \(labyrinth.name) can see this until you publish a paired update.")
                            .font(.system(size: 12))
                            .foregroundStyle(Ink.muted)
                    }
                }

                SlabButton(title: photo == nil ? "Skip for now" : "Store baseline", filled: photo != nil) {
                    state.setBaseline(photo, for: labyrinth)
                    state.baselinePrompt = nil
                    Haptics.success()
                    dismiss()
                }
                Color.clear.frame(height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 26)
        }
        .scrollIndicators(.hidden)
        .background(Ink.canvas)
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
            PhotoCaptureView(title: "Baseline Capture") { image in
                if let data = image.jpegData(compressionQuality: 0.7) { photo = .data(data) }
            }
        }
        .interactiveDismissDisabled()
    }

    private func tile(icon: String, title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .ultraLight))
                .foregroundStyle(Ink.text)
            MonoLabel(text: title, size: 9, color: Ink.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150)
        .background(Ink.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

/// Reusable full-screen camera sheet.
struct PhotoCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onCapture: (UIImage) -> Void

    @State private var camera = CameraService()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch camera.status {
            case .ready:
                CameraPreview(box: camera.box)
                    .ignoresSafeArea()
                    .overlay { grid }
            case .denied:
                message(icon: "camera.badge.ellipsis",
                        title: "Camera access off",
                        body: "Enable camera access in Settings to capture directly, or pick an image from your library instead.")
            case .unavailable:
                message(icon: "camera.metering.unknown",
                        title: "No camera found",
                        body: "This device has no available capture device. Use the library option instead.")
            case .idle:
                ProgressView().tint(.white)
            }

            VStack {
                HStack {
                    Button {
                        Haptics.soft()
                        camera.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    Spacer()
                    MonoLabel(text: title, size: 10, color: .white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)

                Spacer()

                if camera.status == .ready {
                    Button {
                        Haptics.tap()
                        camera.capture()
                    } label: {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 3)
                            .frame(width: 74, height: 74)
                            .overlay { Circle().fill(Color.white).frame(width: 60, height: 60) }
                    }
                    .buttonStyle(PressStyle())
                    .padding(.bottom, 34)
                }
            }
        }
        .task { await camera.start() }
        .onChange(of: camera.captured) { _, image in
            guard let image else { return }
            onCapture(image)
            camera.stop()
            dismiss()
        }
    }

    private var grid: some View {
        GeometryReader { geo in
            Path { path in
                for index in 1...2 {
                    let x = geo.size.width / 3 * CGFloat(index)
                    let y = geo.size.height / 3 * CGFloat(index)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
            }
            .stroke(Color.white.opacity(0.18), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }

    private func message(icon: String, title: String, body: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundStyle(.white)
            Display(text: title, size: 20, color: .white)
            Text(body)
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundStyle(Ink.muted)
        }
        .padding(32)
    }
}
