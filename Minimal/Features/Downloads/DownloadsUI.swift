import SwiftUI

struct DownloadRowView: View {
    @ObservedObject var task: DownloadTask
    var onCancel: () -> Void
    var onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.filename)
                    .font(.headline)
                Text(task.url.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if !task.isFinished {
                    ProgressView(value: task.progress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: .infinity)
                    Text("\(Int(task.progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if task.isFinished {
                Text("Finished")
                    .foregroundColor(.green)
            } else {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
    }
}

struct DownloadsListView: View {
    @ObservedObject var manager: DownloadManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedTask: DownloadTask?
    
    var body: some View {
        NavigationStack {
            List(manager.tasks) { task in
                DownloadRowView(
                    task: task,
                    onCancel: { manager.cancelTask(task) },
                    onSelect: { selectedTask = task }
                )
            }
            .navigationTitle("Downloads")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                DownloadDetailView(task: task)
            }
            .overlay {
                if manager.tasks.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Active Downloads")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct DownloadDetailView: View {
    @ObservedObject var task: DownloadTask
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(task.filename)
                    .font(.headline)
                Spacer()
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            if !task.isFinished {
                VStack(spacing: 4) {
                    ProgressView(value: task.progress)
                        .progressViewStyle(.linear)
                    Text("\(Int(task.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    Text(task.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("bottom")
                }
                .onChange(of: task.output) { newValue in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            
            Divider()
            
            HStack {
                if !task.isFinished {
                    Button("Cancel Download") {
                        task.cancel()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Text("Download Finished")
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
