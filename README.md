# nudge Notes iOS

Calm, non-judgmental wellness tracking with a WHR-first focus.

## Stack

- SwiftUI
- SwiftData
- XCTest + XCUITest
- iOS 17.0+

## Project Structure

```text
nudgeNotes/
├── Models/
├── Resources/
├── Services/
├── ViewModels/
└── Views/
```

## Build

1. Generate the Xcode project with `xcodegen generate`.
2. Open `nudgeNotes.xcodeproj`.
3. Build or test with Xcode 26+.

## Testing Strategy

This project follows a test-first workflow:

- write failing tests before implementation
- keep model and view model logic covered in unit tests
- verify critical user journeys with UI tests
- keep phases green before moving forward

Phase 1 starts with fixtures and failing unit tests that define the expected model API before any model implementation is added.
