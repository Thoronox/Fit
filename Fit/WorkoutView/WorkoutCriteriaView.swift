import SwiftUI

struct CriteriaMenu: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(selection.isEmpty ? title : selection)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minWidth: 80)
            .background(Color.appPrimary)
            .cornerRadius(8)
        }
    }
}

struct WorkoutCriteriaView: View {
    @EnvironmentObject var criteria: WorkoutCriteria

    let duration = ["30 min", "45 min", "60 min", "90 min"]
    let trainingType = ["Strength", "Hypertrophy", "Cardio", "HIIT", "Yoga"]
    let difficulty = ["Beginner", "Intermediate", "Advanced"]
    let workoutSplit = ["Full Body", "Push", "Pull", "Legs"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CriteriaMenu(title: "Duration", options: duration, selection: $criteria.durationSelected)
                CriteriaMenu(title: "Workout Split", options: workoutSplit, selection: $criteria.workoutSplitSelected)
                CriteriaMenu(title: "Type", options: trainingType, selection: $criteria.trainingTypeSelected)
                CriteriaMenu(title: "Difficulty", options: difficulty, selection: $criteria.difficultySelected)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
}

#Preview {
    WorkoutCriteriaView()
        .environmentObject(WorkoutCriteria())
        .preferredColorScheme(.dark)
}

