import Foundation

enum ATLAS_CONFIG {
    static let DATABASE_NAME = "training-record"
    static let PROGRAMS_COLLECTION = "programs"
    static let SESSIONS_COLLECTION = "sessions"

    // NOTE (temporary): Loaded from apps/mobile/.env → Generated/MONGODB_SECRETS.swift at build time.
    // .env is gitignored — never commit the URI. Prefer App Services before a public App Store release.
    // See docs/ATLAS_SETUP.md and apps/mobile/.env.example.
    static var MONGODB_URI: String {
        MONGODB_SECRETS.URI
    }

    static var isConfigured: Bool {
        !MONGODB_URI.isEmpty
    }
}
