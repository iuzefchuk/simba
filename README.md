# Simba

A macOS menu bar app for people who track their day in one-line notes. While your **Work** Focus is on,
Simba asks every hour *"What are you doing right now?"*. When the Focus ends, every answer shows up in
one list you can copy, line by line or all at once.

## How it works

- **Focus filter.** Simba registers a Focus filter (System Settings → Focus → Work → Add Filter).
  macOS calls it when that Focus turns on and off, so the app knows exactly when a report starts
  and ends. Any Focus works; "Work" is just the obvious one.
- **Hourly prompt.** On the top of each hour a small floating panel appears in the top-right corner.
  Type, press Return, done. Esc skips. The panel takes the keyboard without pulling you out of the
  app you were using.
- **Report.** When the Focus turns off, the Result window opens with that report's entries.
  Each row has a copy button, and **Copy All** puts the whole report on the clipboard as
  `10:00 – Fixing the login bug` lines. Past reports stay available from the picker in the header.
- **Menu bar.** The icon is the app icon itself, shrunk to menu bar size: the meowing cat while
  logging is running, the calm one when idle. The menu shows how the open report is going, lets you
  add an entry early, finish early, show the result, and toggle Launch at Login.

## Setup

1. `make install` builds the release app and copies it to `/Applications` (macOS 14 or later).
   Or open `Simba.xcodeproj` and run it from Xcode.
2. In the menu bar menu choose **Set Up Focus Filter…** and follow the three steps:
   System Settings → Focus → Work → Focus Filters → Add Filter → Simba → turn on *Hourly entries* → Add.
3. Turn on **Launch at Login** so Simba is running when the Focus switches.

No Focus? **Start Logging Manually** in the menu does the same thing by hand.

## Layout

The repository follows this design, verbatim, with three exceptions that Swift's own idiom asks for and the text
below explains: the dependency rules gain a row for `stores`, every entry is named for its role rather than `index`,
and there is no `routing`, since a single window coordinator sits beside the app's other objects and may name its
routes:

```
~
├── *rest* ‣ config
└── src ‣ config-agnostic logic
    ├── assets ‣ no logic.
    ├── domain ‣ language-agnostic logic
    │   └── {ddd-category}.{abstraction}.{ext}
    ├── infra ‣ language-specific framework-agnostic logic
    │   └── {dependency}.{port}.{implementation}.{ext}
    └── fw ‣ language-specific framework-specific logic
        ├── *rest* ‣ framework-idiomatic layout
        ├── stores
        ├── routing
        └── blocks ‣ framework-idiomatic building blocks (component, view, etc)
             ├── by-design ‣ by definition in design system, reusable
             │   └── *rest* ‣ see building blocks
             └── by-hierarchy ‣ by rendering hierarchy, non-reusable beyond single instance
                 ├── per-app ‣ mounted per app
                 │   ├── index.{ext} ‣ app entry
                 │   └── *rest* ‣ see building blocks
                 └── per-route ‣ mounted per route
                     └── {route}
                         ├── index.{ext} ‣ route entry
                         └── *rest* ‣ see building blocks
```

Legend: `{}` is a dynamic value; the DDD category is `aggregate`, `entity`, `value_object` or `service`; the
dependency is `browser`/`system`, `server` or `sdk`. A building block is `{Entity}.{ext}`, a flat block, or a
nested block: the folder `{NestedEntity}/` holding `{NestedEntity}.{ext}` and `{NestedEntity}{ChildEntity}.{ext}`.
And the dependency rules, where a row may import a column:

```
                                        1   2   3   4   5   6   7   8
1  assets                               ○   ✗   ✗   ✗   ✗   ✗   ✗   ✗
2  domain                               ✓   ○   ✗   ✗   ✗   ✗   ✗   ✗
3  infra                                ✓   ✗   ○   ✗   ✗   ✗   ✗   ✗
4  fw/stores                            ✓   ✓   ✓   ○   ✗   ✗   ✗   ✗
5  fw/*rest*                            ✓   ✓   ✓   ✓   ○   ✗   ✗   ✓
6  fw/blocks/by-design                  ✓   ✓   ✓   ✓   ✓   ○   ✗   ✗
7  fw/blocks/by-hierarchy/per-app       ✓   ✓   ✓   ✓   ✓   ✓   ○   ✗
8  fw/blocks/by-hierarchy/per-route     ✓   ✓   ✓   ✓   ✓   ✓   ✗   ○

○ itself   ✓ yes   ✗ no
```

