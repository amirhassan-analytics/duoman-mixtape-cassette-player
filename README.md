# MixShare (`mixtape`)

A tactile cassette and mixtape player built in SwiftUI for dual-screen **iPhone Duo** layouts, pairing nostalgic Walkman-inspired controls and sound effects with modern playlist and voice-note workflows.

## Key Features
- **Closed Cover & Tent Mode**: Walkman-style controls (`REW`, `PLAY`, `FF`, `RELOAD / EJECT`, and `Side A / Side B` switching) tailored for dual-screen postures.
- **Side A & Side B Mixtapes**: Organize mixtapes across Side A and Side B with support for curated tracks (up to 7 songs per side) and 30-minute side capacity.
- **Voice Notes & Cover Studio**: Record short voice messages (capped at 30 seconds with privacy/GDPR considerations) and customize tape cover titles and styling.
- **Tactile Audio Feedback**: Real mechanical button click and analog tape static/hiss audio cues.

## Project Structure & Tech Stack
- **Platform**: iOS / iPhone Duo (`mixtape` Xcode project)
- **UI & Architecture**: SwiftUI (`App`, `Components`, `Models`, `Services`, `ViewModels`, `Views`, `Sounds`, `Assets`)
- **Frameworks**: SwiftUI, AVFoundation / AudioToolbox, MusicKit *(update with the exact frameworks used in your target)*

## Current Prototype Status & Known Issues
- Core cassette playback, Side A/B views, tape selection, and mixtape creation flows are under active development.
- **Known prototype issues**:
  - App extension lookup error during certain flows.
  - Multi-display selection prompt when targeting a specific display ID on dual-screen setups.

## Security & Version Control
- Keep secrets, signing credentials, and restricted media out of public branches before publishing.
