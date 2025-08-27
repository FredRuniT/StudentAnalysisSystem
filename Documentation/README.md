# Student Analysis System Documentation

## Quick Links

### Build & Development
- [XcodeGen Configuration Guide](Build/XcodeGen-Configuration.md) - **MUST READ** for Xcode builds
- [Build Issues Troubleshooting](Troubleshooting/Build-Issues.md) - Common build problems and solutions

### Architecture
- Module dependency hierarchy and structure (coming soon)
- Data flow and processing pipeline (coming soon)

## Documentation Structure

```
Documentation/
├── README.md                    # This file
├── Build/                       # Build configuration and setup
│   └── XcodeGen-Configuration.md
├── Troubleshooting/            # Problem-solving guides
│   └── Build-Issues.md
└── Architecture/               # System design documentation
```

## Key Points for Developers

### 🚨 Critical Build Information
This project uses a modular Swift Package structure with XcodeGen. The most common build issue is incorrect `project.yml` configuration. 

**Before building in Xcode:**
1. Ensure `project.yml` is correctly configured (see [XcodeGen Configuration Guide](Build/XcodeGen-Configuration.md))
2. Run `xcodegen generate` after any project structure changes
3. Clean derived data if you encounter "No such module" errors

### Build Commands

```bash
# Standard workflow
xcodegen generate              # Generate Xcode project
swift build                    # Build Swift package
xcodebuild -scheme StudentAnalysisSystem-Mac build  # Build Mac app

# If you encounter issues
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData/StudentAnalysisSystem-*
xcodegen generate
swift build
```

## Contributing Documentation

When adding new documentation:
1. Place it in the appropriate subdirectory
2. Update this README with a link
3. Keep documentation concise and solution-focused
4. Include examples where applicable