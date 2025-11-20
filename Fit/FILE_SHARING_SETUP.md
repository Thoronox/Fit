# Making Exported Files Visible in File Picker

## Solution

To make exported data files visible in the iOS file picker, you need to enable File Sharing in your app's configuration.

## Steps to Enable File Sharing

### Option 1: Using Xcode UI (Recommended)

1. **Open your project** in Xcode
2. **Select the Fit target** in the project navigator
3. **Go to the Build Settings tab**
4. **Search for "File Sharing"** in the search bar
5. **Set "Application supports iTunes file sharing" to YES**
   - Look for the key: `UIFileSharingEnabled`
6. **Also enable "Supports opening documents in place"**
   - Look for the key: `LSSupportsOpeningDocumentsInPlace` and set to YES
7. **Build and run the app**

### Option 2: Manually Edit Info.plist

If you prefer to edit via code:

1. Right-click on your project in Xcode
2. Select "Open as > Source Code"
3. Add the following keys to the root `<dict>`:

```xml
<key>UIFileSharingEnabled</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

## What These Settings Do

- **UIFileSharingEnabled (YES)**: Makes your app's Documents folder visible in the Files app and file pickers
- **LSSupportsOpeningDocumentsInPlace (YES)**: Allows the app to open files directly from cloud storage

## After Enabling File Sharing

Once you enable these settings:

1. **Export files** from your app using the "Export to File" button
2. **Files are saved** to: `~/Documents/fit_export_YYYY-MM-DD_HH-MM-SS.json`
3. **Files become visible** in:
   - The Files app on your device
   - The file picker in your Fit app's "Import from File" button
4. **You can then import** any exported file using the file picker

## Testing

1. Build and run the app
2. Tap "Export to File" - this saves a file to Documents
3. Tap "Import from File" - the file picker should now show your exported file
4. Select the file to import it

## File Picker Locations

When you open the file picker, you can navigate to:
- **On My iPhone/iPad** → Fit → (your exported files will appear here)

Or:
- **Recents** section may show recently used files

## Troubleshooting

If files still don't show:
1. Verify the Info.plist keys are set correctly
2. Clean build folder (Cmd + Shift + K)
3. Restart Xcode
4. Reinstall the app on your device/simulator
5. Check Files app to confirm Documents folder contains .json files
