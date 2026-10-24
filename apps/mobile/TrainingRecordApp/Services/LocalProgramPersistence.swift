import Foundation

actor LocalProgramPersistence {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = folder.appendingPathComponent("TrainingRecord", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("store.json")
    }

    func load() throws -> PersistedStoreSnapshot? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(PersistedStoreSnapshot.self, from: data)
    }

    func save(_ snapshot: PersistedStoreSnapshot) throws {
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}
