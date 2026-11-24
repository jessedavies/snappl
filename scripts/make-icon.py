"""Builds Resources/AppIcon.icns: the app's snap glyph as a glass panel over
Clarice Beckett's Passing Trams. Run from the repo root with python3 -I.
Needs Pillow. Re-run only when the icon design changes."""
import pathlib, shutil, subprocess, sys
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance, ImageOps

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "Resources/Icon/passing-trams.jpg"
OUT = ROOT / "Resources/AppIcon.icns"
INK = (29, 35, 43)
S = 1024                    # canvas
BODY, R = 824, 186          # macOS icon grid: 824 body, ~22.5% corner radius
OFF = (S - BODY) // 2

def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return m

# Painting, cropped square around the tram lamps, kept dark: dusk with the
# lamps glowing, so the white panel is the one sharp contrast and the icon
# stands out on light Finder and DMG backgrounds.
p = Image.open(SRC).convert("RGB")
w, h = p.size
# Square around the trams and the right-hand lamps.
side = int(w * 0.75)
left, top = w - side, int(h * 0.21)
crop = p.crop((left, top, left + side, top + side)).resize((BODY, BODY), Image.LANCZOS)
# The painting is fog-grey, so map its tones onto dusk blue (keeps every
# brushstroke), then lay the original colour back over the warm lamps.
grey = ImageEnhance.Contrast(crop.convert("L")).enhance(1.35)
duo = ImageOps.colorize(grey, black=(16, 22, 34), mid=(58, 76, 102), white=(170, 188, 208))
warm = ImageEnhance.Color(crop).enhance(2.2)
lamps = Image.eval(ImageEnhance.Color(crop).enhance(3.0).convert("HSV").split()[1], lambda s: 255 if s > 120 else int(s * 1.4))
art = Image.composite(warm, duo, lamps.filter(ImageFilter.GaussianBlur(6)))

# Glass panel: the painting behind it blurred and washed white, a hairline
# highlight, and a soft shadow. Inside, the left-half fill in ink.
PW, PH, PR = 560, 420, 72
px, py = (BODY - PW) // 2, (BODY - PH) // 2 + 6
shadow = Image.new("RGBA", art.size, (0, 0, 0, 0))
ImageDraw.Draw(shadow).rounded_rectangle((px, py + 18, px + PW, py + PH + 18), PR, fill=(0, 0, 0, 120))
shadow = shadow.filter(ImageFilter.GaussianBlur(28))
body = art.convert("RGBA")
body.alpha_composite(shadow)

glass = art.crop((px, py, px + PW, py + PH)).filter(ImageFilter.GaussianBlur(26))
glass = Image.blend(glass, Image.new("RGB", glass.size, (255, 255, 255)), 0.86).convert("RGBA")
d = ImageDraw.Draw(glass)
d.rounded_rectangle((1, 1, PW - 2, PH - 2), PR, outline=(255, 255, 255, 230), width=3)
inset = 40
d.rounded_rectangle((inset, inset, PW // 2 - 6, PH - inset), 34, fill=(*INK, 240))
body.paste(glass, (px, py), rounded_mask((PW, PH), PR))

# Clip to the icon shape, add the standard soft drop shadow.
icon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
drop = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ImageDraw.Draw(drop).rounded_rectangle((OFF, OFF + 12, OFF + BODY, OFF + BODY + 12), R, fill=(0, 0, 0, 90))
icon.alpha_composite(drop.filter(ImageFilter.GaussianBlur(14)))
clipped = Image.new("RGBA", (BODY, BODY), (0, 0, 0, 0))
clipped.paste(body, (0, 0), rounded_mask((BODY, BODY), R))
icon.alpha_composite(clipped, (OFF, OFF))

iconset = ROOT / "build/AppIcon.iconset"
shutil.rmtree(iconset, ignore_errors=True)
iconset.mkdir(parents=True)
for base in (16, 32, 128, 256, 512):
    for scale in (1, 2):
        px_size = base * scale
        name = f"icon_{base}x{base}{'@2x' if scale == 2 else ''}.png"
        icon.resize((px_size, px_size), Image.LANCZOS).save(iconset / name)
icon.save(ROOT / "build/AppIcon-1024.png")
subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(OUT)], check=True)
print("wrote", OUT)
