import SwiftUI

struct VerticalDayList: View {
    let days: [DayRecord]
    let labelForDay: (DayRecord) -> String
    let isLoadingPast: Bool
    let isLoadingFuture: Bool
    let onLoadPast: () -> Void
    let onLoadFuture: () -> Void

    private var monthSections: [(key: String, title: String, days: [DayRecord])] {
        var sections: [(key: String, title: String, days: [DayRecord])] = []
        for day in days {
            if let last = sections.last, last.key == day.monthYearKey {
                sections[sections.count - 1].days.append(day)
            } else {
                sections.append((day.monthYearKey, day.monthYearLabel, [day]))
            }
        }
        return sections
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
            Color.clear
                .frame(height: 1)
                .id("past-sentinel")
                .onAppear(perform: onLoadPast)

            if isLoadingPast {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            ForEach(monthSections, id: \.key) { section in
                Section {
                    ForEach(section.days) { day in
                        dayRow(day)
                    }
                } header: {
                    Text(section.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(APP_COLORS.NAVY)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .background(APP_COLORS.BACKGROUND.opacity(0.94))
                }
            }

            if isLoadingFuture {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            Color.clear
                .frame(height: 1)
                .id("future-sentinel")
                .onAppear(perform: onLoadFuture)
        }
        .scrollTargetLayout()
        .padding(.horizontal, APP_LAYOUT.HORIZONTAL_PADDING)
    }

    @ViewBuilder
    private func dayRow(_ day: DayRecord) -> some View {
        Group {
            if day.hasTraining {
                NavigationLink(value: PROGRAM_ROUTE.dayDetail(day.id)) {
                    ScheduleDayCard(day: day, label: labelForDay(day))
                }
                .buttonStyle(.plain)
            } else {
                ScheduleDayCard(day: day, label: labelForDay(day))
            }
        }
        .id(day.id)
    }
}
