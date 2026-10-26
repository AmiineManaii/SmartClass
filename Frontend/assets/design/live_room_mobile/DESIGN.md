# SmartClass Live Room — Mobile Design Specification

## 1. Overview & Mobile-First Strategy

The Mobile Live Room experience is tailored for smartphones (portrait default: 360px–430px width, 740px–932px height) and tablets, prioritizing **single-handed thumb reach**, **low cognitive overload**, and **instant interaction** during live lectures and interactive seminars.

### Key Mobile Principles
- **Portrait-First Stage Focus**: The active speaker or shared presentation occupies the top 55–65% of the viewport, maintaining an optimal 16:9 aspect ratio without vertical stretching or letterboxing letter bars.
- **Thumb-Zone Controls**: All interactive controls are anchored within the bottom 120px thumb arc of the device screen, ensuring one-handed reachability on modern large smartphones (e.g. 6.7" displays).
- **Non-Intrusive Bottom Sheets**:
  - Live chat and participant lists do not compress or shrink the active video stream into an unusable thumbnail; instead, they slide up as swipeable modal bottom sheets (`showModalBottomSheet` with drag handles).
  - While chat is open, a compact audio wave / mini-stage pill persists at the top so the student never loses visual feedback of who is speaking.
- **Picture-in-Picture Self Preview**: The local user's camera feed floats as an draggable overlay card in the bottom-right corner (or top-right during landscape).
- **Safe Area Padding**: Explicit compliance with iOS notch / Dynamic Island and Android navigation bars using `SafeArea` margins.

---

## 2. Design Tokens & Styling Guide

| Token | Mobile Value | Usage |
|---|---|---|
| `surface` | `#0B0F19` | Deep black background maximizing contrast and OLED battery efficiency |
| `surface-container` | `#151B2B` | Bottom sheet backgrounds, header bar |
| `surface-container-high` | `#1E2638` | Control button circles, message bubbles |
| `primary` | `#122675` | Academic badge color |
| `secondary` | `#4056B9` | Active buttons, highlighted state |
| `error` | `#DC2626` | End session danger button, muted mic icon |
| `tertiary-fixed` | `#83F8CD` | Active audio pulse |
| `border-radius` | `24px` / `full` | Pill-shaped thumb controls, sheet top corners |

---

## 3. Mobile Component Inventory

1. **MobileHeaderBar (56px)**:
   - Compact back/minimize chevron.
   - Class Group and Title marquee.
   - Live pill with glowing red indicator (`EN DIRECT`).
   - Elapsed timer (`00:34`).
   - Camera flip icon (Switch front/back camera).
2. **HeroVideoStage**:
   - 16:9 video frame with rounded borders (`16px`).
   - Active speaker tag pinned to bottom-left with animated mic meter.
   - Draggable Local Camera PiP tile (`90px × 120px`).
3. **ParticipantStrip (Horizontal swipe)**:
   - Compact scrollable strip of attending peers with raised hand indicators.
4. **BottomControlBar**:
   - Circular action buttons (52px diameter):
     - Mic Toggle (Green active / Red slash muted)
     - Camera Toggle (Green active / Red slash off)
     - Raise Hand Button (Amber glow when raised)
     - Chat Button with unread indicator dot
     - Leave / End session icon button (Clearly differentiated by color: grey for Leave, deep red for End for everyone)
5. **MobileChatSheet**:
   - Swipeable bottom sheet with 60% and 90% snap heights.
   - Chat history with sender avatars, timestamps, and compact composer.

---

## 4. State Variants & Error Handling

- **Camera/Mic Denied**: Bottom snackbar with "Accès caméra requis" and direct button to OS App Settings.
- **Poor Network / Audio-Only Mode**: Automatically disables incoming video rendering on mobile cellular networks to preserve bandwidth, switching to animated speaker avatar.
- **Incoming Call / Interruption**: Graceful WebRTC audio ducking and resume via `AudioTrack` routing.
