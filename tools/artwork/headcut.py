import math
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

photo, mask, out = sys.argv[1:4]
ax, ay, arx, ary, bx, by, brx, bry, lx, ly, rx, ry = (float(v) for v in sys.argv[4:16])
gx, gy = (float(v) for v in sys.argv[16:18]) if len(sys.argv) >= 18 else (0.0, 0.0)
img = Image.open(photo).convert("RGBA")

def nudge_gaze(image, centre, radius, dx, dy):
    src = image.load()
    out = image.copy()
    dst = out.load()
    ex, ey = centre
    w, h = image.size

    def sample(x, y):
        x = min(max(x, 0), w - 1.001); y = min(max(y, 0), h - 1.001)
        x0, y0 = int(x), int(y); fx, fy = x - x0, y - y0
        p00, p10, p01, p11 = src[x0, y0], src[x0 + 1, y0], src[x0, y0 + 1], src[x0 + 1, y0 + 1]
        return tuple(int(round((p00[c] * (1 - fx) + p10[c] * fx) * (1 - fy) + (p01[c] * (1 - fx) + p11[c] * fx) * fy)) for c in range(4))

    for y in range(int(ey - radius), int(ey + radius) + 1):
        for x in range(int(ex - radius), int(ex + radius) + 1):
            d = math.hypot(x - ex, y - ey) / radius
            if d >= 1:
                continue
            k = (1 - d * d) ** 2
            dst[x, y] = sample(x - dx * k, y - dy * k)
    return out

if gx or gy:
    eye_radius = 0.32 * math.hypot(rx - lx, ry - ly)
    for eye in ((lx, ly), (rx, ry)):
        img = nudge_gaze(img, eye, eye_radius, gx, gy)
    lx, ly, rx, ry = lx + gx, ly + gy, rx + gx, ry + gy
subject = Image.open(mask).convert("L")
if subject.size != img.size:
    subject = subject.resize(img.size, Image.LANCZOS)

K = 4
region = Image.new("L", (img.width * K, img.height * K), 0)
d = ImageDraw.Draw(region)
d.ellipse(((ax - arx) * K, (ay - ary) * K, (ax + arx) * K, (ay + ary) * K), fill=255)
d.ellipse(((bx - brx) * K, (by - bry) * K, (bx + brx) * K, (by + bry) * K), fill=255)
region = region.resize(img.size, Image.LANCZOS).filter(ImageFilter.GaussianBlur(5))
head = img.copy()
head.putalpha(ImageChops.multiply(subject, region))

mx, my = (lx + rx) / 2, (ly + ry) / 2
tilt = math.degrees(math.atan2(ry - ly, rx - lx))
head = head.rotate(tilt, resample=Image.BICUBIC, center=(mx, my), fillcolor=(0, 0, 0, 0))
eye_distance = math.hypot(rx - lx, ry - ly)
cx, cy = mx, my + 0.35 * eye_distance

bbox = head.split()[3].point(lambda a: 255 if a > 8 else 0).getbbox()
reach = max(cx - bbox[0], bbox[2] - cx, cy - bbox[1], bbox[3] - cy)
side = reach * 2 * 1.04
square = head.crop((int(round(cx - side / 2)), int(round(cy - side / 2)), int(round(cx + side / 2)), int(round(cy + side / 2))))
square.resize((1024, 1024), Image.LANCZOS).save(out)
print(f"{out}: levelled {tilt:.1f}°, centred on ({cx:.0f}, {cy:.0f}), crop {int(side)} px square")
