//
//  LinkSection.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftData
import SwiftUI

struct LinkSection: View {
    @Environment(\.modelContext) private var context
    @Binding var job: Job
    @State private var title = ""
    @State private var urlString = ""

    var body: some View {
        VStack {
            List {
                ForEach(job.links) { link in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(link.title)
                            Text(link.url.absoluteString).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Link(destination: link.url) { Image(systemName: "arrow.up.right.square") }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(link) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            HStack {
                TextField("Title", text: $title)
                TextField("URL", text: $urlString)
                    .textCase(nil)
                Button { addLink() } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }

    private func addLink() {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: s), !t.isEmpty else { return }
        let link = JobLink(title: t, url: url)
        job.links.append(link)
        context.insert(link)
        try? context.save()
        title = ""
        urlString = ""
    }

    private func delete(_ link: JobLink) {
        if let idx = job.links.firstIndex(where: { $0.id == link.id }) { job.links.remove(at: idx) }
        context.delete(link)
        try? context.save()
    }
}

#Preview {
    @Previewable @State var job = Job(title: "Sample Job", company: "Testing Inc.")
    LinkSection(job: $job)
        .modelContainer(for: Job.self, inMemory: true)
}