`~` is the repository. A name in stars is a meta directory, a place rather than a folder: beside `src/`,
`*rest*` is everything else in the repository, under `fw` it is whatever the framework's own idiom lays out
beside the three folders the design names, and under a blocks folder it is the building blocks themselves.

`src/` is the app and nothing else, and the design calls everything beside it config: the Xcode project, the
Makefile, this README and the dotfiles configure the build, and `tests/` and `tools/` configure how the app is
checked and how its icons are made; none of it ships. Inside `src/`, `domain` and `infra` stand alone: neither
knows the other, nor `fw`, and `fw` is the only layer that knows both. The language is Swift with Foundation, and
the framework is what the app is built on: SwiftUI, AppKit, AppIntents and Observation. So `domain` imports
nothing but Foundation and reads nothing from the machine (the time and the calendar come in as parameters),
`infra` may import anything but those four and names no domain type, and `fw` is everything that touches the
framework or binds the other two. Every declaration sits in the layer its logic belongs to, not in the layer of
the code around it: a business rule is domain even when only the store applies it, a mechanism that knows
neither the framework nor the domain is infra even when only a view calls it, and `fw` keeps the framework, the
wiring between the layers, what ties a domain type to its storage, and the words on screen. `src` is also
config-agnostic: nothing in it reads a build setting, so there is no `#if DEBUG`, the Info.plist and the
entitlements are generated from the project, and the storage folder takes the app's name from the running process
instead of repeating it.

Neither `domain` nor `infra` has folders: each is one flat level of files whose names say what they are. A
domain file is `{ddd-category}.{abstraction}.swift`. The category is one of DDD's: `aggregate`, a root that
keeps its own invariants; `entity`, which has an identity; `value_object`, which has none; `service`, a rule
that belongs to no single object; `event`, something that happened. The abstraction is the type the file
declares, in snake_case, so `aggregate.report.swift` declares `Report`. The domain knows no file format: a
report or an entry read back from storage is rebuilt with `init(stored:…)`, which checks nothing, and
`violation` and `isNormalized` say what a stored value breaks. An infra file is
`{dependency}.{port}.{implementation}.swift`. The dependency is one of the three kinds an
app can have: `system` is the operating system (`browser` takes its place in a web app), `server` a remote
service, `sdk` a third-party package. The port is what the app asks for, named in the app's own words and
knowing nothing of the domain, and the implementation is the technology that answers; the file declares one
type named `{Implementation}{Port}`. Simba has six ports, all on the system: `storage`, `launch_at_login`,
`preferences`, `app_folder`, `alarm` and `diagnostics`.

`fw` is split as the design splits it. `stores/` holds what persists: `ReportStore`, the reports and their file.
Its `*rest*` is the framework's own idiom, laid out the way Apple's SwiftUI tutorial and Xcode's app template lay
out an app, since the framework's own documentation is the design: at the top, `AppModel`, the orchestrator every
part of the app talks to, with `Destination`, where it can ask to go, nested inside it, the delegate, and
`WindowCoordinator`, which turns a destination into a window on screen; and `AppIntents/` for the intents.
Everything on screen is a block, and `blocks/` sorts them the design's way. `by-design/` holds what the design
system defines and anything may reuse: `MarkView`, the mark at a size. `by-hierarchy/` holds what exists once, by
where it sits in the rendering hierarchy. `per-app/` is what the app mounts once: `App.swift` is the app entry, the
App itself under `@main`, declaring the one scene, the menu bar item, and `StatusMenuView` is that item's menu, in
AppKit's word for the menu under a menu bar icon. `per-route/` has one folder per route, named after it in
lowercase, and in this app a route is a window: `prompt`, the hourly question, `result` and `setup`. Every file in
a route folder starts with the route's name, and three suffixes name the three roles. `{Route}Route` is the entry:
the window controller, the top of what gets mounted for that route, named for its role as `App.swift` is, since
Swift names a file after its type and allows one file of a name per module. `{Route}View` is the page.
`{Route}View{Part}` is a smaller block of that page, the design's nested-block idiom. `make layers` derives the
prefix from the folder's name and pins the entry to `{Route}Route.swift`, the route's window controller.

