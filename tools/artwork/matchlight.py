import math
import sys
from PIL import Image, ImageFilter, ImageStat

ref_path, src_path, out = sys.argv[1:4]
ref, src = Image.open(ref_path).convert("RGBA"), Image.open(src_path).convert("RGBA")

def fur_mask(img):
    a = img.split()[3].point(lambda v: 255 if v > 200 else 0)
    a.paste(0, (0, int(img.height * 0.6), img.width, img.height))
    return a

def stats(img):
    s = ImageStat.Stat(img.convert("RGB"), fur_mask(img))
    return s.mean, s.stddev

def softness(img):
    edges = img.convert("L").filter(ImageFilter.FIND_EDGES)
    return ImageStat.Stat(edges, fur_mask(img)).stddev[0]

(rm, rs), (sm, ss) = stats(ref), stats(src)
r, g, b, a = src.split()
matched = []
for ch, mean_r, std_r, mean_s, std_s in zip((r, g, b), rm, rs, sm, ss):
    gain = std_r / std_s
    matched.append(ch.point(lambda v, gain=gain, ms=mean_s, mr=mean_r: int(min(max((v - ms) * gain + mr, 0), 255) + 0.5)))
rgb = Image.merge("RGB", matched)

soft_ref, soft_src = softness(ref), softness(src)
note = ""
if soft_src < soft_ref * 0.85:
    amount = int(min(120, 100 * (soft_ref / soft_src - 1)))
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=2, percent=amount, threshold=2))
    note = f", sharpened {amount}%"
crisp = a.point(lambda v: int(255 * min(max((v - 60) / 135, 0), 1) ** 1.0 + 0.5))
blend = Image.new("L", a.size, 255)
for y in range(int(a.height * 0.58), int(a.height * 0.70)):
    blend.paste(int(255 * (1 - (y - a.height * 0.58) / (a.height * 0.12))), (0, y, a.width, y + 1))
blend.paste(0, (0, int(a.height * 0.70), a.width, a.height))
a = Image.composite(crisp, a, blend)
result = Image.merge("RGBA", rgb.split() + (a,))
result.save(out)
print(f"{out}: means {tuple(round(v) for v in sm)} -> {tuple(round(v) for v in rm)}, "
      f"spread {tuple(round(v) for v in ss)} -> {tuple(round(v) for v in rs)}{note} "
      f"(edge energy {soft_src:.1f} vs reference {soft_ref:.1f})")
