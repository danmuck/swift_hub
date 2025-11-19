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
    var salaryEstimate: String?
    var notes: [JobNote]
    var tasks: [JobTask]
    var links: [JobLink]
    var documents: [JobDocument]

    init(id: UUID = UUID(), title: String, company: String, contact: String? = nil, status: JobStatus = .applied, location: String? = nil, salaryRange: String? = nil, dateCreated: Date = .now) {
        self.id = id
        self.title = title
        self.company = company
        self.contact = contact
        self.status = status
        self.location = location
        self.salaryEstimate = salaryRange
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

