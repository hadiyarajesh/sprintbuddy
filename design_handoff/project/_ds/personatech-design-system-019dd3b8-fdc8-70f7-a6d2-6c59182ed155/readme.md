# Personatech Design System

A design system for **Personatech** — a B2B SaaS platform for running professional **events, meetings and registrations**. This system is reverse-engineered from the live **Phoenix** frontend so that design agents can produce on-brand consoles, registration flows, marketing assets and decks.

> **Sources.** Everything here is lifted from Personatech's `phoenix-fe` repository (a Create-React-App + SCSS codebase). If you have access, explore these to go deeper:
> - `https://github.com/tushar-personatech/phoenix-fe` (branch `dev`) — the working fork these tokens, fonts, icons and components were extracted from.
> - `https://github.com/personatech-infra/phoenix-fe` — the canonical org repository (access was restricted at extraction time).
>
> Real assets pulled in: the `Icon` SVG library (`src/assets/icons/index.js`, 225 glyphs), Inter & Lato webfonts, the Personatech logos, and the SCSS theme files (`_theme.scss`, `_theme_constant.scss`, `_fonts.scss`, `button.scss`, `nav.scss`, `table.scss`, etc).

---

## What Personatech does

Personatech is an **event experience platform**. A client organization runs an **Event Series** made up of individual **Events**; within each event, attendees take part in structured **Programs**:

- **1:1 Meetings** — scheduled one-to-one business meetings (accent `--pt-program-meeting`, indigo).
- **Table Talks** — small-group topic roundtables (accent `--pt-program-tabletalk`, cyan).
- **Buyers** — curated buyer/supplier matching programs (accent `--pt-program-buyers`, gold).

Around these sit **Registration** (participant types, rate cards, agendas, badges, approvals, sponsors, FAQ), **Profiles**, **Organizations** and **Clients**.

The frontend is split into three apps, two of which carry distinct theming:

| App | `appType` | Audience | Theme |
|-----|-----------|----------|-------|
| **Console** | `appType--admin` | Internal/client admins | Navy + blue, Roboto, dense tables |
| **Registration** | `appType--reg` | Public attendees | Configurable per-client primary/secondary, lighter |
| **myExperience** | — | Logged-in attendees | Shares console foundations |

This system documents the **Console (admin)** theme as the canonical brand, since its palette and chrome are fixed; the registration app re-themes primary/secondary per client on top of the same tokens.

---

## Content fundamentals

How Personatech writes UI copy (observed across the console & forms):

- **Voice:** plain, operational, task-first. It tells admins what a control does, not how they should feel. No marketing flourish inside the product.
- **Person:** addresses the user implicitly via imperatives — *"Add event"*, *"Create program"*, *"Manage columns"*, *"Back to"*. Rarely "you"; never "we".
- **Casing:** **Title Case for buttons and primary actions** (*"Add Event Series"*, *"Reset Password"*), **Sentence case for helper text, labels and descriptions**. Navigation items are Title Case (*"Event Series"*, *"Rate Card"*).
- **Labels:** short noun phrases — *"Event name"*, *"Program type"*, *"Capacity"*. Required fields get a red asterisk, not the word "required".
- **Status language:** single words / short phrases — *Approved, Pending, Rejected, In Progress, Sponsored, Hosted, No Show*. These map to status colors.
- **Empty & error states:** factual and instructive — *"No results found"*, *"Enter a valid email address"*. Errors name the fix.
- **Domain vocabulary (use exactly):** Event Series, Event, Program, Meeting, Table Talk, Buyers, Participant Type, Rate Card, Agenda, Approval, Sponsor, Registration, Client, Organization, Platform.
- **No emoji.** The product never uses emoji in UI. Iconography is carried entirely by the SVG icon set.
- **Punctuation:** no trailing periods on labels, buttons or single-sentence helper text; periods only in multi-sentence body copy (e.g. modal warnings).

---

## Visual foundations

