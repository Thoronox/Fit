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
                .buttonStyle(.plain) // or .bordered, etc.

                Button(action: {
                    print("Tapped")
                }) {
                    Image(systemName: "gearshape")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.appPrimary)
                }
                .buttonStyle(.plain) // or .bordered, etc.
            }
            .padding()
            
            if workouts.isEmpty {
                Text("No workouts yet")
                    .foregroundColor(.secondary)
            } else {
                List {
                    ForEach(workouts) { workout in
                        LogRowView(workout: workout)
                    }
                    .onDelete(perform: deleteWorkouts)
                }
                .listStyle(PlainListStyle())

            }
            
        }
    }
    
    private func deleteWorkouts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let workoutToDelete = workouts[index]
                print("🔴 Deleting workout: \(workoutToDelete.name)")
                modelContext.delete(workoutToDelete)
            }
            
            // CRITICAL: Save the changes to persist the deletion
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
