# Resurface - Xcode Project Setup

This guide walks you through setting up the Xcode project for Resurface.

## Prerequisites

- macOS with Xcode 15.0+
- Apple Developer Account (for device testing)
- iOS 17.0+ deployment target

## Step 1: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Configure:
   - Product Name: `Resurface`
   - Team: Your development team
   - Organization Identifier: `com.yourname` (or your identifier)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
   - ✅ Include Tests
5. Save to `~/Projects/Resurface/` (replace existing if prompted)

## Step 2: Add Share Extension Target

1. File → New → Target
2. Select **iOS** → **Share Extension**
3. Configure:
   - Product Name: `ShareExtension`
   - ✅ Embed in Application: Resurface
4. When prompted to activate scheme, click "Activate"

## Step 3: Configure App Group

### Enable App Group Capability

For **both** the main app and Share Extension targets:

1. Select target in Project Navigator
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability"
4. Add "App Groups"

5. Click "+" under App Groups
6. Add: `group.com.keenanmeyer.resurface`

### Verify Entitlements

Ensure both targets have the App Group in their entitlements:

**Resurface/Resurface.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>ok
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.keenanmeyer.resurface</string>
    </array>
</dict>
</plist>
```

**ShareExtension/ShareExtension.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.keenanmeyer.resurface</string>
    </array>
</dict>
</plist>
```

## Step 4: Configure Share Extension Info.plist

Update `ShareExtension/Info.plist` to support all content types:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <dict>
            <key>NSExtensionActivationSupportsWebURLWithMaxCount</key>
            <integer>1</integer>
            <key>NSExtensionActivationSupportsImageWithMaxCount</key>
            <integer>10</integer>
            <key>NSExtensionActivationSupportsText</key>
            <true/>
            <key>NSExtensionActivationSupportsFileWithMaxCount</key>
            <integer>10</integer>
        </dict>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

Or for a simpler activation rule that accepts almost anything:

```xml
<key>NSExtensionActivationRule</key>
<string>TRUEPREDICATE</string>
```

(Note: Apple may reject apps with TRUEPREDICATE, so define specific rules for production)

## Step 5: Replace Default Files with Source Code

### Delete Default Files

Delete the auto-generated files that Xcode created:
- `Resurface/ContentView.swift` (will be replaced)
- `Resurface/ResurfaceApp.swift` (will be replaced)
- `ShareExtension/ShareViewController.swift` (will be replaced)
- `ShareExtension/MainInterface.storyboard` (we use SwiftUI)

### Add Source Files

Drag and drop the source files from this project into Xcode:

**Main App (Resurface target):**
- `Resurface/ResurfaceApp.swift`
- `Resurface/ContentView.swift`
- `Resurface/Models/*.swift`
- `Resurface/Views/**/*.swift`

**Share Extension (ShareExtension target):**
- `ShareExtension/ShareViewController.swift`
- `ShareExtension/ContentExtractors/*.swift`

**Shared (both targets):**
- `Shared/Services/**/*.swift`

### Configure Target Membership

For files in `Shared/`:
1. Select each file
2. In File Inspector, check both "Resurface" and "ShareExtension" under Target Membership

## Step 6: Update Share Extension Principal Class

Since we're using SwiftUI, update the extension's Info.plist:

1. Remove: `NSExtensionMainStoryboard` key
2. Add:
```xml
<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).ShareViewController</string>
```

## Step 7: Build & Run

1. Select the "Resurface" scheme
2. Select a simulator or device
3. Press Cmd+R to build and run

### Test Share Extension

1. Run the app once to install it
2. Open Safari and navigate to any webpage
3. Tap the Share button
4. Find "Resurface" in the share sheet (you may need to scroll or tap "More")
5. Tap to share

## Troubleshooting

### "App Group container not accessible"

- Verify App Group is enabled in Signing & Capabilities for both targets
- Ensure the group identifier matches exactly: `group.com.keenanmeyer.resurface`
- Clean build folder (Cmd+Shift+K) and rebuild

### Share Extension doesn't appear

- Ensure the extension is embedded in the app (Target → General → Frameworks, Libraries, and Embedded Content)
- Check the activation rules in Info.plist
- Restart the simulator/device

### SwiftData errors

- Ensure minimum deployment target is iOS 17.0
- Check that all model files have `import SwiftData`

### Share Extension crashes

- Check Console.app for logs
- Ensure all files are added to ShareExtension target membership
- Verify the principal class is set correctly

## Next Steps

After setup is complete:

1. **Test capturing content** from various apps
2. **Verify data persistence** - items should appear in the main app
3. **Phase 2**: Add AI processing with Claude API

## File Structure After Setup

```
Resurface.xcodeproj
├── Resurface/
│   ├── ResurfaceApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   │   ├── BookmarkItem.swift
│   │   ├── WebContent.swift
│   │   └── Category.swift
│   └── Views/
│       ├── Home/
│       │   └── HomeView.swift
│       ├── Library/
│       │   └── LibraryView.swift
│       ├── Search/
│       │   └── SearchView.swift
│       ├── Detail/
│       │   ├── BookmarkDetailView.swift
│       │   └── CategoryDetailView.swift
│       ├── Settings/
│       │   └── SettingsView.swift
│       └── Components/
│           └── BookmarkRowView.swift
├── ShareExtension/
│   ├── ShareViewController.swift
│   └── ContentExtractors/
│       ├── ContentExtractor.swift
│       ├── ContentExtractorRegistry.swift
│       ├── URLExtractor.swift
│       ├── ImageExtractor.swift
│       └── TextExtractor.swift
├── Shared/
│   └── Services/
│       └── Storage/
│           └── AppGroupContainer.swift
└── docs/
    ├── PLANNING.md
    ├── ARCHITECTURE.md
    ├── REQUIREMENTS.md
    └── COMPETITIVE_ANALYSIS.md
```
