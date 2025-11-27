import SwiftUI
import Charts

struct DualAxisChartView: View {
    var oneRepMaxHistory: [OneRepMaxHistory]
    
    // Sample data - will be populated from oneRepMaxHistory
    @State private var orpData: [(number: String, oneRepMax: Int, normalizedORP: Double)] = []
    @State private var volumeData: [(number: String, totalVolume: Double, normalizedTotalVolume: Double)] = []
    
    private func calculateChartData() {
        // Clear existing data
        orpData = []
        volumeData = []
        
        // Sort oneRepMaxHistory by date (oldest to newest)
        let sortedHistory = oneRepMaxHistory.sorted { first, second in
            return first.date < second.date
        }
        
        // Find min/max for normalization using sorted data
        let maxOneRepMax = sortedHistory.map { $0.oneRepMax }.max() ?? 1.0
        let minOneRepMax = sortedHistory.map { $0.oneRepMax }.min() ?? 0.0

        // Generate volume data first to find actual min/max
        var tempVolumeData: [Double] = []
        
        for index in 0..<sortedHistory.count {
            let oneRepMax = sortedHistory[index].oneRepMax
            
            // Normalize the one rep max value (0 to 1)
            let normalizedValue = maxOneRepMax > minOneRepMax ?
                (oneRepMax - minOneRepMax) / (maxOneRepMax - minOneRepMax) : 0.0
            
            orpData.append((
                number: String(index + 1),
                oneRepMax: Int(oneRepMax),
                normalizedORP: normalizedValue
            ))
            
            let totalVolume = 1000 + Double.random(in: 0...4000)
            tempVolumeData.append(totalVolume)
        }
        
        // Find actual min/max volume from generated data
        let maxVolume = tempVolumeData.max() ?? 5000.0
        let minVolume = tempVolumeData.min() ?? 1000.0
        
        // Now create volume data with proper normalization
        for index in 0..<tempVolumeData.count {
            let totalVolume = tempVolumeData[index]
            let normalizedVolumeValue = maxVolume > minVolume ?
                (totalVolume - minVolume) / (maxVolume - minVolume) : 0.0

            volumeData.append((
                number: String(index + 1),
                totalVolume: totalVolume,
                normalizedTotalVolume: normalizedVolumeValue
            ))
        }
    }
    
    var body: some View {
        VStack {
            Chart {
                // Left axis - One Rep Max (Line Chart)
                ForEach(orpData, id: \.number) { data in
                    LineMark(
                        x: .value("No.", data.number),
                        y: .value("One Rep Max", data.oneRepMax)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .symbol(Circle())
                }
                
                // Right axis - Volume (Line Chart) - scale normalized values to One Rep Max range
                ForEach(volumeData, id: \.number) { data in
                    LineMark(
                        x: .value("No.", data.number),
                        y: .value("Scaled Volume", data.normalizedTotalVolume * getMaxOneRepMax()), // Scale to match One Rep Max range
                        series: .value("Volume", "Volume") // Separate series for right axis
                    )
                    .foregroundStyle(Color.appPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom) // Smooth line
                }
            }
            .chartYAxis {
                // Left axis for one rep max
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue) kg")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Right axis for volume
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            // Convert back to volume scale
                            let maxORP = getMaxOneRepMax()
                            let normalizedValue = Double(intValue) / maxORP
                            let volumeValue = getMinVolume() + (normalizedValue * (getMaxVolume() - getMinVolume()))
                            Text("\(volumeValue, specifier: "%.0f") kg")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .frame(height: 100)
            .padding()
            
            // Legend
            HStack {
                HStack {
                    Rectangle()
                        .fill(.blue)
                        .frame(width: 20, height: 3)
                    Text("One Rep Max")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                HStack {
                    Rectangle()
                        .fill(.red)
                        .frame(width: 20, height: 3)
                    Text("Volume")
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            calculateChartData()
        }
    }
    
    // Helper functions for scaling
    private func getMaxOneRepMax() -> Double {
        return Double(orpData.map { $0.oneRepMax }.max() ?? 100)
    }
    
    private func getMaxVolume() -> Double {
        return volumeData.map { $0.totalVolume }.max() ?? 5000.0
    }
    
    private func getMinVolume() -> Double {
        return volumeData.map { $0.totalVolume }.min() ?? 1000.0
    }
}
