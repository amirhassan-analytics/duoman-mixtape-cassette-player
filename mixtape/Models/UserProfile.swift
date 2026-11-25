//
//  UserProfile.swift
//  mixtape
//
//  Created by ManoveKumar on 06/11/2026.
//


import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var displayName: String
    var username: String
    var profileImageURL: String?
    var bio: String?
    var createdAt: Date = Date()
}
