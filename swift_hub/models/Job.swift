//
//  Job.swift
//  Looker
//
//  Created by Daniel Muck on 11/9/25.
//

import Foundation
import SwiftData
import SwiftUI

enum JobStatus: String, Codable, CaseIterable {
    case docket
    case research
    case applied
    case contacted
    case interviewing
    case offer
    case rejected
    case withdrawn

    var color: Color {
        switch self {
        case .docket:
            return Color.gray
        case .research:
            return Color.indigo
        case .applied:
            return Color.blue
        case .contacted:
            return Color.teal
        case .interviewing:
            return Color.orange
        case .offer:
            return Color.green
        case .rejected:
            return Color.red
        case .withdrawn:
            return Color.brown
        }
    }

    // An optional contrasting color you might use for text or accents
    var accentColor: Color {
        switch self {
        case .docket, .research:
            return Color.white
        case .applied, .contacted, .interviewing:
            return Color.white
        case .offer:
            return Color.white
        case .rejected:
            return Color.white
        case .withdrawn:
            return Color.white
        }
    }
    
    var displayName: String {
        switch self {
        case .docket: return "Docket"
        case .research: return "Research"
        case .applied: return "Applied"
        case .contacted: return "Contacted"
        case .interviewing: return "Interviewing"
        case .offer: return "Offer"
        case .rejected: return "Rejected"
        case .withdrawn: return "Withdrawn"
        }
    }
}


@Model
final class Job: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var company: String
    var contact: String?
    var dateCreated: Date
    var status: JobStatus
    var location: String?
    var salaryK: Int?
    var notes: [JobNote]
    var tasks: [JobTask]
    var links: [JobLink]
    var documents: [JobDocument]
    
    // Computed: salary in whole dollars (e.g., 60 -> 60000)
    var salaryInDollars: Int? {
        guard let salaryK else { return nil }
        return salaryK * 1000
    }

    // Computed: a display string like "$60k" or "—"
    var salaryDisplay: String {
        if let salaryK { return "\u{0024}\(salaryK)k" } // $60k
        return "—"
    }

    // Computed: open (incomplete) tasks count
    var openTasksCount: Int {
        tasks.filter { !$0.isCompleted }.count
    }

    // Bucketed salary range for grouping
    enum SalaryBucket: String, Codable, CaseIterable, Comparable {
        case under50 = "Under 50k"
        case from50to75 = "50k–75k"
        case from75to100 = "75k–100k"
        case from100to150 = "100k–150k"
        case above150 = "150k+"

        static func < (lhs: SalaryBucket, rhs: SalaryBucket) -> Bool {
            let order: [SalaryBucket] = [.under50, .from50to75, .from75to100, .from100to150, .above150]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }

    var salaryBucket: SalaryBucket? {
        guard let k = salaryK else { return nil }
        switch k {
        case ..<50: return .under50
        case 50..<75: return .from50to75
        case 75..<100: return .from75to100
        case 100..<150: return .from100to150
        default: return .above150
        }
    }

    // Common sort keys
    enum SortKey {
        case status
        case salaryDescending
        case salaryAscending
        case openTasksDescending
        case dateCreatedDescending
    }

    static func sort(_ key: SortKey) -> (Job, Job) -> Bool {
        switch key {
        case .status:
            // Keep JobStatus order as declared in CaseIterable
            let order = Array(JobStatus.allCases.enumerated()).reduce(into: [JobStatus:Int]()) { dict, pair in
                dict[pair.element] = pair.offset
            }
            return { a, b in
                (order[a.status] ?? 0) < (order[b.status] ?? 0)
            }
        case .salaryDescending:
            return { (a, b) in
                (a.salaryK ?? Int.min) > (b.salaryK ?? Int.min)
            }
        case .salaryAscending:
            return { (a, b) in
                (a.salaryK ?? Int.max) < (b.salaryK ?? Int.max)
            }
        case .openTasksDescending:
            return { (a, b) in
                a.openTasksCount > b.openTasksCount
            }
        case .dateCreatedDescending:
            return { (a, b) in
                a.dateCreated > b.dateCreated
            }
        }
    }

    // Grouping helpers
    static func groupByStatus(jobs: [Job]) -> [(status: JobStatus, jobs: [Job])] {
        let grouped = Dictionary(grouping: jobs, by: { $0.status })
        let ordered = JobStatus.allCases
            .compactMap { status -> (JobStatus, [Job])? in
                guard let items = grouped[status] else { return nil }
                return (status, items)
            }
        return ordered.map { (status: $0.0, jobs: $0.1) }
    }

    static func groupBySalaryBucket(jobs: [Job]) -> [(bucket: SalaryBucket, jobs: [Job])] {
        let grouped = Dictionary(grouping: jobs.compactMap { job -> (SalaryBucket, Job)? in
            guard let bucket = job.salaryBucket else { return nil }
            return (bucket, job)
        }, by: { $0.0 })
        .mapValues { $0.map { $0.1 } }

        return SalaryBucket.allCases
            .compactMap { bucket -> (SalaryBucket, [Job])? in
                guard let items = grouped[bucket] else { return nil }
                return (bucket, items)
            }
            .sorted { $0.0 < $1.0 }
    }

    init(id: UUID = UUID(), title: String, company: String, contact: String? = nil, status: JobStatus = .applied, location: String? = nil, salaryK: Int? = nil, dateCreated: Date = .now) {
        self.id = id
        self.title = title
        self.company = company
        self.contact = contact
        self.status = status
        self.location = location
        self.salaryK = salaryK
        self.dateCreated = dateCreated
        self.notes = []
        self.tasks = []
        self.links = []
        self.documents = []
    }
}

@Model
final class JobNote: Identifiable {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var text: String

    init(id: UUID = UUID(), text: String, createdAt: Date = .now) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
    }
}

@Model
final class JobTask: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var dueDate: Date?
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, dueDate: Date? = nil, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
    }
}

// maybe if string contains linkedin/github/etc, display icon
@Model
final class JobLink: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var url: URL

    init(id: UUID = UUID(), title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }
}

@Model
final class JobDocument: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var filePath: String
    var addedAt: Date
    var mutable: Bool = false

    init(id: UUID = UUID(), name: String, filePath: String, addedAt: Date = .now) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.addedAt = addedAt
    }
}

// Note: For file storage, this model stores a relative filePath into your app's documents directory. You can manage import/export via FileImporter and move files into app sandbox.

