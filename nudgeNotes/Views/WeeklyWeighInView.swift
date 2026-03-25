import SwiftUI
import SwiftData
import PhotosUI

struct WeeklyWeighInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let date: Date

    @State private var weight = ""
    @State private var waist = ""
    @State private var hips = ""
    @State private var showMeasurementGuide = false
    @State private var photoItem: PhotosPickerItem?
    @State private var bodyPhoto: Data?

    @Query(sort: \WeeklyMetrics.date, order: .reverse) private var previousMetrics: [WeeklyMetrics]

    private var lastWeek: WeeklyMetrics? {
        previousMetrics.first { $0.date < date }
    }

    private var whr: Double? {
        guard let w = Double(waist), let h = Double(hips), h > 0 else { return nil }
        return w / h
    }

    private var whrZone: (color: Color, label: String) {
        guard let whr = whr else { return (.gray, "Enter measurements") }
        if whr < 0.80 { return (Color.appSuccess, "Healthy") }
        if whr < 0.85 { return (Color.appWarning, "Elevated") }
        return (Color.appDanger, "High Risk")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.sectionSpacing) {
                    // Last week summary
                    if let last = lastWeek {
                        lastWeekCard(last)
                    }

                    // Current measurements
                    measurementsCard

                    // WHR result
                    if whr != nil {
                        whrCard
                    }

                    // Optional photo
                    photoCard
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("Weekly Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveWeighIn() }
                        .fontWeight(.semibold)
                        .disabled(weight.isEmpty)
                }
            }
            .sheet(isPresented: $showMeasurementGuide) {
                MeasurementGuideView()
            }
        }
    }

    @ViewBuilder
    private func lastWeekCard(_ last: WeeklyMetrics) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Last Week")
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.appTextSecondary)

                HStack(spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Weight")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(String(format: "%.1f lbs", last.weight))
                            .font(AppFonts.bodyEmphasized)
                            .foregroundStyle(Color.appText)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("WHR")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Text(String(format: "%.2f", last.whr))
                            .font(AppFonts.bodyEmphasized)
                            .foregroundStyle(Color.appText)
                    }

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var measurementsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Text("This Week")
                        .font(AppFonts.headline)
                    Spacer()
                    Button {
                        showMeasurementGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(Color.appAccent)
                    }
                }

                Divider()

                // Weight
                HStack {
                    Text("Weight")
                        .font(AppFonts.body)
                    Spacer()
                    TextField("165", text: $weight)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("lbs")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // Waist
                HStack {
                    Text("Waist")
                        .font(AppFonts.body)
                    Spacer()
                    TextField("32", text: $waist)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("in")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // Hips
                HStack {
                    Text("Hips")
                        .font(AppFonts.body)
                    Spacer()
                    TextField("38", text: $hips)
                        .keyboardType(.decimalPad)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("in")
                        .font(AppFonts.caption)
                        .foregroundStyle(Color.appTextSecondary)
                }

                // Comparison with last week
                if let last = lastWeek, let currentWeight = Double(weight) {
                    let diff = currentWeight - last.weight
                    Divider()
                    HStack {
                        Text("vs last week")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appTextSecondary)
                        Spacer()
                        Text(String(format: "%+.1f lbs", diff))
                            .font(AppFonts.captionEmphasized)
                            .foregroundStyle(diff <= 0 ? Color.appSuccess : Color.appWarning)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var whrCard: some View {
        AppCard {
            VStack(spacing: AppSpacing.sm) {
                Text("Waist-to-Hip Ratio")
                    .font(AppFonts.caption)
                    .foregroundStyle(Color.appTextSecondary)

                Text(String(format: "%.2f", whr ?? 0))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(whrZone.color)

                Text(whrZone.label)
                    .font(AppFonts.bodyEmphasized)
                    .foregroundStyle(whrZone.color)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        Capsule()
                            .fill(whrZone.color.opacity(0.15))
                    )
            }
        }
    }

    @ViewBuilder
    private var photoCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Progress Photo (optional)")
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                if let data = bodyPhoto, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button("Remove") {
                        bodyPhoto = nil
                        photoItem = nil
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(.red)
                } else {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Add Photo")
                        }
                        .font(AppFonts.body)
                        .foregroundStyle(Color.appAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.appBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                    }
                    .onChange(of: photoItem) { _, item in
                        guard let item else { return }
                        Task {
                            bodyPhoto = try? await item.loadTransferable(type: Data.self)
                        }
                    }
                }
            }
        }
    }

    private func saveWeighIn() {
        guard let w = Double(weight) else { return }
        let wa = Double(waist) ?? 0
        let hi = Double(hips) ?? 0
        let calculatedWhr = hi > 0 ? wa / hi : 0

        let metrics = WeeklyMetrics(
            date: date,
            weight: w,
            waist: wa,
            hips: hi,
            whr: calculatedWhr,
            bodyPhoto: bodyPhoto
        )

        modelContext.insert(metrics)
        do {
            try modelContext.save()
            print("✅ WeeklyMetrics saved: weight=\(w), waist=\(wa), hips=\(hi), WHR=\(calculatedWhr)")
        } catch {
            print("❌ Failed to save WeeklyMetrics: \(error)")
        }
        dismiss()
    }
}

// MARK: - Measurement Guide

struct MeasurementGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.sectionSpacing) {
                    guideSection(
                        title: "Weight",
                        icon: "scalemass",
                        steps: [
                            "Weigh yourself in the morning",
                            "After using the bathroom",
                            "Before eating or drinking",
                            "Wear minimal clothing",
                            "Use the same scale each time"
                        ]
                    )

                    guideSection(
                        title: "Waist",
                        icon: "ruler",
                        steps: [
                            "Stand up straight and relax",
                            "Find the narrowest point of your torso",
                            "Usually just above the belly button",
                            "Wrap measuring tape snugly (not tight)",
                            "Measure at the end of a normal exhale"
                        ]
                    )

                    guideSection(
                        title: "Hips",
                        icon: "figure.stand",
                        steps: [
                            "Stand with feet together",
                            "Find the widest point of your hips/buttocks",
                            "Wrap measuring tape at that level",
                            "Keep tape parallel to the floor",
                            "Don't pull too tight"
                        ]
                    )

                    AppCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("WHR Zones")
                                .font(AppFonts.headline)

                            HStack {
                                Circle().fill(Color.appSuccess).frame(width: 12, height: 12)
                                Text("Below 0.80 — Healthy")
                                    .font(AppFonts.body)
                            }
                            HStack {
                                Circle().fill(Color.appWarning).frame(width: 12, height: 12)
                                Text("0.80 - 0.85 — Elevated")
                                    .font(AppFonts.body)
                            }
                            HStack {
                                Circle().fill(Color.appDanger).frame(width: 12, height: 12)
                                Text("Above 0.85 — High Risk")
                                    .font(AppFonts.body)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
            }
            .background(Color.appBackground)
            .navigationTitle("How to Measure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func guideSection(title: String, icon: String, steps: [String]) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label(title, systemImage: icon)
                    .font(AppFonts.headline)
                    .foregroundStyle(Color.appText)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                        Text("\(index + 1).")
                            .font(AppFonts.caption)
                            .foregroundStyle(Color.appAccent)
                            .frame(width: 20, alignment: .trailing)
                        Text(step)
                            .font(AppFonts.body)
                            .foregroundStyle(Color.appText)
                    }
                }
            }
        }
    }
}
