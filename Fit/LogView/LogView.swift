import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]

    var body: some View {
        VStack {
            HStack {
                Text("Holger F")

                Spacer()
                Button(action: {
                    print("Tapped")
                }) {
                    Image(systemName: "timer")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)

                Button(action: {
                    print("Tapped")
                }) {
                    Image(systemName: "gearshape")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            if workouts.isEmpty {
                Text("No workouts yet")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(workouts) { workout in
                        LogRowView(workout: workout)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
                                        deleteWorkouts(offsets: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    reuseWorkout(workout)
                                } label: {
                                    Label("Start Again", systemImage: "arrow.clockwise")
                                }
                                .tint(.red)
                            }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    private func reuseWorkout(_ completedWorkout: Workout) {
        // Create a new workout based on the completed one
        let newWorkout = Workout(
            name: completedWorkout.name,
            isPredefined: false,
            workoutDescription: completedWorkout.workoutDescription,
            difficulty: completedWorkout.difficulty,
            tags: completedWorkout.tags
        )
        
        // Copy exercises and sets structure (but not completion status)
        for (index, completedExercise) in completedWorkout.exercises.enumerated() {
            guard let exercise = completedExercise.exercise else { continue }
            
            let newWorkoutExercise = WorkoutExercise(
                exercise: exercise,
                order: index
            )
            
            // Copy the sets structure from the completed workout
            for completedSet in completedExercise.sets {
                let newSet = ExerciseSet(
                    setNumber: completedSet.setNumber,
                    weight: completedSet.weight,
                    reps: completedSet.reps
                )
                // Don't mark as completed - user needs to complete them again
                newSet.isCompleted = false
                newWorkoutExercise.sets.append(newSet)
            }
            
            newWorkout.exercises.append(newWorkoutExercise)
        }
        
        // DON'T insert into model context yet - it will be inserted when the workout is finished
        // The workout will only be saved to the database when finishWorkout() is called in StartWorkoutView
        
        // Post notification so WorkoutView can pick it up
        NotificationCenter.default.post(
            name: .workoutCreated,
            object: nil,
            userInfo: ["workout": newWorkout]
        )
        
        // Switch to Workout tab
        NotificationCenter.default.post(
            name: .switchToWorkoutTab,
            object: nil
        )
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workoutToDelete = workouts[index]
                print("🔴 Deleting workout: \(workoutToDelete.name)")
                modelContext.delete(workoutToDelete)
            }
            
            do {
                try modelContext.save()
                print("✅ Workout deletion saved successfully")
            } catch {
                print("❌ Failed to save workout deletion: \(error)")
            }
        }
    }
}

struct LogRowView: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(workout.name)
                    .font(.headline)
                Spacer()
                Text(workout.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("\(workout.exercises.count) exercises")
                Text("•")
                Text("\(workout.totalSets) sets")
                Text("•")
                Text("\(Int(workout.totalVolume)) kg volume")
                Spacer()
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let previewData = PreviewData.create()
    
    LogView()
        .modelContainer(previewData.container)
        .preferredColorScheme(.dark)
}
