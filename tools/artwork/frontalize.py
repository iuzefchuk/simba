import math
import sys
from PIL import Image

src, out = sys.argv[1:3]
img = Image.open(src).convert("RGBA")
W, H = img.size

LEFT_EDGE, RIGHT_EDGE = 195.0, 862.0
EYES_FROM, EYES_TO = 490.0, 517.0
FADE_TOP, FADE_FULL = 150.0, 350.0
PUSH_CENTRE, PUSH_RADII, PUSH_DX = (481.0, 600.0), (170.0, 260.0), 36.0
EASE = 0.2

def smoothstep(e0, e1, v):
    t = min(max((v - e0) / (e1 - e0), 0.0), 1.0)
    return t * t * (3 - 2 * t)

def ramp(t):
    e = EASE
    if t <= 0: return 0.0
    if t >= 1: return 1.0
    if t < e: area = t * t / (2 * e)
    elif t <= 1 - e: area = e / 2 + (t - e)
    else: area = (1 - e) - (1 - t) ** 2 / (2 * e)
    return area / (1 - e)

def displacement(x, y):
    if x <= LEFT_EDGE or x >= RIGHT_EDGE:
        return 0.0
    if x <= EYES_FROM:
        s = ramp((x - LEFT_EDGE) / (EYES_FROM - LEFT_EDGE))
    else:
        s = 1 - ramp((x - EYES_FROM) / (RIGHT_EDGE - EYES_FROM))
    return (EYES_TO - EYES_FROM) * s * smoothstep(FADE_TOP, FADE_FULL, y)

def push_weight(x, y):
    u = (x - PUSH_CENTRE[0]) / PUSH_RADII[0]
    v = (y - PUSH_CENTRE[1]) / PUSH_RADII[1]
    d2 = u * u + v * v
    return 0.0 if d2 >= 1 else (1 - d2) ** 2

px = img.load()
res = Image.new("RGBA", img.size)
rp = res.load()
for y in range(H):
    for x in range(W):
        s = x - displacement(x, y)
        s = x - displacement(s, y)
        s -= PUSH_DX * push_weight(x, y)
        s = min(max(s, 0), W - 1.001)
        x0 = int(s); f = s - x0
        p, q = px[x0, y], px[x0 + 1, y]
        rp[x, y] = tuple(int(p[c] * (1 - f) + q[c] * f + 0.5) for c in range(4))
res.save(out)
print(f"{out}: eye column {EYES_FROM:.0f} -> {EYES_TO:.0f} (even stretch of {100 * (EYES_TO - EYES_FROM) / (EYES_FROM - LEFT_EDGE) / (1 - EASE):.0f}% at most, ears untouched), muzzle pushed {PUSH_DX:.0f} px")