**Palette & vibe.** Cool, corporate, trustworthy. Built on a **deep navy (`#18407B`) primary** and a brighter **blue (`#2A76E1`) secondary**, with a **cyan (`#80CFF6`)** that comes straight from the logo's right edge. Text is a desaturated navy (`#263271`) rather than pure black. Surfaces are near-white with a wide cool-grey ramp (`grey-1`→`grey-10`). It is decidedly *not* a gradient-heavy or playful palette — color is used functionally (brand chrome, status, program taxonomy), not decoratively.

**Typography.** The console base family is **Roboto** (loaded from Google Fonts); **Inter** ships as the product-UI face and **Lato** as a legacy display face. The scale is small and pragmatic — **13px body**, 14px labels/controls, 24px page titles — reflecting an information-dense admin tool. Weights used: 300/400/500/700. Headings are medium/semibold, never ultra-bold.

**Backgrounds.** Flat fills only. Page background is `grey-9` (`#F6F6F6`); cards and panels are white; the sidebar is a faint cool off-white (`#FAFBFC`). The **login screen** is the one expressive surface: a navy top half / white bottom half split with the wordmark watermarked at 40% opacity, and the registration app uses a soft `loginGradient` (mint→pale-cyan). No textures, no photographic hero backgrounds in the admin.

**Borders & dividers.** Hairline `1px` borders in `grey-6`/`grey-7`. A signature **gradient hairline** divider is used for separators (`linear-gradient(90deg, grey-9, grey-5, grey-9)`) — fades in from the edges. The console header carries a subtle 4px gradient drop-shadow strip beneath it instead of a hard border.

**Corner radii.** Tight. **2px** for registration form fields, **4px** for buttons / admin inputs / dropdowns, **6px** for cards, **50%** for avatars. Nothing is heavily rounded.

**Shadows.** Soft, low-spread, functional elevation — never dramatic. Cards use `rgba(149,157,165,0.2) 0 8px 24px`; dropdowns and tables use tight `rgba(9,30,66,…)` stacks; dialogs use `0 4px 12px rgba(0,0,0,.2)`. Focus is a soft navy glow `0 0 6px rgba(38,50,113,.2)` rather than a hard ring.

**Cards.** Two looks: the default **elevated** white card (soft shadow, 6px radius) and the console **bordered entity card** (`grey-10` fill + a full `1px` navy border, 6px radius) used for clients/programs.

**Buttons.** 4px radius, 14px medium label, solid fill or white outline that inverts on hover. Primary buttons have a signature **white sheen that sweeps across on hover** (a translucent overlay animating width 0→100%). Hover also lifts a soft drop shadow. Variants: primary (navy), secondary (blue), error (red), cancel (grey), link (text).

**Motion.** Restrained and quick. Transitions are `0.2s`–`0.5s`; the house easing is `cubic-bezier(0.455,0.03,0.515,0.955)`. Fades use a simple `fadeInAnimation` (opacity 0→1). Playful touches are rare and small — e.g. the "Back to" arrow nudges left on hover. No bounces, no parallax, no infinite decorative loops.

**Hover / press states.** Hover = darker fill (solid buttons use the brand color at ~85% alpha) or a light-blue wash on neutral/nav surfaces (`#DCE9FD`). Active nav = `#CADEFC` fill + a navy left accent bar that slides in. There is no explicit shrink-on-press; feedback is color + shadow.

**Layout rules.** Fixed 52px top header (navy, full-width, z-104), fixed 270px left sidebar, fluid content area on `grey-9`. Forms are responsive two-column (`calc(50% - gutter/2)`) collapsing to one column under 991px. Tables are the dominant content pattern: sticky header, hover row highlight with a navy left accent bar, resizable columns, inline filters.

**Transparency & blur.** Used sparingly — the modal overlay is a translucent navy (`rgba(38,50,113,.45)`); the login watermark is 40% opacity. No backdrop-blur glass effects.

