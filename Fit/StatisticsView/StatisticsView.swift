import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @Query private var oneRepMaxHistories: [OneRepMaxHistory]
    @Query private var exercises: [Exercise]
    
    var body: some View {
        let oneRepMaxService = OneRepMaxService(modelContext: modelContext)
                        
        VStack {
            Text("Statistics")
            List {
                ForEach(exercises, id: \.id) { exercise in
                    let orpHistory = oneRepMaxService.getOneRepMaxHistory(for: exercise)
                    if !orpHistory.isEmpty {
                        DualAxisChartView(oneRepMaxHistory: orpHistory)
                        VStack(alignment: .leading) {
                            Text("Exercise: \(exercise.name)")
                            ForEach(orpHistory, id: \.date) { orp in
                                Text("\(orp.date) \(orp.oneRepMax)")
                            }
                        }
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
