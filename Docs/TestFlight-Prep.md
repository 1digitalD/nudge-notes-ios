# TestFlight Prep

## Code Signing Notes

- Use bundle identifier `com.henkanhacks.nudgenotes`.
- In Xcode, sign the `nudgeNotes` target with the production Apple Developer team.
- Enable `Automatically manage signing` for Debug and Release until a dedicated export profile is needed.
- Confirm the App ID has In-App Purchase enabled before archiving.

## App Store Connect Setup

- Create the app record as `nudge Notes`.
- Category: Health & Fitness.
- Add the two auto-renewable subscriptions:
  - `com.henkanhacks.nudgenotes.pro.monthly`
  - `com.henkanhacks.nudgenotes.pro.yearly`
- Mirror the same pricing already used in the local StoreKit config:
  - Monthly: $4.99
  - Yearly: $39.99
- Add sandbox testers before validating purchases on device.
- Provide the privacy policy URL from the draft in `Docs/Privacy-Policy.md` once it is hosted.

## Screenshot Guide

- Primary device set:
  - 6.9-inch display: iPhone 16 Pro Max simulator
  - 6.3-inch display: iPhone 16 Pro simulator
- Capture these screens in light and dark appearance:
  - Home dashboard with logged data
  - Daily check-in form
  - History heatmap and monthly review
  - Insights chart
  - Pro upgrade modal
- Before screenshots:
  - Seed an onboarded profile
  - Add at least 14 days of logs and 3 WHR entries
  - Use a Pro profile so Insights and CSV export are unlocked

## Beta Instructions

- Archive from Xcode with the Release configuration.
- Upload the build to App Store Connect.
- Add internal testers first, then external testers once subscription metadata is approved.
- Ask testers to verify:
  - onboarding and relaunch persistence
  - check-in, WHR, and photo flows
  - monthly review and CSV export
  - Pro purchase, restore, and Insights unlock
- Keep one tester on a fresh sandbox account specifically for StoreKit restore coverage.
