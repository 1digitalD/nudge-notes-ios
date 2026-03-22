# nudge Notes iOS App - Build Instructions for Codex

## Project Overview
Build a **test-first iOS app** for gentle habit tracking with WHR (waist-to-hip ratio) focus.

**App Name:** nudge Notes  
**Subtitle:** WHR & Habit Tracker  
**Bundle ID:** com.henkanhacks.nudgenotes  
**Min iOS:** 17.0  
**Framework:** SwiftUI + SwiftData

## Core Philosophy
- **Calm, non-judgmental tone** - no streaks, no guilt, no gamification
- **WHR-first** - unique value proposition
- **Test-driven** - write tests before implementation
- **Clean architecture** - Models, Views, ViewModels, clear separation

## Build Order (Test-First!)

### Phase 0: Project Setup ✅
1. Initialize Xcode project: "nudgeNotes"
2. Add .gitignore for Xcode/Swift
3. Create folder structure:
   ```
   nudgeNotes/
   ├── Models/
   ├── Views/
   ├── ViewModels/
   ├── Services/
   ├── Resources/
   └── Tests/
       ├── ModelTests/
       ├── ViewModelTests/
       └── UITests/
   ```
4. Initialize git, commit initial project
5. Push to: https://github.com/1digitalD/nudge-notes-ios

### Phase 1: Testing Framework (DO THIS FIRST!)
**Write tests BEFORE implementation!**

1. Set up XCTest target
2. Set up XCTestUI target  
3. Create test fixtures:
   ```swift
   // TestFixtures.swift
   struct WHRTestData {
       static let sample1 = WHREntry(date: Date(), waist: 85, hip: 95, ratio: 0.89)
       static let healthyFemale = WHREntry(date: Date(), waist: 70, hip: 95, ratio: 0.74)
       // etc.
   }
   ```
4. Write model tests (RED state - tests fail, no models yet)
5. Document testing strategy in README.md
6. **Commit:** "Add testing framework + fixtures"

### Phase 2: Data Models
**Test-first: Models must pass all tests from Phase 1**

Models to create:

1. **WHREntry**
   ```swift
   @Model
   class WHREntry {
       var id: UUID
       var date: Date
       var waist: Double  // cm
       var hip: Double    // cm
       var ratio: Double  // computed: waist/hip
       var category: WHRCategory  // enum: healthy, moderate, high
       
       // Methods: calculateCategory(), isHealthy()
   }
   ```

2. **DailyLog**
   ```swift
   @Model
   class DailyLog {
       var id: UUID
       var date: Date
       var sleepHours: Double?
       var sleepQuality: Int?  // 1-5
       var movement: Bool?
       var steps: Int?
       var waterGlasses: Int?
       var nutritionQuality: Int?  // 1-5
       var fastingWindow: Int?  // hours
       var mood: Int?  // 1-5
       var stress: Int?  // 1-5
       var notes: String?
       var photos: [PhotoLog]?
   }
   ```

3. **HabitEntry**
   ```swift
   @Model
   class HabitEntry {
       var id: UUID
       var name: String
       var type: HabitType  // enum: binary, numeric, timer
       var value: Double?
       var completed: Bool
       var date: Date
   }
   ```

4. **PhotoLog**
   ```swift
   @Model
   class PhotoLog {
       var id: UUID
       var date: Date
       var category: PhotoCategory  // enum: meal, activity, body
       @Attribute(.externalStorage) var imageData: Data?
       var notes: String?
   }
   ```

5. **UserProfile**
   ```swift
   @Model
   class UserProfile {
       var id: UUID
       var onboardingCompleted: Bool
       var isPro: Bool
       var createdAt: Date
       var goals: [String]
   }
   ```

**SwiftData Setup:**
- ModelContainer configuration
- Migration strategy for future schema changes

**Deliverable:** All model tests GREEN ✅

**Commit:** "Add data models + persistence (all tests pass)"

### Phase 3: Onboarding Flow
**UI Tests first!**

Screens:
1. **WelcomeView** - Brand intro, "Get Started" CTA
2. **WHRExplainerView** - "Why WHR?" education
3. **GoalSelectionView** - Select 1-3 wellness goals
4. **PermissionsView** - Request photo/notification access
5. **OnboardingCompletionView** - Set onboarded=true in UserProfile