**Imagery tone.** The product is UI-chrome-driven; there is little photography. Where org/client logos appear they sit on white in a bordered or circular frame. The brand's own imagery (logos) is crisp, flat, vector — cool blues on white.

---

## Iconography

Personatech ships its **own custom SVG icon library** — a single `Icon` class (`src/assets/icons/index.js`) exposing **225 static glyph methods**. We import it verbatim as **`assets/icons.jsx`**, exposed at runtime as the **`window.PTIcon`** global.

- **Style:** monochrome line/solid hybrid, drawn on mixed viewBoxes, rendered at `1em` and inheriting `currentColor`. Many are sourced from common open icon sets (Material, Bootstrap, Ionicons) and normalized through a shared `IconBase` wrapper.
- **Usage in HTML/JSX (Babel):** load `<script type="text/babel" src="…/assets/icons.jsx"></script>`, then call a glyph as a function: `{PTIcon.Dashboard({})}` or `{PTIcon.Search({ style: { color: "var(--pt-navy)" } })}`. They return SVG elements directly.
- **Color them** by setting `color` on the element (they use `currentColor`); size with `fontSize`.
- **Domain glyphs to know:** `Dashboard, Client, Organization, EventSeries, Registration, Approvals, Settings, InPerson, TableTalk, RateCard, SwitchProgram` plus the usual `Search, Add, Edit, Delete, Copy, Refresh, Close, Check, CheckCircle, InfoCircle, Warning, ClosedLock/OpenLock, Logout, BackTo, ChevronDown, VisibilityOn/Off, Dollar, Android, IOS`.
- **No emoji, no unicode-glyph icons.** Always reach for `PTIcon`. If a needed glyph is absent, the closest match in the set or a Material-style substitute keeps visual consistency; flag any substitution.

See the **Iconography** card in the Design System tab for a live specimen grid.

---

## Index / manifest

**Foundations**
- `styles.css` — root entry point (consumers link this). `@import` lines only.
- `tokens/colors.css` · `tokens/typography.css` · `tokens/spacing.css` · `tokens/fonts.css` · `tokens/base.css`
- `guidelines/*.html` — foundation specimen cards (Colors, Type, Spacing, Brand) shown in the Design System tab.

**Assets** (`assets/`)
- `img/personatech-funky-logo.png` (wordmark, light), `…-logo-2.png` (wordmark, on navy), `personatech-short-logo.png` (PT mark), `default_org_logo.png`
- `img/appStore_badge.svg`, `googlePlay_badge.svg`, `note_bulb_icon.svg`
- `fonts/` — Inter (300/400/500) + Lato (300/400/700) woff2
- `icons.jsx` — the 225-glyph `PTIcon` library

**Components** (`components/<group>/`) — bundled into `window.PersonatechDesignSystem_019dd3`
- `core/` — **Button, Badge, Tag, Card, Avatar**
- `forms/` — **Input, Select, Checkbox**
- `navigation/` — **SideNavItem**
- `feedback/` — **Modal**

**Worked example** (`prioritize_participants/`)
- A faithful recreation of the MyExperience **Prioritize Participants** screen (4-step wizard, "Direct 1" meta bar, participant data table) presented on a design canvas with three **"filters on top"** redesign variants — lifting the left Status rail into a top bar styled to match the Accept Meetings screen. Built from the real `phoenix-fe` selection/acceptMeetings module code + product screenshots.

**Other**
- `SKILL.md` — Agent-Skill manifest for use in Claude Code.

---

## Using this system

- **Throwaway artifacts (decks, mocks, prototypes):** link `styles.css`, copy in the logos/icons you need, and build static HTML. Reach for the `--pt-*` tokens and `PTIcon`.
- **Production work:** treat the tokens as the source of truth and mirror the component contracts in `components/*/<Name>.d.ts`.
- **Caveat:** Roboto loads from Google Fonts; Inter & Lato are the bundled binaries. The icon library is large (~185KB) — tree-shake to the glyphs you actually use when shipping to production.
