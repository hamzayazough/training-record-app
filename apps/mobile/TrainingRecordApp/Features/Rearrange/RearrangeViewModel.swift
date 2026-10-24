import Foundation
import CoreTransferable

@MainActor
final class RearrangeViewModel: ObservableObject {
    @Published var trainings: [RearrangeTraining] = []
    @Published var weekDays: [RearrangeWeekDay] = []
    @Published var assignmentByDayNumber: [Int: WEEKDAY] = [:]
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didSave = false
    @Published var draggingDayNumber: Int?

    let programType: PROGRAM_TYPE
    private let api: TrainingAPIClient

    init(programType: PROGRAM_TYPE, api: TrainingAPIClient = .SHARED) {
        self.programType = programType
        self.api = api
    }

    var unassignedTrainings: [RearrangeTraining] {
        trainings.filter { assignmentByDayNumber[$0.dayNumber] == nil }
    }

    func trainings(for weekday: WEEKDAY) -> [RearrangeTraining] {
        trainings.filter { assignmentByDayNumber[$0.dayNumber] == weekday }
    }

    func beginDrag(_ dayNumber: Int) {
        draggingDayNumber = dayNumber
    }

    func endDrag() {
        draggingDayNumber = nil
    }

    func isDragging(_ dayNumber: Int) -> Bool {
        draggingDayNumber == dayNumber
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let layout = try await api.fetchRearrangeLayout(type: programType)
            trainings = layout.trainings
            weekDays = layout.weekDays
            assignmentByDayNumber = Dictionary(
                uniqueKeysWithValues: layout.trainings.map { ($0.dayNumber, $0.currentWeekday) }
            )
        } catch {
            errorMessage = "Could not load week layout."
        }
    }

    func resetTrainings() {
        assignmentByDayNumber = [:]
        errorMessage = nil
    }

    func assign(dayNumber: Int, to weekday: WEEKDAY?) {
        if let weekday {
            assignmentByDayNumber[dayNumber] = weekday
        } else {
            assignmentByDayNumber.removeValue(forKey: dayNumber)
        }
    }

    func save() async {
        guard assignmentByDayNumber.count == trainings.count else {
            errorMessage = "Place every training on a day before saving."
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let assignments = assignmentByDayNumber.map {
                RearrangeAssignment(dayNumber: $0.key, weekday: $0.value)
            }
            _ = try await api.saveRearrange(
                type: programType,
                request: RearrangeRequest(assignments: assignments)
            )
            didSave = true
        } catch {
            errorMessage = "Could not save arrangement."
        }
    }
}

enum REARRANGE_DRAG: Transferable, Equatable {
    case training(Int)

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(
            exporting: { "\($0.dayNumber)" },
            importing: { REARRANGE_DRAG.training(Int($0) ?? 0) }
        )
    }

    var dayNumber: Int {
        switch self {
        case .training(let dayNumber): return dayNumber
        }
    }
}
