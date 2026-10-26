# SmartClass Live Room — Desktop & Web Design Specification

## 1. Overview & Layout Strategy

The Web/Desktop Live Room experience is tailored for wide viewports (min-width: 1024px, optimized for 1280px–1920px+). It provides an immersive academic lecture and interactive seminar experience adhering strictly to the **SmartClass Academic Precision** design language.

### Core Layout Geometry
- **Top Academic Bar (64px)**: Fixed persistent header containing institutional context, course and class group, session title, live status with pulse indicator, real-time elapsed timer, network signal quality, and quick view settings.
- **Central Video Canvas (Flex: 1)**:
  - **Hero Stage**: Dynamic active-speaker focus area maximizing visual clarity for teacher instruction, shared slides, or student interventions.
  - **Participant Strip / Filmstrip**: Clean horizontal carousel of attending participants (up to 6 visible concurrently with paging), displaying camera feed, active mic wave animation, raised hand badge, and fallback initials avatar.
- **Collapsible Right Rail (360px - 400px)**:
  - Dual tabs: **Discussion (Chat)** and **Participants ({count})**.
  - Persistent message history with teacher distinction badges, role chips, timestamps, auto-scroll, and localized input composer.
  - Participant management drawer with teacher moderation actions (Mute, Mute All, Remove).
- **Floating Bottom Action Dock (76px)**:
  - Primary media controls (Mic, Camera, Screen Share, Raise Hand).
  - Distinction between **Quitter la session (Leave)** and **Mettre fin pour tous (End for everyone)** to prevent accidental session termination.

---

## 2. Design Tokens & Styling Guide

| Token | Value | Role / Usage |
|---|---|---|
| `primary` | `#122675` | Academic deep blue, primary controls, badges |
| `primary-container` | `#2D3E8C` | Active speaker card background, control container |
| `surface` | `#0B0F19` (Dark Live Mode) | Low-glare dark stage optimized for extended video focus |
| `surface-container` | `#151B2B` | Participant tiles, side rail background |
| `surface-container-high` | `#1E2638` | Interactive cards, input fields, control hover |
| `tertiary-fixed` | `#83F8CD` | Active mic indicator, live connection health |
| `error` | `#BA1A1A` | Live badge dot, End session button, mute states |
| `border-radius` | `16px` (containers), `24px` (pills) | Soft rounded corners matching SmartClass design |

---

## 3. Component Inventory

1. **SessionHeader**:
   - Class Chip (`L3 Informatique • Groupe A`), Title (`Algorithmique Avancée & Graphes`), Live Indicator (`EN DIRECT • 00:34:12`), Network Health (`24ms • Excellent`).
2. **VideoTile (Active Speaker)**:
   - 16:9 aspect-ratio responsive stage with speaker name tag, active speaker halo glow (`#4056B9`), audio activity meter.
3. **FilmstripTile**:
   - Compact participant video tile with camera status, mute indicator, raised hand overlay badge.
4. **ChatPanel**:
   - Message bubble list, teacher accent border, student standard bubble, chat-disabled banner when host disables discussion, auto-resizing input with keyboard shortcuts (`Enter` to send).
5. **ParticipantsPanel**:
   - Role-grouped list (Hôte / Professeur, Étudiants), mic state icons, hand-raised queue, "Muter tout le monde" (Host only) button.
6. **ControlDock**:
   - Mic toggle with device dropdown arrow.
   - Camera toggle with device selection dropdown.
   - Screen share toggle (Teacher & authorized participants).
   - Raise Hand toggle (animates on active).
   - Chat toggle & Participants toggle with unread counter badge.
   - Leave button (`#374151` neutral outline).
   - End for everyone button (`#DC2626` solid red with confirmation prompt).

---

## 4. State Variants

- **Connecting State**: Translucent blur overlay with animated academic spinner and "Connexion au sas vidéo...".
- **Reconnecting / Poor Network**: Top alert banner with warning pill, audio track prioritization notice.
- **Permission Denied**: Centered modal with illustrated camera/mic icons, instructions for browser permission settings.
- **Host Not Yet Started**: Waiting room banner with session start countdown.
- **Chat Disabled**: Composer replaced by locked icon and "Le chat a été désactivé par l'hôte".
- **Screen Share Active**: Active screen stream occupies 80% stage, speaker video moves to floating picture-in-picture window.
