//
//  User.swift
//  dps_hub
//
//  Created by Daniel Muck on 11/11/25.
//

import SwiftData
import Foundation


// User
//  - id (unique)
//  - email
//  - username
//  - first name
//  - last name
//  - data
//
@Model
final class User: Identifiable {
    @Attribute(.unique) var id: UUID
    var email: String
    var username: String
    var firstName: String
    var lastName: String
    var documents: [JobDocument]
    var jobs: [Job]
    
    init(id: UUID = UUID(), username: String, email: String, firstName: String, lastName: String) {
        self.id = id
        self.email = email
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.documents = []
        self.jobs = []
    }
}
