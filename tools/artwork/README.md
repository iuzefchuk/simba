# Artwork

The icon pipeline. It is developer tooling: nothing in the app depends on it, so it lives here beside `src/`
rather than inside it. Its inputs (the two masters, the photos, the archive) sit next to the scripts, and its
only output is the asset catalog the app ships, `src/assets/Simba.xcassets`. `make icons` builds it.

```
tools/artwork/
    masters/            active.png, idle.png: the two 1024 px head cutouts every asset derives from
    sources/            where the original photos go (not in the repo, see below; create the folder)
    archive/            the earlier icon generations: their pictures and their generators, wired to nothing
    build.sh            `./build.sh` composes, `./build.sh --masters` rebuilds the masters first
    compose.swift       masters to every image set in the catalog
    subjectmask.swift, headcut.py, earfix.py, frontalize.py, matchlight.py   photos to masters
```

## From masters to assets

`make icons` (that is, `build.sh`) compiles `compose.swift` and composes `src/assets/Simba.xcassets`
from the two masters, so the app icon and the menu bar can never drift:

- `appiconset/Main`: the app icon, the active master on a squircle at every macOS size, `16.png` to
  `512@2x.png`. The project's `ASSETCATALOG_COMPILER_APPICON_NAME` names this set, so renaming it means
  changing that setting too.
  `ICON_BG=white|olive|khaki|light` picks the squircle colour; white is the default and has no ground shadow.
- `imageset/Mark`: the active master on transparency, for the in-app windows (`360.png`, `360@2x.png`).
- `imageset/MenuBarActive`: the active master shrunk to 18 and 36 px in full colour (`18.png`, `18@2x.png`).
- `imageset/MenuBarIdle`: the idle master shrunk with identical framing, so the menu bar can switch
  between the two without anything jumping.

Sets sit in a folder named after their extension, and every file is named by its point size and scale. Each
set's `Contents.json` is its manifest, checked in, listing exactly those names; the script only replaces the
PNGs, and `make layers` checks that the two agree. The catalog root and the extension folders carry no
`Contents.json`: Xcode writes metadata-only ones there, but the build does not need them.

## From photos to masters

The masters are head-only cutouts of a cat: the meowing head is active, the calm head idle.
`build.sh --masters` runs the chain below and expects the original photos at
`tools/artwork/sources/active.png` and `tools/artwork/sources/idle.png`.

1. `subjectmask.swift` lifts the subject from a photo with Vision, the same model behind Preview's
   Remove Background.
2. `headcut.py` keeps only the head: the subject mask times a two-ellipse region (skull and jaw, so the
   neck is cut on a curve under the jaw), rotated until the eyes are level, centred on the nose bridge,
   squared, 1024 px. For the calm photo it also slides the pupils 11 px right and 5 px down toward the lens
   (4 and 5 was too timid; the cat still read as looking left).
3. `earfix.py`, calm head only: mirrors the upright left ear and the whole right outline down to the jaw
   over the right side, because the cat had swivelled its right ear sideways. The zone runs the full
   outline so the silhouette stays one continuous edge.
4. `frontalize.py`, calm head only: warps the slightly turned head toward the lens. Near cheek stretched a
   little, far cheek compressed, muzzle pushed under the eyes, nothing above the ears.
5. `matchlight.py`, calm head only: matches the calm head's exposure, colour balance and sharpness to the
   meowing head, so the two states sit in the same light.

The ellipse and pupil coordinates for `headcut.py` sit at the top of `build.sh`. **They are blank.** The
photos were pasted into a chat and never kept, and the coordinates were typed once and not written down,
so the current masters cannot be regenerated. To redo them: put the photos in `tools/artwork/sources/`,
read the coordinates off them, fill in `ACTIVE_HEAD` and `IDLE_HEAD`, run `make masters`. The constants
inside `earfix.py` and `frontalize.py` are in master pixels and belong to the current calm head; a new
cut needs them checked.

Everything runs on what ships with macOS plus Pillow for Python. There is no numpy here; the pure-Python
warp takes about a second at 1024 px.

## Archive

Two earlier generations of the icon, kept for reference only, scripts and pictures together in `archive/`:

- The 3D horse chestnut: `render3d.swift` builds it as SceneKit geometry and rendered `icon-master.png`
  (husk bitten open) and `icon-master-closed.png` (shut); `reference-vs-render.png` is the comparison sheet
  it was matched against.
- The flat SVG concepts: `generate.py` writes them, `svg2png.swift` rasterises them with AppKit.
- `make-icons.sh` drove both; its paths no longer exist.

`build.sh` only knows the cat. To see the chestnut again, compile `compose.swift` and point it at the two
archived masters. Once the repository has a first commit, this folder can go; git will keep it.
