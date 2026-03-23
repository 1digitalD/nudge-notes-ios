# Implementation Plan - iOS App Fixes v1

**Date:** 2026-03-22  
**Based on:** User feedback + PDF printable design reference  
**Estimated time:** 45-60 minutes

## Requirements Summary

### 1. Fix Disabled Buttons ✅
- All buttons should be tappable and show visual feedback
- Use proper SwiftUI button styles

### 2. Meal Tracking with Auto Fasting Window 🍽️
**Fasting calculation:** Option A (last meal previous day → first meal today)

**Meal detail level:**
- ✅ Timestamp (required)
- ✅ Meal type (breakfast/lunch/dinner/snack)
- ✅ Notes (optional)
- ✅ Photos (optional)
- ✅ Calories (optional)
- ✅ Packaged/processed checkbox

### 3. Full Edit/Delete Support ✏️
- Tap any history entry to edit
- Delete with confirmation
- Full CRUD for all fields

### 4. Design Alignment 🎨
- Match PDF printable tracker design
- Use cover page for logo/app icon inspiration
- Apply consistent color palette and typography

### 5. Data Migration
- Option A: Wipe existing data (clean slate for testing)

---

## Data Model Changes

### New Model: `MealLog.swift`
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

### Updated: `DailyLog.swift`
```swift
// REMOVE:
var fastingWindow: Int?

// ADD:
@Relationship(deleteRule: .cascade, inverse: \MealLog.dailyLog)
var meals: [MealLog]
var createdAt: Date
var updatedAt: Date

// COMPUTED PROPERTY:
var fastingWindow: TimeInterval? {
    // Logic: Get last meal from previous day + first meal today
    // Return hours between them
}
```

### Updated: `PhotoLog.swift`
```swift
// ADD optional relation:
@Relationship var mealLog: MealLog?

// Keep existing:
@Relationship var dailyLog: DailyLog?
```

---

## UI Changes

### 1. `DailyCheckInView.swift` - Complete Redesign

**Remove:**
- "Fasting window" text field

**Add:**
- **Meals Section** with:
  - List of meals logged today
  - "Add Meal" button
  - Each meal shows: time, type, calories (if entered), 📦 icon if packaged
  - Tap meal → edit meal detail view
  - Swipe to delete meal
  
- **Fasting Window Display** (read-only):
  - Show calculated hours: "14h 30m fasting"
  - Gray/disabled if no meals from yesterday/today
  - Small explanation text below

**Update:**
- Change initialization to support edit mode
- Add "Save" vs "Update" button logic
- Populate fields when editing existing entry

### 2. New View: `MealDetailView.swift`
```swift
struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var meal: MealLog
    
    var body: some View {
        Form {
            Section("Meal Details") {
                DatePicker("Time", selection: $meal.timestamp)
                Picker("Type", selection: $meal.mealType) {
                    ForEach(MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                TextField("Calories (optional)", value: $meal.calories, format: .number)
                Toggle("Packaged/Processed", isOn: $meal.isPackaged)
            }
            
            Section("Notes") {
                TextField("Notes", text: Binding(
                    get: { meal.notes ?? "" },
                    set: { meal.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
            }
            
            Section("Photos") {
                // Photo picker integration
            }
        }
        .navigationTitle(meal.mealType.rawValue)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    meal.updatedAt = Date()
                    dismiss()
                }
            }
        }
    }
}
```

### 3. `HistoryTabView.swift` - Add Edit Support
- Make each row tappable
- Navigate to `DailyCheckInView` in edit mode
- Pass existing `DailyLog` instance

### 4. Button Fixes
Audit all buttons and apply proper styles:
```swift
.buttonStyle(.borderedProminent)
.tint(AppTheme.accent)
```

---

## Design System Updates

### Colors (from PDF printable)
**To be extracted from PDF analysis:**
- Primary color (likely sage green or similar)
- Background (warm neutral)
- Text colors
- Accent colors

### Typography
- Maintain SF Pro / SF Rounded
- Match PDF hierarchy

### App Icon
- Extract logo/graphic from PDF cover page
- Create all required sizes for Assets.xcassets

---

## Migration Strategy

