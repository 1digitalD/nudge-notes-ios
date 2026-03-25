import Charts
import SwiftUI

struct WHRLineChart: View {
    let dataPoints: [WHRDataPoint]

    var body: some View {
        Chart {
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Week", point.weekLabel),
                    y: .value("WHR", point.whr)
                )
                .foregroundStyle(Color.appAccent)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Week", point.weekLabel),
                    y: .value("WHR", point.whr)
                )
                .foregroundStyle(Color.appAccent)
            }

            RuleMark(y: .value("Healthy", 0.80))
                .foregroundStyle(Color.appSuccess.opacity(0.3))
                .lineStyle(StrokeStyle(dash: [5, 5]))

            RuleMark(y: .value("Elevated", 0.85))
                .foregroundStyle(Color.appWarning.opacity(0.3))
                .lineStyle(StrokeStyle(dash: [5, 5]))
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(AppFonts.caption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if let whr = value.as(Double.self) {
                        Text(String(format: "%.2f", whr))
                            .font(AppFonts.caption)
                    }
                }
            }
        }
    }
}
