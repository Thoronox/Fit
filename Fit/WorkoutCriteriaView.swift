import SwiftUI

struct WorkoutCriteriaView: View {
    @State private var durationSelected = "45m"
    @State private var trainingTypeSelected = "Hypertrophy"
    @State private var difficultySelected = "Intermediate"
    @State private var equipmentSelected = "Equipment"
    
    let duration = ["30 min", "45 min", "60 min", "90 min"]
    let trainingType = ["Strength", "Hypertrophy", "Cardio", "HIIT", "Yoga"]
    let difficulty = ["Beginner", "Intermediate", "Advanced"]
    let equipment = ["Bodyweight", "Equipment"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Duration Picker
                Menu {
                    ForEach(duration, id: \.self) { option in
                        Button(action: {
                            durationSelected = option
                        }) {
                            HStack {
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                                if durationSelected == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(durationSelected.isEmpty ? "Duration" : durationSelected)
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
                            trainingTypeSelected = option
                        }) {
                            HStack {
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                                if trainingTypeSelected == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(trainingTypeSelected.isEmpty ? "Type" : trainingTypeSelected)
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
                            difficultySelected = option
                        }) {
                            HStack {
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                                if difficultySelected == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(difficultySelected.isEmpty ? "Difficulty" : difficultySelected)
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
                            equipmentSelected = option
                        }) {
                            HStack {
                                Text(option)
                                    .foregroundColor(.primary)
                                Spacer()
                                if equipmentSelected == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(equipmentSelected.isEmpty ? "Equipment" : equipmentSelected)
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
