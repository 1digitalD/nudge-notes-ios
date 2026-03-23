# Codex: Implement iOS App Fixes

## Context
User tested the nudge Notes iOS app and provided feedback. Fix these issues and align design with the PDF printable tracker.

## Reference Materials
- **PDF design files:** `design-reference/pdf-page1.png` and `pdf-page2.png` (converted from PDFs)
- **Current implementation:** All Phase 0-9 code in `nudgeNotes/`
- **Full requirements:** `IMPLEMENTATION-PLAN.md`
- **Original PRD:** `../PRD.md`

## Critical Fixes Required

### 1. Fix Disabled Buttons (URGENT)
**Problem:** Buttons appear disabled/unresponsive in the app  
**Fix:** Audit ALL buttons and apply proper styles

```swift
// Apply to all interactive buttons:
.buttonStyle(.borderedProminent)
.tint(AppTheme.accent)

// For secondary actions:
.buttonStyle(.bordered)
```

Check these views:
- `DailyCheckInView.swift` - Save button
- `HomeView.swift` - Check-in button, other CTAs
- `MonthlyReviewView.swift` - Save button
- `ProUpgradeView.swift` - Purchase buttons
- Any other views with buttons

### 2. Meal Tracking + Auto Fasting Window

**Current (WRONG):**
```swift
TextField("Fasting window", text: $viewModel.fastingWindowText)
```

**Required (CORRECT):**
- Remove manual fasting window input completely
- Create full meal tracking system
- Auto-calculate fasting window

#### A. Create New Model: `nudgeNotes/Models/MealLog.swift`

```swift
import Foundation
import SwiftData

@Model
final class MealLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var mealType: MealType
    var notes: String?
    var calories: Int?
    var isPackaged: Bool
    @Relationship(deleteRule: .cascade, inverse: \PhotoLog.mealLog)
    var photos: [PhotoLog]
    @Relationship var dailyLog: DailyLog?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        timestamp: Date,
        mealType: MealType,
        notes: String? = nil,
        calories: Int? = nil,
        isPackaged: Bool = false,
        photos: [PhotoLog] = [],
        dailyLog: DailyLog? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.mealType = mealType
        self.notes = notes
        self.calories = calories
        self.isPackaged = isPackaged
        self.photos = photos
        self.dailyLog = dailyLog
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
}
```

#### B. Update `nudgeNotes/Models/DailyLog.swift`

```swift
// REMOVE THIS:
var fastingWindow: Int?

// ADD THESE:
@Relationship(deleteRule: .cascade, inverse: \MealLog.dailyLog)
var meals: [MealLog]
var createdAt: Date
var updatedAt: Date

// ADD THIS COMPUTED PROPERTY:
var fastingWindowHours: Double? {
    // Get meals from this day and previous day
    // Find: last meal from previous day
    // Find: first meal from this day
    // Calculate time difference in hours
    
    // Pseudo-logic:
    // 1. Get previous day's date
    // 2. Query all MealLog entries for previous day (same DailyLog parent)
    // 3. Find latest timestamp
    // 4. Query this day's meals, find earliest timestamp
    // 5. Return time difference in hours
    
    // NOTE: You'll need to fetch previous day's DailyLog from ModelContext
    // This might require passing ModelContext to this property, OR
    // Calculate it in the ViewModel instead
    
    return nil  // Implement logic
}
```

**IMPORTANT:** Fasting window calculation might need to be in `DailyCheckInViewModel` since it requires ModelContext to query previous day's data. Use this logic:

```swift
// In ViewModel:
func calculateFastingWindow(modelContext: ModelContext) -> TimeInterval? {
    guard let firstMeal = dailyLog.meals.min(by: { $0.timestamp < $1.timestamp }) else {
        return nil
    }
    
    // Get previous day
    let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: dailyLog.date)!
    
    // Fetch previous day's DailyLog
    let descriptor = FetchDescriptor<DailyLog>(
        predicate: #Predicate { log in
            Calendar.current.isDate(log.date, inSameDayAs: previousDay)
        }
    )
    
    guard let previousDayLog = try? modelContext.fetch(descriptor).first,
          let lastMeal = previousDayLog.meals.max(by: { $0.timestamp < $1.timestamp }) else {
        return nil
    }
    
    return firstMeal.timestamp.timeIntervalSince(lastMeal.timestamp)
}
```

#### C. Update `nudgeNotes/Models/PhotoLog.swift`

```swift
// ADD optional meal relation:
@Relationship var mealLog: MealLog?

// Keep existing dailyLog relation
```

#### D. Create New View: `nudgeNotes/Views/MealDetailView.swift`

