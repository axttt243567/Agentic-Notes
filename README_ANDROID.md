Android testing checklist

Permissions
- Declared in AndroidManifest.xml (release):
  - android.permission.INTERNET
  - android.permission.RECORD_AUDIO
- Requested at runtime in CallPage using permission_handler.

Run on device
1) Enable Developer Options and USB debugging on your phone.
2) Connect via USB and accept RSA prompt.
3) In VS Code, select the Android device from the status bar.
4) Run the app in Debug.

First call
- Tap the phone icon in Chat.
- Grant microphone permission when prompted.
- You should see Connecting… then Live call with a running timer.

Notes
- This build uses a stub LiveService—no real audio I/O yet. Replace with flutter_webrtc + Gemini Live when ready.