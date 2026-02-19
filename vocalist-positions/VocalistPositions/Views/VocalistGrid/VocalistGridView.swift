import SwiftUI

struct VocalistGridView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with add button
            HStack {
                Text("Vocalist Positions")
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    viewModel.addVocalistPosition()
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .font(.title3)
                .help("Add vocalist position")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Vocalist columns
            if viewModel.vocalistPositions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mic")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No vocalist positions")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Click + to add vocalist positions")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(viewModel.vocalistPositions) { position in
                            VocalistColumnView(
                                position: position,
                                assignment: viewModel.workingAssignments.first { $0.vocalistPositionId == position.id },
                                viewModel: viewModel
                            )
                        }
                    }
                    .padding(16)
                }
            }
        }
    }
}
