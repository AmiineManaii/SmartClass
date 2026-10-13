---
name: SmartClass Academic Precision
colors:
  surface: '#faf8ff'
  surface-dim: '#d4d9f5'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f2ff'
  surface-container: '#ebedff'
  surface-container-high: '#e3e7ff'
  surface-container-highest: '#dce1fe'
  on-surface: '#151b2f'
  on-surface-variant: '#454651'
  inverse-surface: '#2a3045'
  inverse-on-surface: '#eff0ff'
  outline: '#757682'
  outline-variant: '#c6c5d3'
  surface-tint: '#4858a8'
  primary: '#122675'
  on-primary: '#ffffff'
  primary-container: '#2d3e8c'
  on-primary-container: '#9eaeff'
  inverse-primary: '#b9c3ff'
  secondary: '#4056b9'
  on-secondary: '#ffffff'
  secondary-container: '#8197ff'
  on-secondary-container: '#09288e'
  tertiary: '#003627'
  on-tertiary: '#ffffff'
  tertiary-container: '#004f3b'
  on-tertiary-container: '#4ec69f'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dee1ff'
  primary-fixed-dim: '#b9c3ff'
  on-primary-fixed: '#001258'
  on-primary-fixed-variant: '#2f408e'
  secondary-fixed: '#dde1ff'
  secondary-fixed-dim: '#b9c3ff'
  on-secondary-fixed: '#001257'
  on-secondary-fixed-variant: '#243da0'
  tertiary-fixed: '#83f8cd'
  tertiary-fixed-dim: '#65dbb2'
  on-tertiary-fixed: '#002116'
  on-tertiary-fixed-variant: '#00513c'
  background: '#faf8ff'
  on-background: '#151b2f'
  surface-variant: '#dce1fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.022em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
    letterSpacing: -0.019em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 25px
    letterSpacing: -0.012em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.011em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: -0.008em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: -0.003em
  label-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.011em
  label-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.008em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.002em
  caption:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 13px
    letterSpacing: 0.006em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  gutter-lg: 1.5rem
  margin: 1.25rem
  margin-sm: 1rem
  margin-lg: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system embodies the clarity, calm focus, and institutional confidence required for modern digital education on iOS platforms. It balances authoritative pedagogical structure with the frictionless human interface aesthetics of Apple's Human Interface Guidelines. 

The visual narrative prioritizes low cognitive load, razor-sharp typographic hierarchy, and deliberate tactile feedback. The experience evokes intellectual capability, trustworthiness, and effortless order. The interface blends modern iOS utility with subtle ambient depth, ensuring course progression, interactive assessments, and authentication flows remain distraction-free and legible in both micro-sessions and extended study hours.

## Colors

The palette establishes focus through a dominant, deep smart blue foundation paired against crisp, high-clarity surfaces:

- **Primary (`#2d3e8c`)**: Anchors critical interactive actions, primary navigation bars, and active state highlights.
- **Secondary (`#4f65c9`)**: Utilized for accents, active segmented switches, progress bars, and link text.
- **Tertiary (`#0f9d78`)**: A focused sage-emerald used exclusively for affirmative states, correct quiz answers, streak counters, and completion badges.
- **Neutral (`#1d2338`)**: High-contrast, optical slate black used for titles, form labels, and critical typography to maximize legibility.
- **Canvas Base**: Set to `#f7f8fb` to provide a subtle, eye-soothing tint that reduces glare compared to pure white, allowing pure `#ffffff` cards and input containers to lift effortlessly from the background.
- **Subtle Surface & Stroke Colors**: Structural dividers and input borders utilize `#e4e7f0` in default states, shifting to `#2d3e8c` when active.

## Typography

The typographic engine uses Inter to evoke the precise, native clarity of Apple's San Francisco system font. It delivers neutral geometric balance, tall x-height, and tailored tracking tables optimized for screens.

- **Display & Large Titles**: Reserved for primary onboarding screens, dashboard welcome greetings, and completion summaries. Negative tracking tightens the visual mass for crisp impact.
- **Headlines**: Scale from `28px` down to `20px` to enforce structural hierarchy within syllabus modules, lesson headings, and modal alerts.
- **Body Text**: Tuned to Apple's standardized base sizes (`17px` primary body, `15px` secondary). Line heights are tightly calibrated to maintain cadence across multi-paragraph assignments without feeling spaced or airy.
- **Labels & Forms**: Semi-bold weight (`600`) ensures high contrast against input containers and primary buttons.

## Layout & Spacing

The layout architecture adheres to a strict 4pt/8pt baseline grid tailored for standard iOS screen viewports:

