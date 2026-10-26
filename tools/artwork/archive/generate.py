import math
import sys
from pathlib import Path

HERE = Path(__file__).parent

def pt(cx, cy, rx, ry, deg):
    t = math.radians(deg)
    return (cx + rx * math.cos(t), cy + ry * math.sin(t))

def f(p):
    return f"{p[0]:.1f} {p[1]:.1f}"

def spike(p, n, length, half_w, color, sink=0.0):
    tx, ty = -n[1], n[0]
    root = (p[0] - n[0] * sink, p[1] - n[1] * sink)
    b1 = (root[0] + tx * half_w, root[1] + ty * half_w)
    b2 = (root[0] - tx * half_w, root[1] - ty * half_w)
    end = (p[0] + n[0] * length, p[1] + n[1] * length)
    return f'<path d="M{f(b1)}L{f(end)}L{f(b2)}Z" fill="{color}"/>'

def circle_path(cx, cy, r):
    return f"M{cx - r:.2f} {cy:.2f}a{r:.2f} {r:.2f} 0 1 0 {2 * r:.2f} 0a{r:.2f} {r:.2f} 0 1 0 {-2 * r:.2f} 0Z"

def lens_path(half_len, half_w):
    k = half_w * 1.05
    return (f"M{-half_len} 0C{-half_len * 0.45:.1f} {-k:.1f} {half_len * 0.45:.1f} {-k:.1f} {half_len} 0"
            f"C{half_len * 0.45:.1f} {k:.1f} {-half_len * 0.45:.1f} {k:.1f} {-half_len} 0Z")

SQUIRCLE = '<rect x="100" y="100" width="824" height="824" rx="186"'
BOX_CLIP = f'<clipPath id="box">{SQUIRCLE}/></clipPath>'

NUT = ("M512 300C596 356 744 452 764 598C778 700 712 744 512 744"
       "C312 744 246 700 260 598C280 452 428 356 512 300Z")
HILUM = "M160 662C330 612 420 642 512 628C604 642 694 612 864 662L864 820L160 820Z"
GLINT = "M396 440C416 376 462 340 514 330C482 356 448 404 436 468C426 514 404 512 396 440Z"

def flat_nut(body, shade, base, glint_opacity=0.8, clip_id="nutClip"):
    return (f'<clipPath id="{clip_id}"><path d="{NUT}"/></clipPath>'
            f'<path d="{NUT}" fill="{body}"/>'
            f'<g clip-path="url(#{clip_id})">'
            f'<ellipse cx="770" cy="540" rx="265" ry="340" fill="{shade}"/>'
            f'<path d="{HILUM}" fill="{base}"/>'
            f'</g>'
            f'<path d="{GLINT}" fill="#FFFFFF" opacity="{glint_opacity}"/>'
            f'<path d="M500 306L512 272L524 306Z" fill="{base}"/>')

def svg(w, h, viewbox, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{viewbox}">\n'
            f'{body}\n</svg>\n')

class Ring:
    bg, ring, lip, wall, cavity = "#22451A", "#5F9B33", "#9BCB5C", "#F0E2BC", "#DACB95"
    spikes = ("#7DB544", "#6EA63A")
    nut = ("#8E4B26", "#6A3418", "#F2E0B8")

    @classmethod
    def scene(cls, with_box):
        parts = []
        for i in range(28):
            a = 2 * math.pi * (i + 0.5) / 28
            p, n = (512 + 318 * math.cos(a), 512 + 318 * math.sin(a)), (math.cos(a), math.sin(a))
            parts.append(spike(p, n, 112 if i % 2 == 0 else 90, 24, cls.spikes[i % 2]))
        parts.append(f'<circle cx="512" cy="512" r="330" fill="{cls.ring}"/>')
        parts.append(f'<circle cx="512" cy="512" r="250" fill="{cls.lip}"/>')
        parts.append(f'<circle cx="512" cy="512" r="236" fill="{cls.wall}"/>')
        parts.append(f'<circle cx="512" cy="512" r="194" fill="{cls.cavity}"/>')
        parts.append('<g transform="translate(512 534) rotate(-12) scale(0.66) translate(-512 -522)">'
                     + flat_nut(*cls.nut) + '</g>')
        body = "\n  ".join(parts)
        if with_box:
            return f'<defs>{BOX_CLIP}</defs>\n{SQUIRCLE} fill="{cls.bg}"/>\n<g clip-path="url(#box)">\n  {body}\n</g>'
        return body

    @classmethod
    def app_icon(cls):
        return svg(1024, 1024, "0 0 1024 1024", cls.scene(True))

    @classmethod
    def mark(cls):
        return svg(860, 860, "82 82 860 860", cls.scene(False))

    @classmethod
    def menubar(cls, opacity):
        return Minimal.menubar(opacity)