The dependency rules are the design's, with the row `stores` needs and one cell relaxed. `stores` knows only the
layers below `fw`: nothing in it names the model or a window. `*rest*` knows `stores`, because the model holds the
store. A block knows both, `by-design` knows no `by-hierarchy`, and `per-app` and `per-route` know nothing of each
other. The relaxed cell is the window coordinator's: the design forbids anything outside a route from naming it,
which works on the web because a framework with file-based routing mounts every route by itself. Swift has nothing
of the kind, so the coordinator names its routes, the way a coordinator does in any AppKit or UIKit app, and
nothing else in `*rest*` does. `WindowCoordinator`, built by the delegate, holds the three window controllers, made
on first use, and follows the model with Observation's `withObservationTracking`: when the model sets a destination
the coordinator clears it and opens that window, activating the app; while the model has a prompt the coordinator
shows the panel, and closes it when the prompt is answered or skipped. So the model holds no window, and a route's
entry is a plain window controller hosting its view.

The data flows as the framework recommends. The app delegate, SwiftUI's hook for launch-time work, builds the
model, registers it with the App Intents dependency manager and hands it to the window coordinator; the App hands
it to the menu through the environment, so views read it from the environment and the Focus filter through
`@Dependency`. The windows are AppKit windows hosting the SwiftUI views through `NSHostingController`, the
framework's AppKit integration, because a SwiftUI `Window` scene can only be opened from inside a view and Simba
opens windows from the Focus filter and at launch; the prompt is an AppKit panel because SwiftUI has no
non-activating panel. Each window has an `NSWindowController`, AppKit's owner of a window, built together with the
window at launch, and the result window remembers its frame. Every view file ends in a `#Preview`, as Apple's view
files do, over `AppModel.preview`: a model on a throwaway store in the temporary directory, loaded with a sample
report. `make layers` checks all of that, the names, the imports and the direction; the rest is read.

