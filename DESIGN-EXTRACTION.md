# Design Extraction from PDF Printable Tracker

## Color Palette

### Primary Colors
- **Blue (Primary):** `#2B7FDB` - Used for links, checkmarks, primary text
- **Mint/Teal (Accent):** `#7DD3C0` - Arrow graphics, accents, plus pattern
- **Black:** `#1A1A1A` - Main text, headers

### Background Colors
- **Light Mode Background:** `#FFFFFF` or `#FAFAFA` - Clean white
- **Subtle Gray:** `#F5F5F5` - For cards/sections

### Water Droplet Icon
- Uses 💧 emoji (already implemented!)

## Typography

### Logo/Branding
- **"nudge":** Bold, blue (#0066CC), sans-serif (all lowercase)
- **"Notes":** Handwriting style, black
- **Tagline:** "My gentle accountability journal" - clean sans-serif

### Tracker Headers
- **"Daily Tracker":** Handwriting/script font style
- **Section labels:** ALL CAPS, sans-serif, medium weight
- **Field labels:** Sentence case, underlined fields

## Layout Patterns

### Tracker Page (Page 1)
- Top: Date + day of week
- Left column: Waist, Hips measurements
- Right column: Weight, WHR
- **Food section:** Two-column checklist with underscores
  - Note: "Mark the check box for Packaged/processed food items"
- **Meal times:** First meal / Last meal with timestamps
- **Metrics:** Hours slept, Steps count (of 10000), Water intake (droplet icons)
- **Healthy habits:** Checkbox list
- **Reflection:** Open-ended text area

### Cover Page (Page 2)
- **Logo:** Large "nudge" text with arrow graphic
- **Notebook graphic:** Spiral-bound notepad illustration
- **Paper airplane:** Dotted trail graphic
- **Icon row:** 5 wellness icons (fitness, nutrition, meditation, weight, hydration)
- **Background pattern:** Light mint plus signs (+) scattered

## Icons/Emoji Used

- 💧 Water droplet (repeated for intake tracking)
- ✓ Checkmarks (blue, in checkboxes)
- Plus signs (+) for decorative background pattern
- Illustrations: paper airplane, notebook, wellness icons

## App Icon Concept

Based on Page 2 cover design:

### Option A: "nudge" Logo
- Blue "nudge" text
- Mint arrow accent
- White or light background
- Rounded square app icon format

### Option B: Notebook
- Spiral notebook illustration
- "nudge Notes" text overlay
- Paper airplane element
- Light background with plus pattern

### Option C: Minimal
- Single large "n" from "nudge"
- Arrow graphic integrated
- Blue + mint color scheme
- Clean, modern

**Recommendation:** Option A (logo-focused) for brand recognition

## Design System for iOS App

### Colors to Update in AppTheme.swift

```swift
enum AppTheme {
    // Primary brand colors
    static let nudgeBlue = Color(hex: "#2B7FDB")  // Primary blue
    static let mint = Color(hex: "#7DD3C0")       // Mint/teal accent
    
    // Light mode
    static let lightBackground = Color(hex: "#FAFAFA")
    static let lightCard = Color(hex: "#FFFFFF")
    
    // Dark mode (adapt primary colors)
    static let darkBackground = Color(hex: "#1A1A1A")
    static let darkCard = Color(hex: "#2A2A2A")
    
    // Adaptive (switches based on light/dark)
    static let accent = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#7DD3C0")  // Mint in dark mode
                : UIColor(hex: "#2B7FDB")  // Blue in light mode
        }
    )
    
    static let background = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#1A1A1A")
                : UIColor(hex: "#FAFAFA")
        }
    )
    
    static let cardBackground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(hex: "#2A2A2A")
                : UIColor(hex: "#FFFFFF")
        }
    )
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: 1
        )
    }
}

extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }
}
```

### Typography Patterns

- **Headers:** Bold, slightly larger
- **Labels:** ALL CAPS for section headers (e.g., "FOOD ITEMS/GROUPS CONSUMED")
- **Body:** Clean sans-serif (SF Pro works well)
- **Numbers:** Tabular numerals for alignment

### UI Element Patterns

- **Water tracking:** Use 💧 emoji (already done!)
- **Checkboxes:** Blue checkmarks
- **Input fields:** Underlined style (can use TextField with underline border)
- **Sections:** Clear separation with headers
- **Reflection/Notes:** Larger text area with subtle border

### App Icon Specifications

**iOS Requirements:**
- 1024x1024 master (App Store)
- Multiple sizes for devices (generated automatically by Xcode)

**Recommended Icon:**
- Background: White or very light mint (#F0FAF8)
- Foreground: Bold blue "n" or full "nudge" text
- Accent: Mint arrow or plus pattern
- Rounded corners (handled by iOS)

---

## Implementation Checklist

- [ ] Update AppTheme.swift with new color palette
- [ ] Add hex color extension helpers
- [ ] Create app icon asset (1024x1024)
- [ ] Export all required icon sizes
- [ ] Update Assets.xcassets
- [ ] Test in light mode
- [ ] Test in dark mode
- [ ] Verify accessibility (color contrast)
- [ ] Build and test

---

**Source Files:**
- `design-reference/pdf-page1.png` - Tracker layout
- `design-reference/pdf-page2.png` - Cover/branding
