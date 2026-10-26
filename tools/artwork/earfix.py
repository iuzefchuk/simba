import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageMath

src, out = sys.argv[1:3]
img = Image.open(src).convert("RGBA")
AXIS = 527
FEATHER = 10
EAR_ZONE = [(640, 230), (690, 40), (780, 4), (960, 4), (960, 330), (890, 362), (800, 322), (700, 282)]
BAND_TOP, INSET = 300, 70

def premultiply(image):
    r, g, b, a = image.split()
    return tuple(ImageChops.multiply(c, a) for c in (r, g, b)), a

def unpremultiply(channels, a):
    safe = a.point(lambda v: max(v, 1))
    def divide(c):
        if hasattr(ImageMath, "lambda_eval"):
            return ImageMath.lambda_eval(lambda e: e["convert"](e["min"](e["c"] * 255 / e["a"], 255), "L"), c=c, a=safe)
        return ImageMath.eval("convert(min(c * 255 / a, 255), 'L')", c=c, a=safe)
    return tuple(divide(c) for c in channels)

alpha_px = img.split()[3].load()
def edges(y):
    xs = [x for x in range(img.width) if alpha_px[x, y] > 128]
    return (xs[0], xs[-1]) if xs else None
band = []
last = None
for y in range(BAND_TOP, img.height, 6):
    e = edges(y)
    if e is None:
        break
    left, right = e
    inner = min(right, 2 * AXIS - left) - INSET
    band.append((inner, y)); last = y
polygon = EAR_ZONE[:5] + [(960, last)] + band[::-1] + EAR_ZONE[7:]
K = 4
mask = Image.new("L", (img.width * K, img.height * K), 0)
ImageDraw.Draw(mask).polygon([(x * K, y * K) for x, y in polygon], fill=255)
mask = mask.resize(img.size, Image.LANCZOS).filter(ImageFilter.GaussianBlur(FEATHER))

mirror = Image.new("RGBA", img.size, (0, 0, 0, 0))
mirror.paste(img.transpose(Image.FLIP_LEFT_RIGHT), (2 * AXIS - img.width, 0))

(orig_rgb, orig_a), (mir_rgb, mir_a) = premultiply(img), premultiply(mirror)
out_a = Image.composite(mir_a, orig_a, mask)
out_rgb = unpremultiply(tuple(Image.composite(m, o, mask) for m, o in zip(mir_rgb, orig_rgb)), out_a)
Image.merge("RGBA", out_rgb + (out_a,)).save(out)
print(f"{out}: zone around the right ear replaced by the mirror of the left side about x={AXIS}")
