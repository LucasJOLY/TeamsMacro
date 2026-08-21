from __future__ import annotations

from PIL import Image, ImageDraw


def make_tray_icon(*, active: bool) -> Image.Image:
    size = 64
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    margin = 8
    fill = (46, 160, 67, 255) if active else (150, 150, 150, 255)
    outline = (255, 255, 255, 230)
    draw.ellipse(
        (margin, margin, size - margin, size - margin),
        fill=fill,
        outline=outline,
        width=3,
    )
    if active:
        draw.ellipse((24, 24, 40, 40), fill=(255, 255, 255, 255))
    return image
