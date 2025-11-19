import SwiftUI
import SwiftData

struct JobsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Job.dateCreated, order: .reverse)]) private var jobs: [Job]
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if jobs.isEmpty {
                    ContentUnavailableView("No Jobs Yet", systemImage: "tray", description: Text("Tap + to add your first job."))
                } else {
                    List {
                        ForEach(jobs) { job in
                            NavigationLink(value: job.id) {
                                JobRow(job: job)
                            }
                            .contextMenu {
                                Button(role: .destructive) { delete(job) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Applications")
            .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAdd = true } label: { Label("Add", systemImage: "plus") }
            }
        }
            .sheet(isPresented: $showingAdd) {
                AddJobView()
                    .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: UUID.self) { id in
                if let job = jobs.first(where: { $0.id == id }) {
                    JobDetailView(job: job)
                } else {
                    Text("Job not found")
                }
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(jobs[index]) }
        try? context.save()
    }

    private func delete(_ job: Job) {
        context.delete(job)
        try? context.save()
    }
}

struct JobRow: View {
    let job: Job

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(job.title).font(.headline)
                Text(job.company).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(job.status.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(job.status.accentColor)
                .background(job.status.color, in: Capsule())
        }
    }
}

struct AddJobView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var company = ""
    @State private var linkString = ""
    @State private var status: JobStatus = .applied
    @State private var location = ""
    @State private var salary: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    TextField("Job Title", text: $title)
                    TextField("Company", text: $company)
                    Picker("Status", selection: $status) {
                        ForEach(JobStatus.allCases, id: \.self) { s in
                            Text(s.displayName).tag(s)
                        }
                    }
                    TextField("Location", text: $location)
                    TextField("Listing Link", text: $linkString)
                }
            }
            .navigationTitle("New Job")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { add() }.disabled(title.isEmpty || company.isEmpty) }
            }
        }
    }

    private func add() {
        let job = Job(
            title: title,
            company: company,
            status: status,
            location: location.isEmpty ? nil : location,
            salaryRange: salary
        )
        context.insert(job)
        try? context.save()
        dismiss()
    }
}

struct JobDetailView: View {
    @Environment(\.modelContext) private var context
    @State var job: Job
    @State private var tab: Tab = .overview

    enum Tab: String, CaseIterable, Identifiable { case overview, notes, tasks, links, documents; var id: String { rawValue } }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases) { t in Text(t.rawValue.capitalized).tag(t) }
            }
            .pickerStyle(.segmented)
            .padding()

            Group {
                switch tab {
                case .overview: OverviewSection(job: $job)
                case .notes: NotesSection(job: $job)
                case .tasks: TasksSection(job: $job)
                case .links: LinksSection(job: $job)
                case .documents: DocumentsSection(job: $job)
                }
            }
        }
        .navigationTitle(job.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: job) { _, _ in try? context.save() }
    }
}

private struct OverviewSection: View {
    @Binding var job: Job

    var body: some View {
        Form {
            Section("Position") {
                TextField("Title", text: Binding(get: { job.title }, set: { job.title = $0 }))
                TextField("Company", text: Binding(get: { job.company }, set: { job.company = $0 }))
                Picker("Status", selection: Binding(get: { job.status }, set: { job.status = $0 })) {
                    ForEach(JobStatus.allCases, id: \.self) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                TextField("Location", text: Binding(get: { job.location ?? "" }, set: { job.location = $0.isEmpty ? nil : $0 }))
                TextField("Salary Range", text: Binding(get: { job.salaryEstimate ?? "" }, set: { job.salaryEstimate = $0.isEmpty ? nil : $0 }))
            }
        }
    }
}

private struct NotesSection: View {
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

private struct TasksSection: View {
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

private struct LinksSection: View {
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

private struct DocumentsSection: View {
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
                    Image(systemName: "plus.circle.fill").font(.system(size: 44))
                }
                .padding()
            }
        }
    }
}

#Preview {
    JobsView()
        .modelContainer(for: Job.self, inMemory: true)
}
