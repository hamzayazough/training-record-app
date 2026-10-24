import Foundation
import MongoKitten

/// Syncs program/session documents to Atlas via a direct MongoDB connection.
///
/// NOTE: URI comes from gitignored `.env` (see docs/ATLAS_SETUP.md). Prefer App Services later.
actor AtlasProgramPersistence {
    private var database: MongoDatabase?

    var isEnabled: Bool { ATLAS_CONFIG.isConfigured }

    func loadSnapshot() async throws -> PersistedStoreSnapshot? {
        guard isEnabled else { return nil }
        let db = try await connect()
        let programs: [PersistedProgramState] = try await db[ATLAS_CONFIG.PROGRAMS_COLLECTION]
            .find()
            .decode(PersistedProgramState.self)
            .drain()
        guard !programs.isEmpty else { return nil }
        let sessions: [ScheduledSession] = try await db[ATLAS_CONFIG.SESSIONS_COLLECTION]
            .find()
            .decode(ScheduledSession.self)
            .drain()
        return PersistedStoreSnapshot(programs: programs, sessions: sessions)
    }

    func upsertProgram(_ program: PersistedProgramState) async throws {
        guard isEnabled else { return }
        let db = try await connect()
        try await db[ATLAS_CONFIG.PROGRAMS_COLLECTION].upsertEncoded(
            program,
            where: "programType" == program.programType.rawValue
        )
    }

    func upsertSession(_ session: ScheduledSession) async throws {
        guard isEnabled else { return }
        let db = try await connect()
        try await db[ATLAS_CONFIG.SESSIONS_COLLECTION].upsertEncoded(
            session,
            where: "id" == session.id
        )
    }

    func upsertSessions(_ sessions: [ScheduledSession]) async throws {
        guard isEnabled, !sessions.isEmpty else { return }
        let db = try await connect()
        let collection = db[ATLAS_CONFIG.SESSIONS_COLLECTION]
        for session in sessions {
            try await collection.upsertEncoded(session, where: "id" == session.id)
        }
    }

    /// Full replace — only for one-time bootstrap. Prefer `upsertSession` for edits.
    func saveSnapshot(_ snapshot: PersistedStoreSnapshot) async throws {
        guard isEnabled else { return }
        for program in snapshot.programs {
            try await upsertProgram(program)
        }
        try await upsertSessions(snapshot.sessions)
    }

    private func connect() async throws -> MongoDatabase {
        if let database { return database }
        let db = try await MongoDatabase.connect(to: ATLAS_CONFIG.MONGODB_URI)
        database = db
        return db
    }
}
