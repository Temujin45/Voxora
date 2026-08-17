# Voxora

Voxora is a lightweight, system-wide voice dictation app for macOS. Hold the **Right Option (⌥)** key, speak, and release it to transcribe your voice and paste the result wherever your cursor is active.

Built as a native menu-bar app with Swift, SwiftUI, and AppKit, Voxora keeps the interaction deliberately simple: one key, one compact visual indicator, and no separate transcription window.

> **Status:** Voxora v1 is a working personal project. It is not currently distributed through the Mac App Store.

## Features

- System-wide push-to-talk dictation using **Right Option**
- Native audio capture with `AVAudioEngine`
- Audio conversion to **16 kHz mono WAV** for transcription
- Speech-to-text through `mistralai/voxtral-mini-transcribe` via OpenRouter
- Automatic insertion at the active cursor
- Clipboard restoration after text is pasted
- API-key storage in the macOS Keychain
- Compact bottom-center recording indicator
- Reactive pink waveform that becomes dots when the input is quiet
- Native macOS menu-bar experience

## How it works

1. Voxora listens for the Right Option key globally.
2. Pressing and holding the key starts microphone capture.
3. `AVAudioEngine` records the input and Voxora converts it to a 16 kHz mono WAV file.
4. Releasing the key stops recording and sends the audio to OpenRouter.
5. OpenRouter routes the request to `mistralai/voxtral-mini-transcribe`.
6. Voxora temporarily places the returned transcription on the clipboard and pastes it at the active cursor using macOS Accessibility APIs and `CGEvent`.
7. The previous clipboard contents are restored.

```text
Right Option held
        ↓
AVAudioEngine capture
        ↓
16 kHz mono WAV
        ↓
OpenRouter → Voxtral transcription
        ↓
Clipboard + Accessibility paste
        ↓
Active application
```

## Interface

While recording, Voxora displays a small pill at the bottom center of the screen:

- Background: `#0D0D0D`
- Pink Voxora “V” mark
- Vertical divider
- Reactive waveform
- Quiet input represented as dots

The indicator stays out of the way and provides immediate feedback without interrupting the active application.

## Architecture and tech stack

- **Language:** Swift
- **UI:** SwiftUI and AppKit
- **Audio:** AVFoundation / `AVAudioEngine`
- **Global keyboard input:** macOS event monitoring
- **Text insertion:** Accessibility APIs, `CGEvent`, and `NSPasteboard`
- **Networking:** OpenRouter API
- **Transcription model:** `mistralai/voxtral-mini-transcribe`
- **Secret storage:** macOS Keychain
- **Security configuration:** Hardened Runtime enabled with Audio Input entitlement
- **Sandboxing:** App Sandbox disabled to support the current system-wide input workflow

## Requirements

- A Mac running a macOS version supported by the project’s deployment target
- A current version of Xcode compatible with that macOS version
- An [OpenRouter](https://openrouter.ai/) account and API key
- Microphone permission
- Accessibility permission
- An internet connection for transcription requests

## Setup and build

1. Clone the repository:

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. Open the `.xcodeproj` file in Xcode.

3. Select the Voxora app target and confirm that your development team is selected under **Signing & Capabilities**.

4. Confirm the target configuration:

   - **Hardened Runtime:** On
   - **Audio Input:** Enabled
   - **App Sandbox:** Off
   - A microphone usage description is present in the app’s Info settings

5. Build and run with **Product → Run** or `⌘R`.

For a standalone release build:

1. Open **Product → Scheme → Edit Scheme**.
2. Select **Run** and set **Build Configuration** to **Release**.
3. Build with `⌘B`.
4. Choose **Product → Show Build Folder in Finder**.
5. Find the compiled `.app` in the Release products folder and copy it to `/Applications`.

Signing or rebuilding the app can cause macOS to treat it as a new app instance. If dictation stops working after a rebuild, remove the old permission entry and grant access again.

## OpenRouter API-key configuration

On first launch, use Voxora’s API-key configuration UI to enter an OpenRouter API key. The key is stored in the macOS Keychain rather than in the source code or a plain-text preferences file.

Create and manage keys from the [OpenRouter Keys](https://openrouter.ai/keys) page.

Do not commit API keys to Git, add them directly to Swift source files, or include them in screenshots and issue reports. If a key is exposed, revoke it in OpenRouter and create a replacement.

## Permissions

Voxora needs two macOS permissions:

### Microphone

Required to record speech.

Go to **System Settings → Privacy & Security → Microphone**, then enable Voxora.

### Accessibility

Required to monitor the push-to-talk key and paste transcribed text into the active application.

Go to **System Settings → Privacy & Security → Accessibility**, then enable Voxora.

You may need to quit and reopen Voxora after changing permissions. Development and installed builds may require separate approvals because macOS can identify them as different signed applications.

## Privacy and security

- Audio is recorded only while the Right Option key is held.
- Recorded audio is sent to OpenRouter for transcription by the configured model. Review [OpenRouter’s privacy policy](https://openrouter.ai/privacy) and the applicable model-provider terms before using Voxora with sensitive information.
- The OpenRouter API key is stored in the macOS Keychain.
- Transcribed text briefly uses the system clipboard for insertion. Voxora restores the prior clipboard contents after pasting.
- Voxora requires powerful Accessibility access. Only run builds you trust, and revoke access in System Settings when it is no longer needed.
- Voxora is not intended for passwords, authentication codes, regulated data, or other highly sensitive content without an independent security review.

## Cost

Using Voxora can incur OpenRouter model and API charges. Pricing and model availability can change, so check the current model listing and your OpenRouter usage dashboard before relying on any cost estimate. Voxora itself does not remove or replace those provider charges.

## Current v1 status

Voxora v1 implements the complete core workflow:

- Hold Right Option to record
- Release to transcribe
- Paste at the active cursor
- Restore the clipboard
- Store the API key securely
- Show a compact reactive recording indicator

As an early personal release, v1 may still have rough edges around permission resets, network failures, audio-device changes, app compatibility, and code signing. Back up working releases before changing signing settings or entitlements.

## Roadmap

Possible future improvements include:

- Configurable push-to-talk shortcut
- Transcription history with opt-in local storage
- Clearer error and connection-state feedback
- Automatic retry and improved offline handling
- Input-device selection
- Language and model selection
- Custom vocabulary and text replacements
- Launch-at-login support
- Signed and notarized distribution
- Automated tests and a reproducible release workflow

## Contributing

Voxora is currently a personal v1 project. Issues and pull requests are welcome if public contribution is enabled for this repository. Please do not include API keys, private transcriptions, or recorded audio in bug reports.

## License

No license has been selected yet. Until a `LICENSE` file is added, all rights are reserved and no permission is granted to copy, modify, or distribute this project.

Replace this section when a license is chosen (for example, MIT, Apache-2.0, or a proprietary license).
