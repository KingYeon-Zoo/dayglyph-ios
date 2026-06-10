from __future__ import annotations

from pathlib import Path
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "DayGlyph" / "Assets.xcassets" / "AppIcon.appiconset"
SIZE = 1024
SAMPLES = 2
TAU = math.pi * 2


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.removeprefix("#")
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4))


def blend(
    bottom: tuple[int, int, int],
    top: tuple[int, int, int],
    alpha: float,
) -> tuple[int, int, int]:
    alpha = max(0.0, min(alpha, 1.0))
    return tuple(round(bottom[i] * (1 - alpha) + top[i] * alpha) for i in range(3))


def smooth_coverage(distance: float, half_width: float) -> float:
    edge = 1.5
    return max(0.0, min(1.0, (half_width + edge - distance) / (edge * 2)))


def background_color(
    x: float,
    y: float,
    start: tuple[int, int, int],
    end: tuple[int, int, int],
) -> tuple[int, int, int]:
    progress = max(0.0, min(1.0, (x + y) / (SIZE * 2)))
    return blend(start, end, progress)


def spiral_distance(x: float, y: float) -> tuple[float, tuple[float, float]]:
    cx = cy = SIZE / 2
    dx = x - cx
    dy = y - cy
    radius = math.hypot(dx, dy)
    angle = math.atan2(dy, dx) % TAU

    start_angle = math.radians(166)
    end_angle = start_angle + TAU * 1.55
    outer_radius = 236.0
    inner_radius = 104.0
    best_distance = float("inf")

    for turn in range(3):
        unwrapped = angle + TAU * turn
        if start_angle <= unwrapped <= end_angle:
            progress = (unwrapped - start_angle) / (end_angle - start_angle)
            expected_radius = outer_radius + (inner_radius - outer_radius) * progress
            best_distance = min(best_distance, abs(radius - expected_radius))

    start_point = (
        cx + math.cos(start_angle) * outer_radius,
        cy + math.sin(start_angle) * outer_radius,
    )
    end_point = (
        cx + math.cos(end_angle) * inner_radius,
        cy + math.sin(end_angle) * inner_radius,
    )
    best_distance = min(
        best_distance,
        math.hypot(x - start_point[0], y - start_point[1]),
        math.hypot(x - end_point[0], y - end_point[1]),
    )
    return best_distance, end_point


def pixel_color(
    x: float,
    y: float,
    colors: dict[str, tuple[int, int, int]],
) -> tuple[int, int, int]:
    color = background_color(x, y, colors["bg_start"], colors["bg_end"])
    distance, end_point = spiral_distance(x, y)

    stroke_alpha = smooth_coverage(distance, 31)
    if stroke_alpha > 0:
        color = blend(color, colors["stroke"], stroke_alpha)

    dot_distance = math.hypot(x - end_point[0], y - end_point[1])
    dot_alpha = smooth_coverage(dot_distance, 22)
    if dot_alpha > 0:
        color = blend(color, colors["dot"], dot_alpha)

    return color


def write_png(path: Path, pixels: list[tuple[int, int, int]]) -> None:
    raw_rows = []
    for row in range(SIZE):
        start = row * SIZE
        scanline = bytearray([0])
        for red, green, blue in pixels[start : start + SIZE]:
            scanline.extend((red, green, blue))
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
        + chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(payload, level=9))
        + chunk(b"IEND", b"")
    )
    path.write_bytes(png)


def render_icon(path: Path, palette: dict[str, str]) -> None:
    colors = {key: hex_to_rgb(value) for key, value in palette.items()}
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
            pixels.append(
                tuple(
                    sum(sample[channel] for sample in samples) // len(samples)
                    for channel in range(3)
                )
            )
    write_png(path, pixels)


VARIANTS = {
    "dayglyph-icon-default.png": {
        "bg_start": "#FBFAF4",
        "bg_end": "#E1EDE5",
        "stroke": "#1C6852",
        "dot": "#EF725D",
    },
    "dayglyph-icon-dark.png": {
        "bg_start": "#12322C",
        "bg_end": "#091B18",
        "stroke": "#E6F1E8",
        "dot": "#FF806B",
    },
    "dayglyph-icon-tinted.png": {
        "bg_start": "#F4F4F4",
        "bg_end": "#DADADA",
        "stroke": "#242424",
        "dot": "#707070",
    },
}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, palette in VARIANTS.items():
        path = OUT / name
        render_icon(path, palette)
        print(path)


if __name__ == "__main__":
    main()