Full meal entry/edit form:
- DatePicker for timestamp
- Picker for meal type (breakfast/lunch/dinner/snack)
- TextField for calories (optional, number pad)
- Toggle for "Packaged/Processed"
- TextField for notes (multiline, optional)
- Photo picker button (future: use PhotosPicker)
- Save button

#### E. Update `nudgeNotes/Views/DailyCheckInView.swift`

**Remove:**
- Entire "Fasting window" text field section

**Add new section:**
```swift
Section("Meals") {
    ForEach(viewModel.meals) { meal in
        NavigationLink {
            MealDetailView(meal: meal)
        } label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(meal.mealType.rawValue)
                        .font(.headline)
                    Text(meal.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let calories = meal.calories {
                    Text("\(calories) cal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if meal.isPackaged {
                    Text("📦")
                }
            }
        }
    }
    .onDelete(perform: viewModel.deleteMeal)
    
    Button("Add Meal") {
        viewModel.addNewMeal()
    }
    .buttonStyle(.bordered)
}

Section("Fasting Window") {
    if let hours = viewModel.fastingWindowHours {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        Text("\(wholeHours)h \(minutes)m fasting")
            .font(.title3)
            .foregroundStyle(AppTheme.accent)
    } else {
        Text("Log meals to see fasting window")
            .foregroundStyle(.secondary)
            .font(.caption)
    }
}
```

#### F. Update `nudgeNotes/ViewModels/DailyCheckInViewModel.swift`

```swift
// Remove:
@Published var fastingWindowText: String = ""

// Add:
@Published var meals: [MealLog] = []
var fastingWindowHours: Double? {
    // Calculate from meals (see logic above)
}

func addNewMeal() {
    let meal = MealLog(
        timestamp: Date(),
        mealType: .breakfast  // default, user will change
    )
    meals.append(meal)
}

func deleteMeal(at offsets: IndexSet) {
    meals.remove(atOffsets: offsets)
}
```

### 3. Edit/Delete Support

#### A. Update `nudgeNotes/Views/HistoryTabView.swift`

Make each row tappable to edit:

```swift
ForEach(logs) { log in
    NavigationLink {
        DailyCheckInView(date: log.date, existingLog: log)  // Pass existing log
    } label: {
        // existing row content
    }
}
.onDelete { offsets in
    // Add delete confirmation alert
    showingDeleteConfirmation = true
    logToDelete = offsets.first
}
```

#### B. Update `nudgeNotes/Views/DailyCheckInView.swift`

Add edit mode support:

```swift
init(date: Date, existingLog: DailyLog? = nil) {
    _viewModel = State(initialValue: DailyCheckInViewModel(
        date: date,
        existingLog: existingLog
    ))
}

// In toolbar:
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button(viewModel.isEditMode ? "Update" : "Save") {
            do {
                try viewModel.save(in: modelContext)
                dismiss()
            } catch {
                // handle error
            }
        }
        .buttonStyle(.borderedProminent)  // FIX BUTTON STYLE
    }
}
```

#### C. Update ViewModel to handle edit mode

```swift
// In DailyCheckInViewModel:
var isEditMode: Bool { existingLog != nil }
private var existingLog: DailyLog?

init(date: Date, existingLog: DailyLog? = nil) {
    self.date = date
    self.existingLog = existingLog
    
    if let existing = existingLog {
        // Populate all fields from existing log
        self.sleepHoursText = existing.sleepHours.map { String($0) } ?? ""
        self.sleepQuality = existing.sleepQuality ?? 3
        self.meals = existing.meals
        // ... etc for all fields
    }
}

func save(in context: ModelContext) throws {
    if let existing = existingLog {
        // Update existing
        existing.sleepHours = Double(sleepHoursText)
        existing.updatedAt = Date()
        // ... update all fields
    } else {
        // Create new (existing logic)
    }
}
```

### 4. Design Alignment with PDF

**CRITICAL:** Look at `design-reference/pdf-page1.png` and `pdf-page2.png`

Extract:
1. **Color palette** - What colors are used? Update `AppTheme.swift`
2. **Logo/branding** - Create app icon based on cover page design
3. **Typography** - Match font weights, sizes, hierarchy
4. **Layout patterns** - Spacing, grouping, visual hierarchy
5. **Icons/emoji** - If PDF uses emoji (like 💧 for water), add them

#### Update `nudgeNotes/Resources/AppTheme.swift`