```
src/
├── assets      no logic: files sorted by file extension                                 deps: none
│   └── Simba.xcassets    the asset catalog: the images `make icons` writes and the colours (Accent,
│                         PanelBackground, WindowBackground, each light and dark); a loose file would go in {ext}/
├── domain      language-agnostic logic: {ddd-category}.{abstraction}.swift              deps: assets
│   ├── aggregate.report.swift  what one Work Focus period collects: start, end, its entries kept in time order and
│   │                           never before the start, open or ended, stale after 16 h without an entry; add or
│   │                           remove an entry, throwing a Report.Rejection when one breaks its rules, end, or end at
│   │                           the last entry; and the Violation a stored report carries, if any
│   ├── entity.entry.swift      one answer to the hourly prompt: time and text, one line and never blank by
│   │                           construction, and whether a stored one still is
│   └── service.logging.swift   the activity of keeping reports: the next prompt, at the top of the hour in a given
│                               calendar, and below it the rules over all reports as [Report]: one open at a time and
│                               only as the last, one after another without overlap, unique; start, end, end a stale
│                               one at its last entry or drop it when it has no entries, add or remove an entry, each
│                               returning the report it changed, and the Violation the stored list carries
├── infra       language-specific framework-agnostic logic: a file per port              deps: assets
│   ├── system.storage.json.swift                        JSONStorage: a Codable value kept as one JSON file,
│   │                                                    dates in ISO 8601 at whole seconds; an unreadable
│   │                                                    file is moved aside, never overwritten
│   ├── system.launch_at_login.service_management.swift  ServiceManagementLaunchAtLogin: read it, or set it
│   │                                                    and throw
│   ├── system.preferences.user_defaults.swift           UserDefaultsPreferences: the two defaults the app
│   │                                                    reads: whether setup was shown (also set) and the
│   │                                                    -promptInterval override
│   ├── system.app_folder.file_manager.swift             FileManagerAppFolder: the app's folder in Application
│   │                                                    Support and under the temporary directory, each named
│   │                                                    after the running process, and emptying a folder
│   ├── system.alarm.timer.swift                         TimerAlarm: fire a closure once at a date, with a
│   │                                                    tolerance, on the main run loop, unless cancelled
│   └── system.diagnostics.ns_log.swift                  NSLogDiagnostics: note a message in the system log
└── fw          language-specific framework-specific logic: stores < *rest* < blocks   deps: assets, domain, infra
    ├── AppModel.swift      the orchestrator: logging on and off, the prompt schedule (the domain's next prompt or
    │                       every -promptInterval seconds), the prompt's time and draft, the selected report, the
    │                       destination it asks for (Destination, nested: result or setup), Launch at Login with
    │                       its failures logged, and the sample report; below it `preview`, a model on a throwaway
    │                       store with that sample, which every view's #Preview uses
    ├── AppDelegate.swift   the application delegate: builds the model, registers it for the intents, hands it to
    │                       the window coordinator, shows setup on the first run
    ├── WindowCoordinator.swift  owns the three routes' window controllers, made on first use, and follows the
    │                            model: opens the window a destination names, shows or hides the prompt panel
    ├── stores/
    │   └── ReportStore.swift    the report state: holds the reports, applies the domain's changes, saves
    │                            after each one and logs a rejection; an unreadable file is moved aside and
    │                            it starts empty; below it ReportFile, the version-1 envelope, and
    │                            StoredReport and StoredEntry, the JSON shape of a report and an entry;
    │                            read, the envelope rejects another version and a list of reports that
    │                            carries a Violation
    ├── AppIntents/
    │   └── LoggingFocusFilter.swift  the Focus filter macOS calls: an entry point the system mounts
    └── blocks/     framework-idiomatic building blocks: the views                deps: + stores, routing, fw/*rest*
        ├── by-design/   reusable, by the design system
        │   └── MarkView.swift     the mark at a size
        └── by-hierarchy/   one instance each, by where it is mounted
            ├── per-app/     mounted once, by the App                                           deps: + by-design
            │   ├── App.swift          SimbaApp, the App: the menu bar extra, with the active or idle icon, over
            │   │                      the delegate's model
            │   └── StatusMenuView.swift  the menu under the icon
            └── per-route/   mounted per route, a window each                                  deps: + by-design
                ├── prompt/
                │   ├── PromptRoute.swift     the entry: the floating panel's controller, placed top-right when
                │   │                         shown; PromptPanel below
                │   └── PromptView.swift      the hourly question
                ├── result/
                │   ├── ResultRoute.swift     the entry: the window's controller; it remembers its frame
                │   ├── ResultView.swift      a report and its entries
                │   └── ResultViewRow.swift   one entry with its copy button
                └── setup/
                    ├── SetupRoute.swift      the entry: the window's controller
                    ├── SetupView.swift       the three setup steps
                    └── SetupViewStep.swift   one numbered step
```

The Xcode project syncs folders, never loose files: the four layer folders into the app target, and
`tests/` with the two layers under test into `SimbaTests`, so a file added under a layer compiles
without touching the project. A file holds one type: in `fw` the file is named like the type, except
`per-app/App.swift`, named for its role, in `domain` the type is the file's abstraction and in `infra` it
is `{Implementation}{Port}`; a companion type, or anything it adds to another type, sits below it in the same
file.

