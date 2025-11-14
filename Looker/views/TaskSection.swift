//
//  TaskSection.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import SwiftUI
import SwiftData

struct TaskSection: View {
    @Environment(\.modelContext) private var context
    @Binding var job: Job
    @State private var newTask = ""
    @State private var dueDate: Date? = nil

    var body: some View {
        VStack {
            List {
                ForEach(job.tasks) { task in
                    HStack {
                        Button { toggle(task) } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        .buttonStyle(.plain)
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .strikethrough(task.isCompleted)
                            if let d = task.dueDate {
                                Text(d, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { delete(task) } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            HStack {
                TextField("New task", text: $newTask)
                Menu {
                    Button("No due date") { dueDate = nil }
                    DatePicker("Due date", selection: Binding(get: { dueDate ?? Date() }, set: { dueDate = $0 }), displayedComponents: .date)
                } label: { Image(systemName: "calendar") }
                Button { addTask() } label: { Image(systemName: "plus.circle.fill") }
                    .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }

    private func addTask() {
        let title = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let task = JobTask(title: title, dueDate: dueDate)
        job.tasks.append(task)
        context.insert(task)
        try? context.save()
        newTask = ""
        dueDate = nil
    }

    private func toggle(_ task: JobTask) {
        task.isCompleted.toggle()
        try? context.save()
    }

    private func delete(_ task: JobTask) {
        if let idx = job.tasks.firstIndex(where: { $0.id == task.id }) { job.tasks.remove(at: idx) }
        context.delete(task)
        try? context.save()
    }
}


#Preview {
    @Previewable @State var job = Job(title: "Sample Job", company: "Testing Inc.")
    TaskSection(job: $job)
        .modelContainer(for: Job.self, inMemory: true)
}