class Roasted:
    bg = "#F5E6CB"
    shell, face, base = "#6B3416", "#864420", "#F0DDB4"
    rim, flesh, crease = "#B5763C", "#F2C86E", "#D59D3C"

    @classmethod
    def scene(cls):
        lens_outer, lens_inner, lens_crease = lens_path(160, 54), lens_path(150, 42), lens_path(132, 9)
        cuts = "".join(
            f'<g transform="translate(512 436) rotate({deg})">'
            f'<path d="{lens_outer}" fill="{cls.rim}"/><path d="{lens_inner}" fill="{cls.flesh}"/>'
            f'<path d="{lens_crease}" fill="{cls.crease}"/></g>'
            for deg in (45, -45))
        return (f'<clipPath id="shell"><ellipse cx="512" cy="548" rx="300" ry="270"/></clipPath>\n'
                f'<ellipse cx="512" cy="548" rx="300" ry="270" fill="{cls.shell}"/>\n'
                f'<g clip-path="url(#shell)">'
                f'<ellipse cx="450" cy="470" rx="250" ry="215" fill="{cls.face}"/>'
                f'<path d="M150 720C300 670 420 700 512 690C604 700 724 670 874 720L874 900L150 900Z" fill="{cls.base}"/>'
                f'</g>\n{cuts}\n'
                f'<path d="M300 420C318 352 366 310 420 296C380 326 342 370 326 440C316 486 296 480 300 420Z" fill="#FFFFFF" opacity="0.7"/>')

    @classmethod
    def app_icon(cls):
        return svg(1024, 1024, "0 0 1024 1024", f'{SQUIRCLE} fill="{cls.bg}"/>\n{cls.scene()}')

    @classmethod
    def mark(cls):
        return svg(640, 580, "192 258 640 580", cls.scene())

    @classmethod
    def menubar(cls, opacity):
        lens = lens_path(5.2, 1.5)
        holes = "".join(f'<path d="{lens}" transform="translate(18 14.2) rotate({d})"/>' for d in (45, -45))
        shape = (f'<path d="{circle_path(18, 18, 0)}" fill="none"/>'
                 f'<path fill="#000" fill-rule="evenodd" d="M6.5 18.5a11.5 10.5 0 1 0 23 0a11.5 10.5 0 1 0 -23 0Z '
                 f'{lens_rotated(lens, 45)} {lens_rotated(lens, -45)}"/>')
        base = '<path d="M6.5 22.5C11 21 14 22 18 21.5C22 22 25 21 29.5 22.5L29.5 29L6.5 29Z" fill="#000" opacity="0.42"/>'
        return svg(36, 36, "0 0 36 36", f'<g opacity="{opacity}"><clipPath id="c"><ellipse cx="18" cy="18.5" rx="11.5" ry="10.5"/></clipPath>{shape}<g clip-path="url(#c)">{base}</g></g>')

def lens_rotated(lens, deg):
    import re
    t = math.radians(deg)
    nums = [float(x) for x in re.findall(r"-?\d+\.?\d*", lens)]
    def rot(x, y):
        return (18 + x * math.cos(t) - y * math.sin(t), 14.2 + x * math.sin(t) + y * math.cos(t))
    p0 = rot(nums[0], nums[1]); c1 = rot(nums[2], nums[3]); c2 = rot(nums[4], nums[5]); p1 = rot(nums[6], nums[7])
    c3 = rot(nums[8], nums[9]); c4 = rot(nums[10], nums[11])
    return f"M{f(p0)}C{f(c1)} {f(c2)} {f(p1)}C{f(c3)} {f(c4)} {f(p0)}Z"

class Minimal:
    bg = "#62B140"
    nut = ("#4B2713", "#3A1C0D", "#F4E7CE")

    @classmethod
    def scene(cls):
        return ('<g transform="translate(512 540) rotate(-14) translate(-512 -522)">'
                + flat_nut(*cls.nut, glint_opacity=0.9) + '</g>')

    @classmethod
    def app_icon(cls):
        return svg(1024, 1024, "0 0 1024 1024", f'{SQUIRCLE} fill="{cls.bg}"/>\n{cls.scene()}')

    @classmethod
    def mark(cls):
        return svg(600, 540, "212 262 600 540", cls.scene())

    @classmethod
    def menubar(cls, opacity):
        s = 30 / 504
        glyph = (f'<clipPath id="n"><path d="{NUT}"/></clipPath>'
                 f'<clipPath id="top"><rect x="0" y="0" width="1024" height="640"/></clipPath>'
                 f'<g clip-path="url(#top)"><path d="{NUT}" fill="#000"/></g>'
                 f'<g clip-path="url(#n)"><rect x="0" y="640" width="1024" height="400" fill="#000" opacity="0.42"/></g>')
        return svg(36, 36, "0 0 36 36",
                   f'<g opacity="{opacity}" transform="translate(18 18.6) rotate(-14) scale({s:.5f}) translate(-512 -522)">{glyph}</g>')