A loose file in `assets` sorts by its extension into `{ext}/`: a font would go in `ttf/`, a fixture in
`json/`. The asset catalog is a directory Xcode owns, not a file, so it sits at the layer root as
`Simba.xcassets` and is sorted the same way inside: each set sits in a folder named after its extension,
`appiconset/`, `colorset/`, `imageset/`. Those folders carry no `Contents.json`, so they are
plain groups that never become part of an asset's name; the only `Contents.json` files are the sets' own
manifests, which say which file is which scale or size (and, for a colour, hold the colour itself, light and
dark). A set is `UpperCamelCase.imageset` (or `.appiconset`, `.colorset`), named for its role, never for the
app: `Mark`, `MenuBarActive`, `MenuBarIdle`, `Accent`, `PanelBackground`, `WindowBackground`. A set's files are
named by point size and scale, `18.png` and `18@2x.png`, every file is listed in the set's manifest, and every
listed file exists. `make layers` checks all of that too, and `make icons` writes exactly those names.

The config beside `src/`: `tests/` holds the unit tests, one folder per layer under test, one
`{Name}Tests.swift` per type (except launch at login, which needs the running app behind it), and
`Fixtures.swift` for what they share; `SimbaTests` compiles `src/domain` and `src/infra` in directly, so a
test run never launches the app. `tools/` is developer tooling the app never imports: `tools/artwork/` is
the icon pipeline with its masters (read its README before touching the pictures) and
`tools/check-layers.sh` is the check behind `make layers`.

## Coming from the web

The same parts under the names a front-end developer would use:

- `blocks/by-hierarchy/per-app/App.swift` is the root component and `_app` in one: `SimbaApp` declares the
  scenes, here a single menu bar item, and `StatusMenuView` beside it is the app shell's one component, the tray menu.
- `blocks/by-hierarchy/per-route/{route}/` is a page folder. Its entry, the window controller, is the page's
  frame; the view beside it is the page, and `ResultViewRow` and `SetupViewStep` are that page's own components.
- `blocks/by-design/` is the design system's components; `MarkView` is the one Simba has.
- `WindowCoordinator` is the router: it names the three pages and opens the one the store asks for, like a route
  table in `App.tsx`. The AppKit code that creates the actual window a page renders in, the nearest thing being
  Electron's `BrowserWindow`, sits in the page folder as its entry.
- `AppDelegate` is the bootstrap with lifecycle hooks: it builds the store on launch and shows setup on the first
  run.
- `AppModel` is the global store with its actions, `stores/ReportStore` the slice that persists, and
  `@Observable` makes them reactive. `AppModel.Destination` is the route enum, the pages the store can navigate to.
- `@Environment(AppModel.self)` is context, or provide and inject; `@Bindable` is two-way binding, like `v-model`.
- A `#Preview` is a story.
- `LoggingFocusFilter` is an endpoint the operating system calls, like a webhook handler.
- Below `fw`, `src/domain` is the pure business logic and `src/infra` the adapters: the file system, the defaults
  store, a timer, the system log and the OS's launch-at-login service.

## Development notes

- `make help` lists the targets: `build`, `test`, `run`, `run-fast` (prompts every 30 seconds), `release`,
  `install`, `icons`, `masters`, `layers`, `clean`, `open`.
- `-promptInterval 30` as a launch argument makes prompts arrive every 30 seconds instead of on the hour.
- Every view file ends in a `#Preview` over the same sample report, so Xcode's canvas shows the view without
  running the app; the preview's store lives under the temporary directory, never in Application Support.
- `make icons` recomposes every image asset from `tools/artwork/masters/`. Read `tools/artwork/README.md`
  before touching the pictures.
- Reports are stored as JSON in the app's Application Support folder (the app is sandboxed, so that is
  `~/Library/Containers/com.iuzefchuk.Simba/Data/Library/Application Support/Simba/reports.json`): an object
  with a `version`, 1 today, and the `reports` array, with dates at whole seconds. If that file cannot be
  read, is another version, or breaks the domain's rules, Simba renames it to
  `reports-unreadable-{timestamp}.json` beside it and starts empty instead of overwriting it; if the rename
  fails too, it saves nothing until the next launch.
