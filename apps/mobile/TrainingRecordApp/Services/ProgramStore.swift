import Foundation

enum ProgramStoreError: Error {
    case programNotFound
    case blockNotFound
    case exerciseNotFound
    case sessionNotFound
    case seedMissing
    case atlasMisconfigured
    case atlasRequestFailed
}

actor ProgramStore {
    static let shared = ProgramStore()

    private var seeds: [PROGRAM_TYPE: ProgramSeed] = [:]
    private var programs: [PROGRAM_TYPE: PersistedProgramState] = [:]
    private var sessions: [String: ScheduledSession] = [:]
    private var exerciseIndex: [String: String] = [:]
    private var isReady = false

    private let local = LocalProgramPersistence()
    private let atlas = AtlasProgramPersistence()

    func ensureReady() async throws {
        if isReady { return }
        loadSeeds()
        // Local-first so UI is instant; Atlas is backup / first install only.
        if let localSnapshot = try await local.load(), !localSnapshot.programs.isEmpty {
            apply(snapshot: localSnapshot)
            isReady = true
            return
        }
        if let remote = try? await atlas.loadSnapshot(), !remote.programs.isEmpty {
            apply(snapshot: remote)
            try await persistLocal()
            isReady = true
            return
        }
        bootstrapFromSeeds()
        try await persistLocal()
        isReady = true
        let snapshot = makeSnapshot()
        Task { try? await atlas.saveSnapshot(snapshot) }
    }

    func listPrograms() -> [ProgramSummary] {
        PROGRAM_TYPE.allCases.map { type in
            let seed = seeds[type]!
            let state = programs[type]!
            return ProgramSummary(
                programType: type,
                title: seed.title,
                totalWeeks: seed.totalWeeks,
                currentWeek: currentWeek(for: type),
                startDate: state.startDate
            )
        }
    }

    func getCalendar(type: PROGRAM_TYPE, from: String, days: Int) -> [DayRecord] {
        guard let start = ScheduleDateHelpers.parseIso(from) else { return [] }
        var byDate: [String: [ScheduledSession]] = [:]
        for session in sessions.values where session.programType == type {
            byDate[session.date, default: []].append(session)
        }
        return (0..<days).compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let iso = ScheduleDateHelpers.toIsoDate(date)
            let daySessions = (byDate[iso] ?? []).sorted {
                $0.sessionLabel.localizedCaseInsensitiveCompare($1.sessionLabel) == .orderedAscending
            }
            return DayRecord(
                date: iso,
                weekday: ScheduleDateHelpers.weekdayFromDate(date),
                sessions: daySessions,
                overallStatus: deriveDayStatus(daySessions, dateIso: iso),
                summary: sessionSummary(daySessions)
            )
        }
    }

    func completeExercise(id: String) async throws -> CompleteExerciseResponse {
        guard var found = getExercise(id) else { throw ProgramStoreError.exerciseNotFound }
        found.exercise.completed = true
        writeExercise(found.exercise, sessionId: found.session.id)
        try await persistLocal()
        enqueueSessionSync(found.session.id)
        return CompleteExerciseResponse(
            exercise: found.exercise,
            promptFeedback: true,
            message: "Confirm how the exercise went"
        )
    }

    func submitFeedback(id: String, status: PERFORMANCE_STATUS, adjustments: ExerciseAdjustment?) async throws -> ScheduledExercise {
        guard var found = getExercise(id) else { throw ProgramStoreError.exerciseNotFound }
        found.exercise.completed = true
        found.exercise.status = status
        if let adjustments {
            found.exercise.adjustments = adjustments
        }
        writeExercise(found.exercise, sessionId: found.session.id)
        try await persistLocal()
        enqueueSessionSync(found.session.id)
        return found.exercise
    }

    func moveSession(id: String, targetDate: String) async throws -> ScheduledSession {
        guard var session = sessions[id] else { throw ProgramStoreError.sessionNotFound }
        guard let date = ScheduleDateHelpers.parseIso(targetDate) else {
            throw ProgramStoreError.sessionNotFound
        }
        session.date = targetDate
        session.weekday = ScheduleDateHelpers.weekdayFromDate(date)
        sessions[id] = session
        try await persistLocal()
        enqueueSessionSync(id)
        return session
    }

    func getRearrangeLayout(type: PROGRAM_TYPE, blockId: String?) throws -> RearrangeLayout {
        guard let seed = seeds[type], programs[type] != nil else {
            throw ProgramStoreError.programNotFound
        }
        let blocks = seed.resolvedBlocks
        let current = currentWeek(for: type)
        let currentBlock = blocks.first { current >= $0.weekStart && current <= $0.weekEnd } ?? blocks[0]
        let selected = blockId.flatMap { id in blocks.first { $0.id == id } } ?? currentBlock
        let templateWeek = min(max(current, selected.weekStart), selected.weekEnd)
        let week = seed.weeks.first { $0.weekNumber == templateWeek }
            ?? seed.weeks.first { $0.weekNumber == selected.weekStart }
            ?? seed.weeks[0]
        let seedWeekdays = seedWeekdayMap(seed)
        let blockWeekdays = blockWeekdayMap(type: type, blockId: selected.id)

        let trainings = week.sessions.map { template in
            RearrangeTraining(
                dayNumber: template.dayNumber,
                label: ScheduleDateHelpers.trainingLabel(template.sessionLabel),
                currentWeekday: blockWeekdays[template.dayNumber]
                    ?? seedWeekdays[template.dayNumber]
                    ?? template.defaultWeekday
            )
        }

        let today = Calendar.current.startOfDay(for: Date())
        let weekDays = (0..<7).compactMap { offset -> RearrangeWeekDay? in
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }
            let weekday = ScheduleDateHelpers.weekdayFromDate(date)
            return RearrangeWeekDay(
                date: ScheduleDateHelpers.toIsoDate(date),
                weekday: weekday,
                shortLabel: ScheduleDateHelpers.shortWeekdayLabel(weekday)
            )
        }

        return RearrangeLayout(
            blocks: blocks.map { block in
                RearrangeBlock(
                    id: block.id,
                    name: block.name,
                    weekStart: block.weekStart,
                    weekEnd: block.weekEnd,
                    isCurrent: current >= block.weekStart && current <= block.weekEnd,
                    isPast: block.weekEnd < current
                )
            },
            selectedBlockId: selected.id,
            trainings: trainings,
            weekDays: weekDays
        )
    }

    func rearrangeSchedule(type: PROGRAM_TYPE, blockId: String, assignments: [RearrangeAssignment]) async throws {
        guard let seed = seeds[type], var state = programs[type] else {
            throw ProgramStoreError.programNotFound
        }
        guard let block = seed.resolvedBlocks.first(where: { $0.id == blockId }) else {
            throw ProgramStoreError.blockNotFound
        }

        var map: [String: WEEKDAY] = [:]
        for assignment in assignments {
            map[String(assignment.dayNumber)] = assignment.weekday
        }
        state.weekdayByBlock[blockId] = map
        programs[type] = state

        let todayIso = ScheduleDateHelpers.toIsoDate(Date())
        let programStartIso = ScheduleDateHelpers.startOfWeekMonday(state.startDate)
        guard let programStart = ScheduleDateHelpers.parseIso(programStartIso) else { return }
        let applyFromWeek = max(currentWeek(for: type), block.weekStart)
        let yesterdayIso = ScheduleDateHelpers.addDays(todayIso, days: -1)
        let weekdayMap = Dictionary(uniqueKeysWithValues: assignments.map { ($0.dayNumber, $0.weekday) })
        var changed: [ScheduledSession] = []

        for (id, var session) in sessions {
            guard session.programType == type else { continue }
            guard session.weekNumber >= applyFromWeek, session.weekNumber <= block.weekEnd else { continue }
            guard let mapped = weekdayMap[session.dayNumber] else { continue }
            guard let weekStart = Calendar.current.date(
                byAdding: .day,
                value: (session.weekNumber - 1) * 7,
                to: programStart
            ) else { continue }
            let nextDate = ScheduleDateHelpers.dateForWeekdayInWeek(
                weekStartMonday: weekStart,
                weekday: mapped
            )
            let nextIso = ScheduleDateHelpers.toIsoDate(nextDate)
            if nextIso < todayIso {
                session.date = yesterdayIso
            } else {
                session.date = nextIso
            }
            session.weekday = mapped
            sessions[id] = session
            changed.append(session)
        }

        try await persistLocal()
        let program = state
        let toSync = changed
        Task {
            try? await atlas.upsertProgram(program)
            try? await atlas.upsertSessions(toSync)
        }
    }

    func persistLocal() async throws {
        try await local.save(makeSnapshot())
    }

    private func makeSnapshot() -> PersistedStoreSnapshot {
        PersistedStoreSnapshot(
            programs: Array(programs.values),
            sessions: Array(sessions.values)
        )
    }

    private func enqueueSessionSync(_ sessionId: String) {
        guard let session = sessions[sessionId] else { return }
        Task { try? await atlas.upsertSession(session) }
    }

    // MARK: - Private

    private func loadSeeds() {
        for type in PROGRAM_TYPE.allCases {
            let name: String
            switch type {
            case .CALISTHENICS: name = "calisthenics"
            case .ENDURANCE: name = "endurance"
            }
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let seed = try? JSONDecoder().decode(ProgramSeed.self, from: data)
            else {
                continue
            }
            seeds[type] = seed
        }
    }

    private func bootstrapFromSeeds() {
        let today = ScheduleDateHelpers.toIsoDate(Date())
        sessions.removeAll()
        exerciseIndex.removeAll()
        programs.removeAll()
        for type in PROGRAM_TYPE.allCases {
            guard let seed = seeds[type] else { continue }
            programs[type] = PersistedProgramState(
                programType: type,
                title: seed.title,
                totalWeeks: seed.totalWeeks,
                startDate: today,
                weekdayByBlock: [:]
            )
            materialize(type: type, seed: seed, startIso: today)
        }
    }

    private func apply(snapshot: PersistedStoreSnapshot) {
        programs = Dictionary(uniqueKeysWithValues: snapshot.programs.map { ($0.programType, $0) })
        sessions = Dictionary(uniqueKeysWithValues: snapshot.sessions.map { ($0.id, $0) })
        exerciseIndex = [:]
        for session in snapshot.sessions {
            for exercise in session.exercises {
                exerciseIndex[exercise.id] = session.id
            }
        }
        for type in PROGRAM_TYPE.allCases where programs[type] == nil {
            if let seed = seeds[type] {
                let today = ScheduleDateHelpers.toIsoDate(Date())
                programs[type] = PersistedProgramState(
                    programType: type,
                    title: seed.title,
                    totalWeeks: seed.totalWeeks,
                    startDate: today,
                    weekdayByBlock: [:]
                )
                materialize(type: type, seed: seed, startIso: today)
            }
        }
    }

    private func materialize(type: PROGRAM_TYPE, seed: ProgramSeed, startIso: String) {
        let seedWeekdays = seedWeekdayMap(seed)
        let programStartIso = ScheduleDateHelpers.startOfWeekMonday(startIso)
        guard let programStart = ScheduleDateHelpers.parseIso(programStartIso) else { return }

        for week in seed.weeks {
            guard let weekStart = Calendar.current.date(
                byAdding: .day,
                value: (week.weekNumber - 1) * 7,
                to: programStart
            ) else { continue }
            for template in week.sessions {
                let weekday = seedWeekdays[template.dayNumber] ?? template.defaultWeekday
                let date = ScheduleDateHelpers.dateForWeekdayInWeek(
                    weekStartMonday: weekStart,
                    weekday: weekday
                )
                let sessionId = UUID().uuidString
                let exercises: [ScheduledExercise] = template.exercises.map { ex in
                    let id = UUID().uuidString
                    exerciseIndex[id] = sessionId
                    let prescription = ex.prescription ?? [
                        ex.name,
                        ex.distance,
                        ex.pace,
                        ex.duration,
                        ex.intervals,
                        ex.targetWeight,
                        ex.setsReps,
                        ex.rest,
                    ]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " — ")
                    return ScheduledExercise(
                        id: id,
                        name: ex.name,
                        prescription: prescription,
                        targetWeight: ex.targetWeight,
                        setsReps: ex.setsReps,
                        rest: ex.rest,
                        distance: ex.distance,
                        pace: ex.pace,
                        duration: ex.duration,
                        intervals: ex.intervals,
                        metrics: ex.metrics,
                        completed: false,
                        status: .PENDING,
                        adjustments: nil
                    )
                }
                sessions[sessionId] = ScheduledSession(
                    id: sessionId,
                    programType: type,
                    weekNumber: week.weekNumber,
                    dayNumber: template.dayNumber,
                    sessionLabel: template.sessionLabel,
                    date: ScheduleDateHelpers.toIsoDate(date),
                    weekday: weekday,
                    exercises: exercises
                )
            }
        }
    }

    private func seedWeekdayMap(_ seed: ProgramSeed) -> [Int: WEEKDAY] {
        Dictionary(
            uniqueKeysWithValues: seed.defaultWeekdayByDayNumber.compactMap { key, value in
                Int(key).map { ($0, value) }
            }
        )
    }

    private func blockWeekdayMap(type: PROGRAM_TYPE, blockId: String) -> [Int: WEEKDAY] {
        guard let raw = programs[type]?.weekdayByBlock[blockId] else { return [:] }
        return Dictionary(
            uniqueKeysWithValues: raw.compactMap { key, value in
                Int(key).map { ($0, value) }
            }
        )
    }

    private func currentWeek(for type: PROGRAM_TYPE) -> Int {
        guard let seed = seeds[type], let state = programs[type],
              let start = ScheduleDateHelpers.parseIso(
                ScheduleDateHelpers.startOfWeekMonday(state.startDate)
              ),
              let today = ScheduleDateHelpers.parseIso(ScheduleDateHelpers.toIsoDate(Date()))
        else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0
        let weeksElapsed = max(0, days / 7)
        return min(seed.totalWeeks, max(1, weeksElapsed + 1))
    }

    private func getExercise(_ exerciseId: String) -> (session: ScheduledSession, exercise: ScheduledExercise)? {
        guard let sessionId = exerciseIndex[exerciseId],
              let session = sessions[sessionId],
              let exercise = session.exercises.first(where: { $0.id == exerciseId })
        else { return nil }
        return (session, exercise)
    }

    private func writeExercise(_ exercise: ScheduledExercise, sessionId: String) {
        guard var session = sessions[sessionId],
              let index = session.exercises.firstIndex(where: { $0.id == exercise.id })
        else { return }
        session.exercises[index] = exercise
        sessions[sessionId] = session
    }

    private func deriveDayStatus(_ daySessions: [ScheduledSession], dateIso: String) -> PERFORMANCE_STATUS {
        if daySessions.isEmpty { return .REST }
        let today = ScheduleDateHelpers.toIsoDate(Date())
        let exercises = daySessions.flatMap(\.exercises)
        let isPast = dateIso < today
        if isPast && exercises.contains(where: { !$0.completed || $0.status == .PENDING }) {
            return .BAD
        }
        let actionable = exercises.map(\.status).filter { $0 != .PENDING }
        if actionable.isEmpty { return .PENDING }
        if actionable.allSatisfy({ $0 == .GOOD }) { return .GOOD }
        if actionable.contains(.BAD) { return .BAD }
        if actionable.contains(.SO_SO) { return .SO_SO }
        return .PENDING
    }

    private func sessionSummary(_ daySessions: [ScheduledSession]) -> String {
        if daySessions.isEmpty { return "Rest" }
        return daySessions.map(\.sessionLabel).joined(separator: " · ")
    }
}
