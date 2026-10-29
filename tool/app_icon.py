"""Draws the REBS Workspace logo: five people joined in a ring.

Each figure is a round head over a tapering, curved body; five copies are
rotated 72 degrees apart so the bodies interlock. Rendered at 4x and scaled
down for smooth edges.

Writes every launcher icon from the drawing below. Run from the project
root (needs Pillow):

    python3 tool/app_icon.py

Outputs: Android legacy and adaptive icons, the iOS AppIcon set, and
assets/branding/logo_1024.png (transparent) for other uses.
"""

import json
import math
import os

from PIL import Image, ImageDraw

COLORS = [
    (214, 51, 138),   # magenta
    (245, 166, 35),   # amber
    (45, 156, 219),   # blue
    (124, 191, 66),   # green
    (232, 69, 44),    # red
]

# One figure, head at the top, in a unit square centred on (0, 0) with y
# pointing down. The body is a cubic Bezier centreline with a width that
# starts full at the shoulders and tapers to a point.
HEAD = (0.0, -0.79)
HEAD_R = 0.125
BODY = [(-0.02, -0.57), (0.44, -0.50), (0.48, 0.08), (0.02, 0.38)]
BODY_W = 0.23
TAIL_END = 0.86


def bezier(p, t):
    u = 1 - t
    return (
        u**3 * p[0][0] + 3 * u * u * t * p[1][0] + 3 * u * t * t * p[2][0] + t**3 * p[3][0],
        u**3 * p[0][1] + 3 * u * u * t * p[1][1] + 3 * u * t * t * p[2][1] + t**3 * p[3][1],
    )


def body_polygon(steps=120):
    left, right = [], []
    for i in range(steps + 1):
        # Stop before the tip so the tail ends rounded, not as a hairline.
        t = TAIL_END * i / steps
        x, y = bezier(BODY, t)
        x2, y2 = bezier(BODY, min(1, t + 1e-3))
        x1, y1 = bezier(BODY, max(0, t - 1e-3))
        dx, dy = x2 - x1, y2 - y1
        n = math.hypot(dx, dy) or 1
        nx, ny = -dy / n, dx / n
        # Full at the shoulders, swelling slightly, then tapering to a point.
        w = BODY_W * (1 - t) ** 0.9 * (1 + 0.25 * math.sin(math.pi * t))
        left.append((x + nx * w / 2, y + ny * w / 2))
        right.append((x - nx * w / 2, y - ny * w / 2))
    return left + right[::-1]


def rotate(pt, angle):
    c, s = math.cos(angle), math.sin(angle)
    return (pt[0] * c - pt[1] * s, pt[0] * s + pt[1] * c)


def render(size, transparent=False, scale=0.86):
    ss = 4
    big = size * ss
    bg = (0, 0, 0, 0) if transparent else (255, 255, 255, 255)
    img = Image.new("RGBA", (big, big), bg)
    draw = ImageDraw.Draw(img)

    def to_px(pt):
        return (big / 2 + pt[0] * big / 2 * scale, big / 2 + pt[1] * big / 2 * scale)

    body = body_polygon()
    figures = []
    for k, color in enumerate(COLORS):
        angle = math.radians(72 * k)
        figures.append((angle, color))

    for angle, color in figures:
        draw.polygon([to_px(rotate(p, angle)) for p in body], fill=color)
        sx, sy = to_px(rotate(BODY[0], angle))
        r = BODY_W / 2 * big / 2 * scale
        draw.ellipse((sx - r, sy - r, sx + r, sy + r), fill=color)
        # Rounded tail end.
        tx, ty = to_px(rotate(bezier(BODY, TAIL_END), angle))
        tw = (
            BODY_W
            * (1 - TAIL_END) ** 0.9
            * (1 + 0.25 * math.sin(math.pi * TAIL_END))
        )
        tr = tw / 2 * big / 2 * scale
        draw.ellipse((tx - tr, ty - tr, tx + tr, ty + tr), fill=color)

    for angle, color in figures:
        hx, hy = to_px(rotate(HEAD, angle))
        r = HEAD_R * big / 2 * scale
        draw.ellipse((hx - r, hy - r, hx + r, hy + r), fill=color)

    return img.resize((size, size), Image.LANCZOS)


ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")
IOS = os.path.join(ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")

# Legacy square icons: logo on white with a margin.
ANDROID_LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# Adaptive foreground is 108 dp; the logo must sit in the 66 dp safe zone.
ANDROID_ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
"""

COLORS_XML = """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#FFFFFF</color>
</resources>
"""


def save(image, path, opaque=True):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (image.convert("RGB") if opaque else image).save(path, optimize=True)


def main():
    for density, size in ANDROID_LEGACY.items():
        save(render(size, scale=0.80), os.path.join(RES, f"mipmap-{density}", "ic_launcher.png"))
    for density, size in ANDROID_ADAPTIVE.items():
        save(
            render(size, transparent=True, scale=0.58),
            os.path.join(RES, f"mipmap-{density}", "ic_launcher_foreground.png"),
            opaque=False,
        )
    anydpi = os.path.join(RES, "mipmap-anydpi-v26")
    os.makedirs(anydpi, exist_ok=True)
    with open(os.path.join(anydpi, "ic_launcher.xml"), "w") as f:
        f.write(ADAPTIVE_XML)
    with open(os.path.join(RES, "values", "ic_launcher_background.xml"), "w") as f:
        f.write(COLORS_XML)

    # iOS: opaque (App Store rejects alpha); the system rounds the corners.
    with open(os.path.join(IOS, "Contents.json")) as f:
        images = json.load(f)["images"]
    for entry in images:
        points = float(entry["size"].split("x")[0])
        pixels = round(points * int(entry["scale"].rstrip("x")))
        save(render(pixels, scale=0.80), os.path.join(IOS, entry["filename"]))

    save(
        render(1024, transparent=True, scale=0.96),
        os.path.join(ROOT, "assets", "branding", "logo_1024.png"),
        opaque=False,
    )


if __name__ == "__main__":
    main()