Based on PDF colors (you'll extract these):

```swift
enum AppTheme {
    // Update with PDF-extracted colors
    static let accent = Color(/* extract from PDF */)
    static let background = Color(/* extract from PDF */)
    static let cardBackground = Color(/* extract from PDF */)
    
    // Add new colors if needed for sections, headers, etc.
}
```

#### Create New App Icon

1. Extract logo/graphic element from pdf-page1.png
2. Create icon at multiple sizes (1024x1024 master, then generate all required sizes)
3. Update `nudgeNotes/Resources/Assets.xcassets/AppIcon.appiconset/`

### 5. Data Migration

**SIMPLE APPROACH:** Wipe existing data, start fresh

```swift
// In PersistenceController.swift, add helper:
static func resetDatabase() {
    let url = URL.applicationSupportDirectory.appending(path: "nudgeNotes.store")
    try? FileManager.default.removeItem(at: url)
}

// Call this once on app launch to clear old data
// Or add a developer menu option
```

---

## Test-First Requirements

Write tests BEFORE implementing features:

### Tests to Add/Update:

1. **`Tests/ModelTests/MealLogTests.swift`** (new)
   - Test meal creation
   - Test meal properties
   - Test relation to DailyLog
   - Test relation to PhotoLog

2. **`Tests/ViewModelTests/DailyCheckInViewModelTests.swift`** (update)
   - Test fasting window calculation
   - Test meal add/delete
   - Test edit mode population
   - Test save vs update logic

3. **`Tests/ViewModelTests/HistoryFeaturesTests.swift`** (update)
   - Test delete with confirmation
   - Test edit navigation

4. **`Tests/UITests/NudgeNotesUITests.swift`** (update)
   - Test meal logging flow
   - Test fasting window display
   - Test edit entry flow
   - Test all buttons are tappable

---

## Implementation Checklist

### Phase 1: Data Model
- [ ] Create `MealLog.swift`
- [ ] Update `DailyLog.swift` (remove fastingWindow, add meals, add timestamps)
- [ ] Update `PhotoLog.swift` (add mealLog relation)
- [ ] Write model tests
- [ ] Verify compilation

### Phase 2: Meal UI
- [ ] Create `MealDetailView.swift`
- [ ] Create `MealEntryViewModel.swift` (or add to DailyCheckInViewModel)
- [ ] Update `DailyCheckInView.swift`:
  - Remove fasting window text field
  - Add meals section
  - Add fasting window display (read-only)
- [ ] Write ViewModel tests for meal logic
- [ ] Test meal CRUD manually

### Phase 3: Edit/Delete
- [ ] Update `HistoryTabView.swift` (tappable rows → edit mode)
- [ ] Update `DailyCheckInView` (edit mode support)
- [ ] Update `DailyCheckInViewModel` (populate from existing, save vs update)
- [ ] Add delete confirmation alert
- [ ] Write tests for edit flows

### Phase 4: Button Fixes
- [ ] Audit ALL buttons across all views
- [ ] Apply `.buttonStyle(.borderedProminent)` or `.bordered`
- [ ] Test every button is tappable
- [ ] Verify visual feedback on tap

### Phase 5: Design
- [ ] Analyze PDF design files
- [ ] Extract color palette
- [ ] Update `AppTheme.swift`
- [ ] Create new app icon
- [ ] Update UI to match PDF aesthetic
- [ ] Add emoji/icons where appropriate (💧 water, 📦 packaged, etc.)

### Phase 6: Testing & Polish
- [ ] Run all unit tests
- [ ] Run UI tests
- [ ] Manual test on simulator (iPhone 16 Pro)
- [ ] Test dark mode
- [ ] Test accessibility (VoiceOver, Dynamic Type)
- [ ] Verify fasting window calculation is correct

### Phase 7: Commit & Push
- [ ] Commit changes: "Implement user feedback fixes: meal tracking, edit/delete, button fixes, design alignment"
- [ ] Update `BUILD-STATE.json`
- [ ] Push to GitHub
- [ ] Update documentation

---

## Critical Notes

1. **Fasting window calculation** requires querying previous day's DailyLog - implement this carefully in the ViewModel, not as a computed property on the model
2. **Button styles** - Use `.borderedProminent` for primary actions, `.bordered` for secondary
3. **Design extraction** - Actually LOOK at the PDF images and match the aesthetic precisely
4. **Test coverage** - Don't skip tests, they caught bugs in Phase 5
5. **SwiftData migration** - Simplest approach: wipe data and start fresh (add a reset button for developers)

---

## When Complete

1. Commit all changes to GitHub
2. Update BUILD-STATE.json with completion note
3. Run full test suite and share results
4. Send system event notification:

```
openclaw system event --text "nudge Notes iOS fixes complete! ✅ Meal tracking with auto fasting window, full edit/delete support, button fixes, design aligned with PDF. Ready for testing. GitHub: https://github.com/1digitalD/nudge-notes-ios" --mode now
```

---

**Build autonomously. Test thoroughly. Match the PDF design exactly.**
