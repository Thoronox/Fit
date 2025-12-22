import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var oneRepMaxHistories: [OneRepMaxHistory]
    @Query(sort: \PersonalRecord.date, order: .reverse) private var personalRecords: [PersonalRecord]
    @Query private var exercises: [Exercise]
    @Query private var userProfiles: [UserProfile]
    
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab bar at the top
                Picker("Statistics Tab", selection: $selectedTab) {
                    Text("1RM Progress").tag(0)
                    Text("Records").tag(1)
                    Text("Overview").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    OneRepMaxStatisticsTab(
                        exercises: exercises,
                        oneRepMaxHistories: oneRepMaxHistories,
                        modelContext: modelContext
                    )
                } else if selectedTab == 1 {
                    PersonalRecordsTab(personalRecords: personalRecords)
                } else {
                    DataOverviewTab(
                        workouts: workouts,
                        exercises: exercises,
                        personalRecords: personalRecords,
                        oneRepMaxHistories: oneRepMaxHistories,
                        userProfiles: userProfiles
                    )
                }
            }
            .navigationTitle("Statistics")
        }
    }
}

// MARK: - One Rep Max Statistics Tab
struct OneRepMaxStatisticsTab: View {
    let exercises: [Exercise]
    let oneRepMaxHistories: [OneRepMaxHistory]
    let modelContext: ModelContext
    
    var body: some View {
        let oneRepMaxService = OneRepMaxService(modelContext: modelContext)
        
        List {
            ForEach(exercises, id: \.id) { exercise in
                let orpHistory = oneRepMaxService.getOneRepMaxHistory(for: exercise)
                if !orpHistory.isEmpty {
                    Section {
                        DualAxisChartView(oneRepMaxHistory: orpHistory)
                            .frame(height: 200)
                            .padding(.vertical, 8)
                        
                        ForEach(orpHistory, id: \.date) { orp in
                            HStack {
                                Text(orp.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                Text("\(orp.oneRepMax, specifier: "%.1f") kg")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                    } header: {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(.red)
                            Text(exercise.name)
                                .textCase(nil)
                        }
                        .font(.headline)
                    }
                }
            }
        }
        .onAppear {
            for ii in 0..<oneRepMaxHistories.count {
                print ("\(ii) : \(oneRepMaxHistories[ii].date) , \(oneRepMaxHistories[ii].exercise!.name) \(oneRepMaxHistories[ii].oneRepMax)")
            }
            print ("------------------")
            for ii in 0..<exercises.count {
                print ("\(ii) : \(exercises[ii].id) , \(exercises[ii].name)")
            }
        }
    }
}

// MARK: - Personal Records Tab
struct PersonalRecordsTab: View {
    let personalRecords: [PersonalRecord]
    
    var body: some View {
        List {
            if personalRecords.isEmpty {
                ContentUnavailableView(
                    "No Personal Records",
                    systemImage: "trophy.fill",
                    description: Text("Complete workouts to set personal records")
                )
            } else {
                ForEach(groupedRecords().keys.sorted(), id: \.self) { exerciseName in
                    if let records = groupedRecords()[exerciseName] {
                        Section {
                            ForEach(records, id: \.id) { record in
                                PersonalRecordRow(record: record)
                            }
                        } header: {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.red)
                                Text(exerciseName)
                                    .textCase(nil)
                            }
                            .font(.headline)
                        }
                    }
                }
            }
        }
    }
    
    private func groupedRecords() -> [String: [PersonalRecord]] {
        Dictionary(grouping: personalRecords) { record in
            record.exercise?.name ?? "Unknown Exercise"
        }
    }
}

// MARK: - Data Overview Tab
struct DataOverviewTab: View {
    let workouts: [Workout]
    let exercises: [Exercise]
    let personalRecords: [PersonalRecord]
    let oneRepMaxHistories: [OneRepMaxHistory]
    let userProfiles: [UserProfile]
    
