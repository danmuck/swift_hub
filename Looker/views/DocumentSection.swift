//
//  DocumentSection.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftUI
import SwiftData

struct DocumentSection: View {
    @Binding var job: Job

    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView("Documents", systemImage: "doc", description: Text("We'll add import and storage next."))
            List(job.documents) { doc in
                HStack {
                    Image(systemName: "doc.text")
                    VStack(alignment: .leading) {
                        Text(doc.name)
                        Text(doc.addedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button { /* placeholder for importer */ } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 24))
                }
                .padding()
            }
        }
    }
}

#Preview {
    @Previewable @State var job = Job(title: "Sample Job", company: "Testing Inc.")
    DocumentSection(job: $job)
        .modelContainer(for: Job.self, inMemory: true)
}
