import Foundation

enum APIError: Error {
    case invalidURL
    case badResponse
    case decodingFailed
}

final class TrainingAPIClient {
    static let SHARED = TrainingAPIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func fetchPrograms() async throws -> [ProgramSummary] {
        try await get("/programs")
    }

    func fetchCalendar(type: PROGRAM_TYPE, days: Int = API_CONFIG.HOME_CALENDAR_DAYS) async throws -> [DayRecord] {
        let from = DayRecord.todayIso()
        return try await get("/programs/\(type.rawValue)/calendar?from=\(from)&days=\(days)")
    }

    func fetchDetail(type: PROGRAM_TYPE) async throws -> [DayRecord] {
        try await get("/programs/\(type.rawValue)/detail")
    }

    func completeExercise(id: String) async throws -> CompleteExerciseResponse {
        try await post("/exercises/\(id)/complete", body: Optional<String>.none)
    }

    func submitFeedback(id: String, request: FeedbackRequest) async throws -> ScheduledExercise {
        try await post("/exercises/\(id)/feedback", body: request)
    }

    func moveSession(id: String, request: MoveSessionRequest) async throws -> ScheduledSession {
        try await patch("/sessions/\(id)/move", body: request)
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let request = try makeRequest(path: path, method: "GET")
        return try await send(request)
    }

    private func post<Body: Encodable, T: Decodable>(_ path: String, body: Body?) async throws -> T {
        var request = try makeRequest(path: path, method: "POST")
        if let body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return try await send(request)
    }

    private func patch<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        var request = try makeRequest(path: path, method: "PATCH")
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await send(request)
    }

    private func makeRequest(path: String, method: String) throws -> URLRequest {
        guard let url = URL(string: API_CONFIG.BASE_URL + path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.badResponse
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}