    var body: some View {
        List {
            Section {
                DataStatRow(
                    icon: "figure.strengthtraining.traditional",
                    iconColor: .red,
                    title: "Workouts",
                    value: "\(workouts.count)",
                    subtitle: totalWorkoutDuration
                )
                
                DataStatRow(
                    icon: "dumbbell.fill",
                    iconColor: .red,
                    title: "Exercises",
                    value: "\(exercises.count)",
                    subtitle: exerciseBreakdown
                )
                
                DataStatRow(
                    icon: "trophy.fill",
                    iconColor: .red,
                    title: "Personal Records",
                    value: "\(personalRecords.count)",
                    subtitle: recordsBreakdown
                )
                
                DataStatRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .red,
                    title: "1RM History Entries",
                    value: "\(oneRepMaxHistories.count)",
                    subtitle: historyBreakdown
                )
            } header: {
                Text("Database Statistics")
                    .font(.headline)
            }
            
            Section {
                DataStatRow(
                    icon: "flame.fill",
                    iconColor: .red,
                    title: "Total Volume",
                    value: String(format: "%.0f kg", totalVolume),
                    subtitle: "Across all workouts"
                )
                
                DataStatRow(
                    icon: "calendar",
                    iconColor: .red,
                    title: "Total Sets",
                    value: "\(totalSets)",
                    subtitle: "Completed in \(workouts.count) workouts"
                )
                
                if let firstWorkout = workouts.last {
                    DataStatRow(
                        icon: "calendar.badge.clock",
                        iconColor: .red,
                        title: "First Workout",
                        value: firstWorkout.date.formatted(date: .abbreviated, time: .omitted),
                        subtitle: firstWorkout.name
                    )
                }
                
                if let lastWorkout = workouts.first {
                    DataStatRow(
                        icon: "calendar.badge.checkmark",
                        iconColor: .red,
                        title: "Latest Workout",
                        value: lastWorkout.date.formatted(date: .abbreviated, time: .omitted),
                        subtitle: lastWorkout.name
                    )
                }
            } header: {
                Text("Workout Statistics")
                    .font(.headline)
            }
        }
    }
    
    private var totalVolume: Double {
        workouts.reduce(0) { $0 + $1.totalVolume }
    }
    
    private var totalSets: Int {
        workouts.reduce(0) { $0 + $1.totalSets }
    }
    
    private var totalWorkoutDuration: String {
        let totalSeconds = workouts.compactMap { $0.duration }.reduce(0, +)
        let hours = Int(totalSeconds) / 3600
        if hours > 0 {
            return "\(hours) hours total"
        } else {
            let minutes = Int(totalSeconds) / 60
            return "\(minutes) minutes total"
        }
    }
    
    private var exerciseBreakdown: String {
        let exerciseTypes = Dictionary(grouping: exercises) { $0.exerciseType }
        let muscleGroups = Set(exercises.map { $0.primaryMuscleGroup })
        return "\(exerciseTypes.count) types, \(muscleGroups.count) muscle groups"
    }
    
    private var recordsBreakdown: String {
        let actual = personalRecords.filter { $0.recordType == .actual }.count
        let calculated = personalRecords.filter { $0.recordType == .calculated }.count
        return "\(actual) actual, \(calculated) calculated"
    }
    
    private var historyBreakdown: String {
        let sources = Dictionary(grouping: oneRepMaxHistories) { $0.source }
        return "\(sources.count) different sources"
    }
    
    private var profileInfo: String {
        if let profile = userProfiles.first {
            return profile.name ?? "No name set"
        }
        return "No profile configured"
    }
}

// MARK: - Data Stat Row
struct DataStatRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Personal Record Row
struct PersonalRecordRow: View {
    let record: PersonalRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(record.weight, specifier: "%.1f") kg")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("×")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("\(record.reps)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Text("1RM: \(record.oneRepMax, specifier: "%.1f") kg")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(record.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    RecordTypeBadge(recordType: record.recordType)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Record Type Badge
struct RecordTypeBadge: View {
    let recordType: RecordType
    
    var body: some View {
        Text(recordType.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch recordType {
        case .actual:
            return .green
        case .calculated:
            return .blue
        }
    }
}

#Preview {
    let previewData = PreviewData.create()
    
    StatisticsView()
        .modelContainer(previewData.container)
        .preferredColorScheme(.dark)
}
