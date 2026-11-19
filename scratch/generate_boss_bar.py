#!/usr/bin/env python3
from PIL import Image, ImageDraw

# Boss Bar Under (Dark metallic bezel with crimson hazard border)
w, h = 480, 20
img_u = Image.new("RGBA", (w, h), (18, 12, 14, 230))
draw_u = ImageDraw.Draw(img_u)
draw_u.rectangle([(0, 0), (w - 1, h - 1)], outline=(255, 40, 40, 255), width=2)
# Internal tick markers
for x in range(40, w - 40, 40):
    draw_u.line([(x, 2), (x, h - 3)], fill=(80, 20, 20, 180), width=1)
img_u.save("assets/ui/tex_bar_under_boss.png", "PNG")

# Boss Bar Fill (Crimson to gold hazard gradient)
img_f = Image.new("RGBA", (w, h), (0, 0, 0, 0))
draw_f = ImageDraw.Draw(img_f)
for x in range(w):
    ratio = x / w
    # Red to Orange-Gold
    r = int(220 + 35 * ratio)
    g = int(30 + 120 * ratio)
    b = int(20 + 10 * ratio)
    draw_f.line([(x, 2), (x, h - 3)], fill=(r, g, b, 255))
# Top highlight sheen
draw_f.line([(2, 3), (w - 3, 3)], fill=(255, 230, 200, 200), width=1)
img_f.save("assets/ui/tex_bar_fill_boss.png", "PNG")

print("[OK] Generated boss bar textures")
