//
//  NotesSection.swift
//  swift_hub
//
//  Created by Daniel Muck on 11/18/25.
//


import SwiftUI
import SwiftData

struct NotesSection: View {
    @Environment(\.modelContext) private var context
    @Binding var job: Job
    @State private var newNote = ""

    var body: some View {
        VStack {
            List {
                ForEach(job.notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.text)
                        Text(note.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(note) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            HStack {
                TextField("Add a note", text: $newNote)
                Button { addNote() } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(newNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }

    private func addNote() {
        let text = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let note = JobNote(text: text)
        job.notes.insert(note, at: 0)
        context.insert(note)
        try? context.save()
        newNote = ""
    }

    private func delete(_ note: JobNote) {
        if let idx = job.notes.firstIndex(where: { $0.id == note.id }) { job.notes.remove(at: idx) }
        context.delete(note)
        try? context.save()
    }
}