**Design System:**
- Colors: Soft beige (#F5F1E8), sage green (#A8B5A0)
- Fonts: SF Pro (system font)
- Buttons: Rounded, 16px radius, soft shadows

**UI Tests:**
```swift
func testOnboardingFlow() {
    // Test complete flow: Welcome → Explainer → Goals → Permissions → Complete
    // Assert: UserProfile.onboardingCompleted == true
}
```

**Commit:** "Add onboarding flow (UI tests pass)"

### Phase 4: Core Tracking
**Critical features - heavily tested!**

1. **HomeView**
   - Date picker
   - "Check in for today" CTA (large button)
   - Summary cards (WHR, days logged, current streak)
   - Bottom tab bar (Home, History, Insights, Settings)

2. **DailyCheckInView**
   - All fields from DailyLog model
   - Sliders for quality ratings (1-5)
   - Number inputs for numeric values
   - Photo attachment button
   - Save & dismiss

3. **WHRCalculatorView**
   - Waist input (cm)
   - Hip input (cm)
   - Auto-calculate ratio
   - Category indicator (color-coded: green/yellow/red)
   - Save to SwiftData

4. **PhotoLoggingView**
   - Camera picker
   - Photo library picker
   - Category selection (meal/activity/body)
   - Save with metadata

**Data Flow:**
- ViewModels handle business logic
- SwiftData persistence
- Pull-to-refresh on HomeView

**UI Tests:**
- Test daily check-in flow (fill all fields, save, verify persistence)
- Test WHR calculation accuracy
- Test photo logging

**Commit:** "Add core tracking features (all tests pass)"

### Phase 5: Review & History
1. **MonthlyReviewView**
   - Reflection questions (editable text fields)
   - Summary of past month
   - Goal setting for next month

2. **CalendarView**
   - Heatmap showing logged days
   - Tap to navigate to specific day

3. **HistoryListView**
   - List of past DailyLogs
   - Searchable
   - Swipe to delete (with confirmation)
   - Tap to edit

4. **CSV Export** (Pro feature)
   - Export all data to CSV
   - Share sheet

**Commit:** "Add review & history features"

### Phase 6: Pro Features (IAP)
**StoreKit 2 setup:**

1. **Product Configuration**
   ```swift
   // Products
   - "pro_monthly": $4.99/month
   - "pro_yearly": $39.99/year (save 33%)
   ```

2. **ProUpgradeView**
   - Feature comparison (Free vs Pro)
   - Monthly/Yearly toggle
   - "Start Free Trial" button (7 days)
   - Restore purchases button

3. **Purchase Flow**
   - Handle transactions
   - Receipt validation (local for MVP)
   - Update UserProfile.isPro

4. **Pro-Gated Features**
   - Insights screen
   - Photo analysis (future AI feature)
   - CSV export
   - Unlimited photo storage

**Testing:** Use Sandbox tester accounts

**Commit:** "Add IAP + Pro features (sandbox tested)"

### Phase 7: Insights (Pro)
1. **InsightsView**
   - WHR trend chart (Swift Charts)
   - Weekly summaries
   - Gentle nudges (non-judgmental copy)

2. **Pattern Detection**
   - Identify correlations (e.g., "Sleep <6h → stress 4+")
   - Basic stats (averages, consistency)

**Copy Tone:**
- ✅ "Your WHR has been steady this month"
- ✅ "You logged 18 out of 30 days—nice consistency"
- ❌ "Don't break your streak!"
- ❌ "You failed to log yesterday"

**Commit:** "Add insights screen (Pro)"

### Phase 8: Polish
1. **App Icon**
   - Export all sizes (AppIcon.appiconset)
   - Design: Minimalist, warm tones, "n" lettermark

2. **Launch Screen**
   - Simple, branded

3. **Dark Mode**
   - Full support (test both light/dark)

4. **Accessibility**
   - VoiceOver labels
   - Dynamic Type support
   - Color contrast (WCAG AA)

5. **Performance**
   - Optimize image loading
   - Lazy views where appropriate

**Commit:** "Add polish + accessibility"

### Phase 9: TestFlight Prep
1. **App Store Connect Setup**
   - Create app record
   - Add description, keywords, category (Health & Fitness)
   - Upload privacy policy URL

2. **Code Signing**
   - Configure signing in Xcode
   - Development + Distribution profiles

3. **Build Archive**
   - Increment build number in BUILD-STATE.json
   - Archive for iOS
   - Upload to TestFlight

4. **Beta Testing Instructions**
   - Create internal testing group
   - Write test instructions

**Commit:** "Prepare for TestFlight v0.1.0"

## Quality Gates

Before completing each phase:
- [ ] All tests passing (GREEN)
- [ ] Code committed to GitHub
- [ ] Todoist tasks updated
- [ ] BUILD-STATE.json updated
- [ ] No compiler warnings
- [ ] No force-unwraps (use guard/if let)

## Style Guidelines

**SwiftUI Best Practices:**
- Use `@State`, `@Binding`, `@Environment` appropriately
- Extract reusable components
- Prefer composition over inheritance
- Use `@Observable` for ViewModels (iOS 17+)

**Error Handling:**
- Never crash on bad input
- Show user-friendly error messages
- Log errors for debugging

**Persistence:**
- Use SwiftData queries efficiently
- Handle migration gracefully
- Don't block main thread

## When Finished

1. Update BUILD-STATE.json with final status
2. Run all tests one more time (green checkmark ✅)
3. Create GitHub release tag: v0.1.0
4. Update Todoist: Mark Phase 0-9 complete
5. Notify via: `openclaw system event --text "nudge Notes iOS MVP complete! All tests passing, ready for TestFlight." --mode now`

## Notes

- Commit frequently (every 30-60 min)
- Write descriptive commit messages
- If you get stuck, document blocker in BUILD-STATE.json
- Keep README.md updated with setup instructions

---

**Remember:** TEST FIRST! Write tests before implementation. Green tests = done.