- **Canvas Margins**: Default outer screen edge padding is fixed at `1.25rem` (20px) on mobile viewports (e.g., iPhone 13/14/15 standards) to preserve thumb zones, expanding to `2rem` (32px) on iPad/tablet split screens.
- **Column Structure**: Mobile views deploy a fluid single-column stack, reflowing to a 6-column grid on compact horizontal views and a 12-column grid on iPadOS/Desktop with fluid gutters scaling between `0.75rem` and `1.5rem`.
- **Vertical Rhythm**: Layout components adhere to rhythmic gaps:
  - Micro-gaps (`space-xs` = 4px, `space-sm` = 8px) handle icon-to-text pairs and metadata groupings.
  - Form field stacks and component groups operate on `space-md` (16px).
  - Inter-section card modules leverage `space-lg` (24px) to preserve hierarchy.

## Elevation & Depth

Depth is treated with native iOS subtlety, relying on layered surface tones and diffused ambient shadows rather than dense drop shadows.

- **Level 0 (Flat Surface / Canvas)**: `#f7f8fb` default background. Contains no shadow or elevation.
- **Level 1 (Card & Content Containers)**: White background (`#ffffff`) surrounded by a hairline boundary stroke of `1px solid rgba(45, 62, 140, 0.08)` and elevated by an ambient shadow: `0 2px 8px rgba(29, 35, 56, 0.04), 0 1px 2px rgba(29, 35, 56, 0.02)`.
- **Level 2 (Interactive Floating Elements / Menus / Dropdowns)**: White surface overlaid with a dual-stage shadow: `0 10px 25px -5px rgba(29, 35, 56, 0.08), 0 4px 6px -2px rgba(29, 35, 56, 0.03)`.
- **Level 3 (Modals / Bottom Sheets)**: Features frosted glass backdrop blurring (`backdrop-filter: blur(20px) saturate(180%)`) paired with an overarching soft scrim `rgba(29, 35, 56, 0.32)` and top edge highlight.

## Shapes

The design system implements a rounded geometry (`roundedness: 2`, base radius `0.5rem` / 8px) calibrated to match iOS continuous curvature (squircle-like feel).

- **Controls & Form Inputs**: Feature an outer radius of `0.75rem` (12px), aligning with iOS standards for tactile inputs.
- **Cards & Modals**: Utilize `rounded-lg` (`1rem` / 16px) for module cards and syllabus panels, stepping up to `1.5rem` (24px) for full bottom-sheet modals.
- **Pills & Chips**: Badges, status chips, and tag buttons use an absolute radius (`9999px`) to create distinction from actionable square-cornered form modules.

## Components

### Buttons
- **Primary Buttons**: Background `#2d3e8c`, foreground text `#ffffff` (`label-md`). Height is standard iOS touch target `50px` with a corner radius of `12px`. Subtle pressed state reduces opacity to `0.9` and downscales slightly to `0.98`.
- **Secondary Buttons**: Transparent background with a crisp border of `1.5px solid #2d3e8c` and text `#2d3e8c`.
- **Social Authentication Buttons**: High-contrast, clean utility buttons.
  - *Apple*: Solid black (`#000000`) background, `#ffffff` text, SF logo left slot.
  - *Google*: Solid white background (`#ffffff`), `1px solid #e4e7f0` border, `#1d2338` text, multi-color Google 'G' icon in left slot.
  - Button height strictly unified to `50px`, gap between icon and label is `12px`.

### Input Fields
- **Container**: Minimum height of `48px`, background `#ffffff`, border `1px solid #e4e7f0`, corner radius `12px`.
- **Icon Slots**: Built-in left and right icon slots sized at `20px x 20px` with a fixed padding inset of `14px`. Unfocused icon color is `#8c94a8`; active focus shifts the icon to `#2d3e8c`.
- **State Changes**: On focus, the border transitions to `1.5px solid #2d3e8c` with an ambient glow of `0 0 0 3px rgba(45, 62, 140, 0.12)`. Error states switch border and glow to `#e53935`.

### Chips & Badges
- **Status Badges**: Capsule-shaped (`rounded-full`), height `28px`, padding `0 12px`.
- **Course Status Active**: Background `rgba(45, 62, 140, 0.08)`, text `#2d3e8c` (`label-sm`).
- **Completed Status**: Background `rgba(15, 157, 120, 0.1)`, text `#0f9d78` (`label-sm`).

### Lists & Navigation Rows
- Grouped iOS-style inset tables. White background container enclosed in `16px` border radius with hairline dividers (`0.5px solid #e4e7f0`) indented by `56px` to account for leading lesson icons. Trailing accessory elements display right-facing chevrons (`#bcc1cd`).

### Checkboxes & Radio Buttons
- **Checkboxes**: Sized `22px x 22px`, corner radius `6px`. Unchecked has `1.5px solid #c8cddc`. Checked fills with `#2d3e8c` displaying an interior white checkmark.
- **Radio Buttons**: Sized `22px x 22px`, circular. Checked state reveals an inner filled circle of `10px` in `#2d3e8c` surrounded by white space inside the border ring.

### Cards
- Standard assignment/course card built with `#ffffff` fill, `16px` corner radius, `1px solid rgba(45, 62, 140, 0.06)`, and ambient elevation. Includes top tags, title, lesson progress indicator bar (height `4px`, fill `#4f65c9`, track `#eef0f6`), and avatar stacks for peer cohorts.