class Conker:
    C, R = (18.0, 18.6), 11.0
    APEX = (24.8, 19.8)
    UP = (-0.866, -0.500)
    LOW = (-0.990, 0.139)
    GAP = 1.8
    NUT = ((16.0, 18.9), 9.6, 0.70)

    @classmethod
    def wedge(cls, apex, reach=40):
        a = apex
        p1 = (a[0] + cls.LOW[0] * reach, a[1] + cls.LOW[1] * reach)
        p2 = (a[0] + cls.UP[0] * reach, a[1] + cls.UP[1] * reach)
        return f"M{f(a)}L{f(p1)}L{f(p2)}Z"

    @classmethod
    def lip_end(cls, direction):
        (cx, cy), R = cls.C, cls.R
        ax, ay = cls.APEX[0] - cx, cls.APEX[1] - cy
        dx, dy = direction
        b = 2 * (ax * dx + ay * dy)
        c = ax * ax + ay * ay - R * R
        t = (-b + math.sqrt(b * b - 4 * c)) / 2
        return (cls.APEX[0] + dx * t, cls.APEX[1] + dy * t)

    @classmethod
    def husk_path(cls):
        R = cls.R
        low, up = cls.lip_end(cls.LOW), cls.lip_end(cls.UP)
        return f"M{f(low)}A{R} {R} 0 1 0 {f(up)}L{f(cls.APEX)}Z"

    @classmethod
    def glyph(cls, ink="#000"):
        (cx, cy), R = cls.C, cls.R
        spikes = []
        for i in range(14):
            ang = 2 * math.pi * (i + 0.3) / 14
            n = (math.cos(ang), math.sin(ang))
            p = (cx + R * n[0], cy + R * n[1])
            phi = math.degrees(math.atan2(p[1] - cls.APEX[1], p[0] - cls.APEX[0])) % 360
            if 166 <= phi <= 218:
                continue
            spikes.append(spike(p, n, 3.6, 1.45, ink, sink=1.2))
        husk = f'<path d="{cls.husk_path()}" fill="{ink}"/>' + "".join(spikes)
        half = math.radians(19)
        bis = (cls.UP[0] + cls.LOW[0], cls.UP[1] + cls.LOW[1])
        bl = math.hypot(*bis)
        d = cls.GAP / math.sin(half)
        inner_apex = (cls.APEX[0] + bis[0] / bl * d, cls.APEX[1] + bis[1] / bl * d)
        (nx, ny), nr, alpha = cls.NUT
        return (f'<clipPath id="mouth"><path d="{cls.wedge(inner_apex)}"/></clipPath>'
                f'{husk}'
                f'<g clip-path="url(#mouth)"><circle cx="{nx}" cy="{ny}" r="{nr}" fill="{ink}" opacity="{alpha}"/></g>')

    @classmethod
    def menubar(cls, opacity):
        return svg(36, 36, "0 0 36 36", f'<g opacity="{opacity}">{cls.glyph()}</g>')

    @classmethod
    def app_icon(cls):
        s = 760 / 36
        return svg(1024, 1024, "0 0 1024 1024",
                   f'{SQUIRCLE} fill="#FFFFFF"/>\n<g transform="translate(132 132) scale({s:.4f})">{cls.glyph("#3C4A1E")}</g>')

    @classmethod
    def mark(cls):
        return svg(720, 720, "0 0 36 36", cls.glyph("#3C4A1E"))

CONCEPTS = {"conker": Conker, "ring": Ring, "roasted": Roasted, "minimal": Minimal}

if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else "ring"
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else HERE
    out.mkdir(parents=True, exist_ok=True)
    concept = CONCEPTS[name]
    (out / "app-icon.svg").write_text(concept.app_icon())
    (out / "mark.svg").write_text(concept.mark())
    (out / "menubar-active.svg").write_text(concept.menubar(1.0))
    (out / "menubar-idle.svg").write_text(concept.menubar(0.45))
    print(f"SVG masters written for concept '{name}' into {out}")
