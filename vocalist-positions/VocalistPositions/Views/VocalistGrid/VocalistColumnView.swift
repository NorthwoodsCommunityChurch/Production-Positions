import SwiftUI
import UniformTypeIdentifiers

struct VocalistColumnView: View {
    let position: VocalistPosition
    let assignment: VocalistAssignment?
    @Bindable var viewModel: AppViewModel

    @State private var labelText: String = ""
    @State private var isDropTargeted = false
    @State private var showingPhotoImporter = false

    var body: some View {
        VStack(spacing: 0) {
            // Angle photo
            anglePhotoSection
                .frame(height: 140)
                .clipped()

            Divider()

            // Vocalist number + label
            VStack(spacing: 4) {
                Text("VOX \(position.number)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.accentColor)

                TextField("Label", text: $labelText)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        viewModel.updateVocalistPositionLabel(position.id, label: labelText.isEmpty ? nil : labelText)
                    }
            }
            .padding(.vertical, 8)

            Divider()

            // Operator display
            operatorSection
                .padding(8)

            Spacer(minLength: 0)

            // Remove button
            Button(role: .destructive) {
                viewModel.removeVocalistPosition(position.id)
            } label: {
                Image(systemName: "minus.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.bottom, 8)
        }
        .frame(width: 180)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isDropTargeted ? Color.accentColor : Color(nsColor: .separatorColor),
                    lineWidth: isDropTargeted ? 2 : 1
                )
        )
        .dropDestination(for: String.self) { items, _ in
            guard let name = items.first else { return false }
            viewModel.assignOperator(to: position.id, name: name)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
        .onAppear {
            labelText = position.label ?? ""
        }
        .fileImporter(isPresented: $showingPhotoImporter, allowedContentTypes: [.image]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url) {
                        viewModel.setVocalistAnglePhoto(position.id, imageData: data)
                    }
                }
            }
        }
    }

    // MARK: - Angle Photo

    @ViewBuilder
    private var anglePhotoSection: some View {
        if let filename = position.anglePhotoFilename,
           let data = viewModel.imageStorage.loadImage(filename: filename),
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .onTapGesture { showingPhotoImporter = true }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Set Photo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .controlColor))
            .onTapGesture { showingPhotoImporter = true }
        }
    }

    // MARK: - Operator Section

    private var operatorSection: some View {
        VStack(spacing: 4) {
            if let name = assignment?.operatorName {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Button {
                        viewModel.removeOperator(from: position.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .foregroundStyle(.secondary)
                    Text("Drop Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            Color(nsColor: .separatorColor),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                        )
                )
            }
        }
    }
}
