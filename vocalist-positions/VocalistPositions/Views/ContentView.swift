import SwiftUI

struct ContentView: View {
    @Bindable var viewModel: AppViewModel

    var body: some View {
        HSplitView {
            // Left sidebar: weekends + team members
            SidebarView(viewModel: viewModel)
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)

            // Center: vocalist columns
            VocalistGridView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Server status — click to copy address
                if let url = viewModel.displayServer.displayURL {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(url, forType: .string)
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text(url)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.accessoryBar)
                    .help("Click to copy address")
                }

                Spacer()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}
