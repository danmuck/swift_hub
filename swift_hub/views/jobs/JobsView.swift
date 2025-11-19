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
    @State private var salary: Int? = nil

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
            salaryK: salary
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
            Picker("", selection: $tab) {
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
                case .documents: DocSection(job: $job)
                }
            }
        }
        .navigationTitle(job.title)
        .onChange(of: job) { _, _ in try? context.save() }
    }
}

private struct OverviewSection: View {
    @Binding var job: Job
    @State private var isEditing = false

    var body: some View {
        Form {

            Section {
                TextField("Title", text: Binding(get: { job.title }, set: { job.title = $0 }))
                TextField("Company", text: Binding(get: { job.company }, set: { job.company = $0 }))
                Picker("Status", selection: Binding(get: { job.status }, set: { job.status = $0 })) {
                    ForEach(JobStatus.allCases, id: \.self) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                TextField("Location", text: Binding(get: { job.location ?? "" }, set: { job.location = $0.isEmpty ? nil : $0 }))
                TextField(
                    "Salary",
                    value: Binding<Double?>(
                        get: {
                            if let k = job.salaryK { return Double(k) * 1000 } else { return nil }
                        },
                        set: { newValue in
                            if let dollars = newValue {
                                let thousands = Int((dollars / 1000).rounded())
                                job.salaryK = max(thousands, 0)
                            } else {
                                job.salaryK = nil
                            }
                        }
                    ),
                    format: .currency(code: Locale.current.currency?.identifier ?? "USD")
                )
            } header: {
//                HStack {
//                    Text("Position")
//                    Spacer()
//
//                }
            }
            .disabled(!isEditing)
            HStack {
                Spacer()
                Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
                    .buttonStyle(.borderless)
            }
        }
        .formStyle(.grouped)
    }
}


#Preview {
    JobsView()
        .modelContainer(for: Job.self, inMemory: true)
}

