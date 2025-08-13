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
            .background(Color.red)
            .cornerRadius(8)
        }
    }
}

struct WorkoutCriteriaView: View {
    @EnvironmentObject var criteria: WorkoutCriteria

    let duration = ["30 min", "45 min", "60 min", "90 min"]
    let trainingType = ["Strength", "Hypertrophy", "Cardio", "HIIT", "Yoga"]
    let difficulty = ["Beginner", "Intermediate", "Advanced"]
    let equipment = ["Bodyweight", "Equipment"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CriteriaMenu(title: "Duration", options: duration, selection: $criteria.durationSelected)
                CriteriaMenu(title: "Type", options: trainingType, selection: $criteria.trainingTypeSelected)
                CriteriaMenu(title: "Difficulty", options: difficulty, selection: $criteria.difficultySelected)
                CriteriaMenu(title: "Equipment", options: equipment, selection: $criteria.equipmentSelected)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical)
    }
}

/*
 struct WorkoutCriteriaViewOld: View {
 @EnvironmentObject var criteria: WorkoutCriteria
 
 let duration: [String] = ["30 min", "45 min", "60 min", "90 min"]
 let trainingType: [String] = ["Strength", "Hypertrophy", "Cardio", "HIIT", "Yoga"]
 let difficulty: [String] = ["Beginner", "Intermediate", "Advanced"]
 let equipment: [String] = ["Bodyweight", "Equipment"]
 
 var body: some View {
 
 ScrollView(.horizontal, showsIndicators: false) {
 HStack(spacing: 8) {
 // Duration Picker
 Menu {
 ForEach(duration, id: \.self) { option in
 Button(action: {
 criteria.durationSelected = option
 }) {
 HStack {
 Text(option)
 .foregroundColor(.primary)
 Spacer()
 if criteria.durationSelected == option {
 Image(systemName: "checkmark")
 .foregroundColor(.blue)
 }
 }
 }
 }
 } label: {
 HStack {
 Text(criteria.durationSelected.isEmpty ? "Duration" : criteria.durationSelected)
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
 .background(Color.red)
 .cornerRadius(8)
 }
 
 // Training Type Picker
 Menu {
 ForEach(trainingType, id: \.self) { option in
 Button(action: {
 criteria.trainingTypeSelected = option
 }) {
 HStack {
 Text(option)
 .foregroundColor(.primary)
 Spacer()
 if criteria.trainingTypeSelected == option {
 Image(systemName: "checkmark")
 .foregroundColor(.blue)
 }
 }
 }
 }
 } label: {
 HStack {
 Text(criteria.trainingTypeSelected.isEmpty ? "Type" : criteria.trainingTypeSelected)
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
 .background(Color.red)
 .cornerRadius(8)
 }
 
 // Difficulty Picker
 Menu {
 ForEach(difficulty, id: \.self) { option in
 Button(action: {
 criteria.difficultySelected = option
 }) {
 HStack {
 Text(option)
 .foregroundColor(.primary)
 Spacer()
 if criteria.difficultySelected == option {
 Image(systemName: "checkmark")
 .foregroundColor(.blue)
 }
 }
 }
 }
 } label: {
 HStack {
 Text(criteria.difficultySelected.isEmpty ? "Difficulty" : criteria.difficultySelected)
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
 .background(Color.red)
 .cornerRadius(8)
 }
 
 // Equipment Picker
 Menu {
 ForEach(equipment, id: \.self) { option in
 Button(action: {
 criteria.equipmentSelected = option
 }) {
 HStack {
 Text(option)
 .foregroundColor(.primary)
 Spacer()
 if criteria.equipmentSelected == option {
 Image(systemName: "checkmark")
 .foregroundColor(.blue)
 }
 }
 }
 }
 } label: {
 HStack {
 Text(criteria.equipmentSelected.isEmpty ? "Equipment" : criteria.equipmentSelected)
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
 .background(Color.red)
 .cornerRadius(8)
 }
 }
 .padding(.horizontal, 16)
 }
 .padding(.vertical)
 }
 }
 */