### SchemaV2 Migration
```swift
// Add to PersistenceController.swift
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: String = "v1"
    static var models: [any PersistentModel.Type] {
        [DailyLog.self, WHREntry.self, PhotoLog.self, UserProfile.self, HabitEntry.self, MonthlyReview.self]
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: String = "v2"
    static var models: [any PersistentModel.Type] {
        [DailyLog.self, WHREntry.self, PhotoLog.self, UserProfile.self, HabitEntry.self, MonthlyReview.self, MealLog.self]
    }
}

// Update ModelContainer to use migration plan
```

**OR (simpler for MVP):**
- Delete existing database
- Start fresh with new schema
- Add version check in app startup

---

## Testing Checklist

- [ ] All buttons are tappable with visual feedback
- [ ] Can add a meal with all fields (type, time, calories, notes, packaged flag)
- [ ] Can edit an existing meal
- [ ] Can delete a meal with swipe action
- [ ] Fasting window calculates correctly (last meal yesterday → first meal today)
- [ ] Can tap history entry to edit entire day
- [ ] Can modify all fields in edit mode
- [ ] Can delete daily log with confirmation
- [ ] Updated timestamps track correctly (createdAt vs updatedAt)
- [ ] UI matches PDF printable design
- [ ] Colors align with PDF palette
- [ ] Dark mode still works
- [ ] VoiceOver labels updated for new fields
- [ ] Dynamic Type works properly
- [ ] App icon updated with PDF-inspired design

---

## Implementation Order

### Phase 1: Data Model (15 mins)
1. Create `MealLog.swift`
2. Update `DailyLog.swift` (remove fastingWindow, add meals relation)
3. Update `PhotoLog.swift` (add mealLog relation)
4. Add createdAt/updatedAt timestamps
5. Implement fasting window computed property
6. Test data model changes compile

### Phase 2: Meal UI (20 mins)
1. Create `MealDetailView.swift`
2. Update `DailyCheckInView.swift`:
   - Remove fasting window text field
   - Add meals section
   - Add "Add Meal" button
   - Display calculated fasting window (read-only)
3. Test meal CRUD

### Phase 3: Edit/Delete Support (10 mins)
1. Update `HistoryTabView.swift` to make rows tappable
2. Add edit mode support to `DailyCheckInView`
3. Add delete confirmation
4. Test edit flows

### Phase 4: Button Fixes (5 mins)
1. Audit all button styles
2. Apply `.buttonStyle(.borderedProminent)`
3. Test all buttons are tappable

### Phase 5: Design Alignment (15 mins)
1. Extract colors/design from PDF
2. Update `AppTheme.swift`
3. Refine UI components
4. Create new app icon
5. Update Assets.xcassets

---

## Codex Prompt

```
Fix iOS app based on user feedback. Reference: IMPLEMENTATION-PLAN.md

CRITICAL CHANGES:
1. Remove manual fasting window input
2. Create MealLog model with full detail tracking
3. Auto-calculate fasting window (last meal yesterday → first meal today)
4. Add meal logging UI to daily check-in
5. Enable edit/delete for all entries
6. Fix all disabled buttons
7. Align design with PDF printable tracker

DATA MODEL:
- Create MealLog.swift (timestamp, type, notes, calories, isPackaged, photos)
- Update DailyLog: remove fastingWindow Int, add meals relation, add createdAt/updatedAt
- Update PhotoLog: add optional mealLog relation
- Add computed fastingWindow property to DailyLog

UI CHANGES:
- DailyCheckInView: Remove fasting field, add meals section, show auto-calc fasting
- Create MealDetailView for meal CRUD
- HistoryTabView: Make rows tappable → edit mode
- All buttons: use .buttonStyle(.borderedProminent)

DESIGN:
- Extract colors from design-reference/pdf-page1.png
- Update AppTheme.swift to match PDF palette
- Create app icon inspired by PDF cover

MIGRATION:
- Wipe existing data (fresh start)
- No backward compatibility needed

Build test-first. Write unit tests for:
- Fasting window calculation logic
- Meal CRUD operations
- Edit mode state management

Commit after each phase. Update BUILD-STATE.json when complete.
```

---

**Next:** Spawn Codex with this plan once PDF design is extracted.
