from __future__ import annotations

from pathlib import Path
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "DayGlyph" / "Assets.xcassets" / "AppIcon.appiconset"
SIZE = 1024
SAMPLES = 2


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def blend(bottom: tuple[int, int, int], top: tuple[int, int, int], alpha: float) -> tuple[int, int, int]:
    alpha = max(0.0, min(alpha, 1.0))
    return tuple(int(bottom[i] * (1 - alpha) + top[i] * alpha) for i in range(3))


def inside_rotated_round_rect(
    x: float,
    y: float,
    cx: float,
    cy: float,
    width: float,
    height: float,
    radius: float,
    rotation: float,
) -> bool:
    cos_v = math.cos(-rotation)
    sin_v = math.sin(-rotation)
    dx = x - cx
    dy = y - cy
    rx = dx * cos_v - dy * sin_v
    ry = dx * sin_v + dy * cos_v
    qx = abs(rx) - width / 2 + radius
    qy = abs(ry) - height / 2 + radius
    outside_x = max(qx, 0)
    outside_y = max(qy, 0)
    inside_distance = min(max(qx, qy), 0)
    return math.hypot(outside_x, outside_y) + inside_distance <= radius


def angle_between(angle: float, start: float, end: float) -> bool:
    angle = angle % (math.pi * 2)
    start = start % (math.pi * 2)
    end = end % (math.pi * 2)
    if start <= end:
        return start <= angle <= end
    return angle >= start or angle <= end


def pixel_color(x: float, y: float, colors: dict[str, tuple[int, int, int]]) -> tuple[int, int, int]:
    cx = cy = SIZE / 2
    color = colors["bg"]

    dist = math.hypot(x - cx, y - cy)
    ring_alpha = max(0.0, 1.0 - abs(dist - 250) / 44)
    if ring_alpha > 0:
        color = blend(color, colors["primary"], ring_alpha)

    arc_angle = math.atan2(y - cy, x - cx)
    arc_dist = math.hypot(x - cx, y - cy)
    if angle_between(arc_angle, math.radians(36), math.radians(166)):
        arc_alpha = max(0.0, 1.0 - abs(arc_dist - 210) / 38)
        if arc_alpha > 0:
            color = blend(color, colors["secondary"], arc_alpha)

    if inside_rotated_round_rect(x, y, 512, 458, 88, 420, 44, math.radians(36)):
        color = colors["accent"]

    dot_dist = math.hypot(x - 670, y - 656)
    dot_alpha = max(0.0, 1.0 - abs(dot_dist) / 58)
    if dot_alpha > 0:
        color = blend(color, colors["dot"], min(dot_alpha * 1.25, 1.0))

    # Soft inner highlight keeps the mark from feeling flat at large sizes.
    highlight = max(0.0, 1.0 - math.hypot(x - 360, y - 270) / 620)
    return blend(color, (255, 255, 255), highlight * colors["highlight"])


def write_png(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    raw_rows = []
    for row in range(SIZE):
        start = row * SIZE
        scanline = bytearray([0])
        for red, green, blue in pixels[start : start + SIZE]:
            scanline.extend((red, green, blue, 255))
        raw_rows.append(bytes(scanline))

    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    payload = b"".join(raw_rows)
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(payload, level=9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def render_icon(path: Path, palette: dict[str, str], highlight: float) -> None:
    colors = {key: hex_to_rgb(value) for key, value in palette.items()}
    colors["highlight"] = highlight
    pixels: list[tuple[int, int, int]] = []
    for y in range(SIZE):
        for x in range(SIZE):
            samples: list[tuple[int, int, int]] = []
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    samples.append(
                        pixel_color(
                            x + (sx + 0.5) / SAMPLES,
                            y + (sy + 0.5) / SAMPLES,
                            colors,
                        )
                    )
            pixels.append(tuple(sum(sample[i] for sample in samples) // len(samples) for i in range(3)))
    write_png(path, pixels)


VARIANTS = {
    "dayglyph-icon-default.png": (
        {
            "bg": "#F9F6EE",
            "primary": "#174C43",
            "secondary": "#D9B45F",
            "accent": "#C95147",
            "dot": "#174C43",
        },
        0.12,
    ),
    "dayglyph-icon-dark.png": (
        {
            "bg": "#101614",
            "primary": "#D8EEE6",
            "secondary": "#D8B762",
            "accent": "#E06A5F",
            "dot": "#F3F0E8",
        },
        0.04,
    ),
    "dayglyph-icon-tinted.png": (
        {
            "bg": "#F7F7F7",
            "primary": "#171717",
            "secondary": "#5D5D5D",
            "accent": "#2D2D2D",
            "dot": "#171717",
        },
        0.08,
    ),
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (palette, highlight) in VARIANTS.items():
        render_icon(OUT / name, palette, highlight)
    print(f"Generated {len(VARIANTS)} app icons in {OUT}")


if __name__ == "__main__":
    main()
