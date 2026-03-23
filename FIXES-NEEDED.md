# iOS App Fixes - User Feedback Round 1

**Date:** 2026-03-22  
**Tester:** digitalD  
**Status:** Pending implementation

## Issues to Fix

### 1. Buttons Disabled by Default ❌
**Problem:** Buttons appear disabled/unresponsive  
**Root Cause:** Likely missing `.buttonStyle()` or disabled state logic  
**Fix:**
- Review all button styles in DailyCheckInView, HomeView, etc.
- Ensure buttons are tappable and show proper visual feedback
- Add `.buttonStyle(.borderedProminent)` where appropriate
- Check for any unintended `.disabled()` modifiers

---

### 2. Fasting Window Auto-Calculation 🍽️
**Current:** Manual fasting window input (hours as number)  
**Desired:** Auto-calculate from meal timestamps

**Changes Required:**

#### A. Data Model Update (`DailyLog.swift`)
```swift
// REMOVE:
var fastingWindow: Int?  // manual hours input

// ADD:
var firstMealTime: Date?
var lastMealTime: Date?
var meals: [MealLog]  // relation to new MealLog model

// COMPUTED:
var fastingWindow: TimeInterval? {
    guard let first = firstMealTime, let last = lastMealTime else { return nil }
    // Calculate from last meal to next day's first meal
    // Or from last meal yesterday to first meal today
}
```

#### B. New Model: `MealLog.swift`
```swift
@Model
final class MealLog {
    var id: UUID
    var timestamp: Date
    var mealType: MealType  // breakfast, lunch, dinner, snack
    var notes: String?
    var isPackaged: Bool
    @Relationship var dailyLog: DailyLog?
}

enum MealType: String, Codable {
    case breakfast, lunch, dinner, snack
}
```

#### C. UI Changes (`DailyCheckInView.swift`)
**Remove:** "Fasting window" text field  
**Add:** Meal logging section
- "Add Meal" button
- List of meals logged today with timestamps
- Edit/delete for each meal
- Auto-display calculated fasting window (read-only, derived)

**Display Logic:**
- Show fasting window as: "14h 30m fasting" (calculated)
- Gray out if no meals logged yet
- Update in real-time as meals are added/edited

---

### 3. Edit/Delete Entries ✏️
**Current:** No way to modify past entries (except maybe in History?)  
**Required:** Full CRUD for daily logs

**Changes:**

#### A. History View Enhancement
- Each history item should be tappable → opens DailyCheckInView in EDIT mode
- Delete swipe action (already exists per Phase 5?)
- Confirm before delete

#### B. DailyCheckInView Edit Mode
- When opened from History, populate with existing data
- Change "Save" to "Update" when editing
- Allow changing any field
- Preserve creation timestamp, update modification timestamp

#### C. Data Model
```swift
// Add to DailyLog:
var createdAt: Date
var updatedAt: Date
```

---

### 4. Align with Notion Template Design 🎨

**Reference:** Notion "nudge Notes Tracker v2" template  
**Current colors:** Sage green (#8CA07A), warm neutral (#F5F1E8)  
**Goal:** Match Notion template aesthetic

#### Review Needed:
1. Check Notion template color scheme
2. Compare with current `AppTheme.swift`
3. Ensure consistency in:
   - Section headers
   - Card backgrounds
   - Form styling
   - Data visualization (charts, heatmap)

#### Specific Alignment:
- **Dashboard cards:** Match Notion database card style
- **Form sections:** Similar grouping as Notion properties
- **Typography:** Clean, minimal (already using SF)
- **Icons/Emoji:** Consider adding emoji labels like Notion (💧 for water, etc.)

**Question for Dan:** Do you have screenshots or can you share the Notion template URL so I can see the exact design?

---

## Implementation Plan

### Phase 1: Critical Fixes
1. Fix disabled buttons (quick win)
2. Add edit/delete functionality (high priority)

### Phase 2: Fasting Window Redesign
1. Create MealLog model
2. Update DailyLog schema (migration needed!)
3. Build meal logging UI
4. Implement auto-calculation logic
5. Update all views that reference fasting window

### Phase 3: Design Alignment
1. Audit Notion template design
2. Update AppTheme.swift
3. Refine UI components
4. Add emoji/icons where appropriate

---

## Questions for Dan

1. **Notion template access:** Can you share the template URL or screenshots so I can match the design exactly?

2. **Fasting window calculation:** Which approach?
   - Option A: Last meal yesterday → first meal today
   - Option B: Last meal today → next day's first meal (requires next-day data)
   - Option C: Simple time between last meal and first meal (same day only)

3. **Meal tracking detail:** How detailed?
   - Just timestamps + meal type?
   - Include notes/photos per meal?
   - Track packaged/processed flag (like Notion Food Log)?

4. **Migration strategy:** Existing test data will have `fastingWindow` as Int. Should we:
   - Migrate to new schema (data loss for fasting window)
   - Or keep old field and mark deprecated?

---

## Test Cases After Fixes

- [ ] All buttons are tappable and show visual feedback
- [ ] Can add multiple meals with timestamps
- [ ] Fasting window auto-calculates correctly
- [ ] Can tap any history entry to edit it
- [ ] Can modify all fields in edit mode
- [ ] Can delete entries with confirmation
- [ ] UI matches Notion template aesthetic
- [ ] Dark mode still works properly
- [ ] Accessibility labels updated for new fields

---

**Next:** Awaiting Dan's answers to questions, then spawn Codex to implement fixes.
