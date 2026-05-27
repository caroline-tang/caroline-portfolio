#!/usr/bin/env python3
"""Recompose homepage case covers for 21:9 banner ratio (not simple center crop)."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parents[1]
IMG = ROOT / "images"
ASSETS = Path.home() / ".cursor/projects/Users-tang-Desktop-Tang-07032022-AI-Life/assets"
W, H = 1536, 658


def avg_corner_color(im: Image.Image) -> tuple[int, int, int]:
    im = im.convert("RGB")
    w, h = im.size
    pts = [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]
    rs, gs, bs = [], [], []
    for x, y in pts:
        r, g, b = im.getpixel((x, y))
        rs.append(r)
        gs.append(g)
        bs.append(b)
    return (sum(rs) // 4, sum(gs) // 4, sum(bs) // 4)


def radial_bg(size: tuple[int, int], center: tuple[float, float], inner, outer):
    tw, th = size
    bg = Image.new("RGB", size, outer)
    px = bg.load()
    cx, cy = center[0] * tw, center[1] * th
    max_d = (tw * tw + th * th) ** 0.5
    for y in range(th):
        for x in range(tw):
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5 / max_d
            t = min(d * 1.35, 1.0)
            px[x, y] = (
                int(inner[0] + (outer[0] - inner[0]) * t),
                int(inner[1] + (outer[1] - inner[1]) * t),
                int(inner[2] + (outer[2] - inner[2]) * t),
            )
    return bg


def blur_side_fill(canvas: Image.Image, layer: Image.Image, x: int, y: int) -> Image.Image:
    tw, _ = canvas.size
    lw, lh = layer.size
    left_gap = x
    right_gap = tw - (x + lw)
    out = canvas.copy()
    if left_gap > 8:
        strip = layer.crop((0, 0, min(28, lw // 6), lh)).resize((left_gap, lh), Image.Resampling.BILINEAR)
        strip = strip.filter(ImageFilter.GaussianBlur(14))
        out.paste(strip, (0, y))
    if right_gap > 8:
        strip = layer.crop((max(lw - 28, lw - lw // 6), 0, lw, lh)).resize((right_gap, lh), Image.Resampling.BILINEAR)
        strip = strip.filter(ImageFilter.GaussianBlur(14))
        out.paste(strip, (x + lw, y))
    out.paste(layer, (x, y))
    return out


def place_scaled(
    canvas: Image.Image,
    im: Image.Image,
    *,
    scale: float,
    x: float | None = None,
    y: float | None = None,
    blur_sides: bool = True,
) -> Image.Image:
    sw, sh = im.size
    nw, nh = int(sw * scale), int(sh * scale)
    layer = im.resize((nw, nh), Image.Resampling.LANCZOS)
    tw, th = canvas.size
    px = int(x if x is not None else (tw - nw) / 2)
    py = int(y if y is not None else (th - nh) / 2)
    if blur_sides:
        return blur_side_fill(canvas, layer, px, py)
    canvas.paste(layer, (px, py))
    return canvas


def save_cover(name: str, im: Image.Image) -> None:
    im = ImageEnhance.Contrast(im).enhance(1.02)
    im.save(IMG / name, "JPEG", quality=92, optimize=True)
    print("wrote", name, im.size)


# 品牌封面两版，均输出 1536×658
BRAND_AI_SCENE = ASSETS / "home-card-brand-ai-scene.jpg"
BRAND_FLATLAY_AI = ASSETS / "home-card-brand-flatlay-ai.jpg"
BRAND_REF_FLATLAY = ASSETS / "image-9ed6af16-1f35-4bc6-8c28-ee32ff19b862.png"
UI_AI = ASSETS / "home-card-ui-ai.jpg"
PACK_AI = ASSETS / "home-card-pack-ai.jpg"
DATAVIZ_AI = ASSETS / "data-case-cover-ai.jpg"
EVENTS_AI = ASSETS / "home-card-events-ai.jpg"
EVENTS_CAIXIN_AI = ASSETS / "home-card-events-caixin-ai.jpg"
EVENTS_SPLIT_EDITORIAL_AI = ASSETS / "home-card-events-split-editorial-ai.jpg"
EVENTS_SPLIT_REAL_AI = ASSETS / "home-card-events-split-real-ai.jpg"
OBJECTS_AI = ASSETS / "home-card-objects-ai.jpg"
def feather_horizontal(im: Image.Image, *, fade_left: int = 0, fade_right: int = 0) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    alpha = im.split()[3]
    px = alpha.load()
    for x in range(w):
        for y in range(h):
            m = 255
            if fade_left > 0 and x < fade_left:
                m = int(255 * (x + 1) / fade_left)
            elif fade_right > 0 and x >= w - fade_right:
                m = int(255 * (w - x) / fade_right)
            px[x, y] = int(px[x, y] * m / 255)
    im.putalpha(alpha)
    return im


def _fit_kv_panel(im: Image.Image, zone_w: int, zone_h: int, *, trim_bottom: float = 0.12) -> Image.Image:
    """裁出背板主视觉区域，去掉台下观众条，缩放进半幅留白区。"""
    im = im.convert("RGB").crop(content_bbox(im, threshold=28, pad_ratio=0.02))
    w, h = im.size
    im = im.crop((0, 0, w, max(1, int(h * (1.0 - trim_bottom)))))
    sw, sh = im.size
    scale = min(zone_w / sw, zone_h / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    return im.resize((nw, nh), Image.Resampling.LANCZOS)


def compose_events_split_abstract() -> Image.Image:
    """抽象作品集排版：两场 KV 各自独立浮于深色底，非同一现实空间。"""
    canvas = radial_bg((W, H), (0.5, 0.5), (22, 26, 44), (4, 6, 10))
    spot = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(spot)
    d.ellipse((-int(W * 0.12), int(H * 0.15), int(W * 0.38), int(H * 0.85)), fill=(255, 175, 110, 18))
    d.ellipse((int(W * 0.62), int(H * 0.15), int(W * 1.1), int(H * 0.85)), fill=(90, 150, 255, 16))
    spot = spot.filter(ImageFilter.GaussianBlur(70))
    out = Image.alpha_composite(canvas.convert("RGBA"), spot)

    gap = int(W * 0.09)
    zone_w = (W - gap) // 2 - int(W * 0.04)
    zone_h = int(H * 0.78)
    y0 = (H - zone_h) // 2

    left_kv = _fit_kv_panel(Image.open(IMG / "event-01.jpg"), zone_w, zone_h)
    right_kv = _fit_kv_panel(Image.open(IMG / "event-02.jpg"), zone_w, zone_h)
    feather = max(24, int(W * 0.04))
    left_kv = feather_horizontal(left_kv.convert("RGBA"), fade_right=feather)
    right_kv = feather_horizontal(right_kv.convert("RGBA"), fade_left=feather)

    lx = (W // 2 - gap // 2 - left_kv.size[0]) // 2
    rx = W // 2 + gap // 2 + ((W // 2 - gap // 2 - right_kv.size[0]) // 2)
    ly = y0 + (zone_h - left_kv.size[1]) // 2
    ry = y0 + (zone_h - right_kv.size[1]) // 2
    out.alpha_composite(left_kv, (lx, ly))
    out.alpha_composite(right_kv, (rx, ry))

    labels = ImageDraw.Draw(out)
    labels.text((int(W * 0.06), int(H * 0.06)), "2015", fill=(200, 210, 230, 140))
    labels.text((int(W * 0.56), int(H * 0.06)), "2014", fill=(200, 210, 230, 140))
    return ImageEnhance.Contrast(out.convert("RGB")).enhance(1.04)


def cover_crop_focal(
    im: Image.Image,
    tw: int,
    th: int,
    *,
    fx: float = 0.5,
    fy: float = 0.5,
) -> Image.Image:
    """Fill target box; fx/fy bias crop when source is wider than panel."""
    sw, sh = im.size
    scale = max(tw / sw, th / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    resized = im.resize((nw, nh), Image.Resampling.LANCZOS)
    left = max(0, min(int((nw - tw) * fx), nw - tw))
    top = max(0, min(int((nh - th) * fy), nh - th))
    return resized.crop((left, top, left + tw, top + th))


def ensure_banner_size(im: Image.Image, *, fx: float = 0.5, fy: float = 0.4) -> Image.Image:
    """强制首页横幅尺寸 1536×658。"""
    if im.size == (W, H):
        return im
    return cover_crop_focal(im.convert("RGB"), W, H, fx=fx, fy=fy)


def split_p1_business_cards() -> tuple[Image.Image, Image.Image]:
    """从详情页名片图拆出幼儿园 / 大手小手两张卡（标志原图）。"""
    src = Image.open(IMG / "brand-p1-01.jpg").convert("RGB")
    w, h = src.size
    split = int(w * 0.50)
    y0, y1 = int(h * 0.13), int(h * 0.87)
    pad = int(w * 0.022)
    kindergarten = src.crop((pad, y0, split - pad, y1))
    club = src.crop((split + pad, y0, w - pad, y1))
    return kindergarten, club


def resize_to_width(im: Image.Image, tw: int) -> Image.Image:
    th = max(1, int(im.size[1] * tw / im.size[0]))
    return im.resize((tw, th), Image.Resampling.LANCZOS)


def paste_card_shadow(canvas: Image.Image, card: Image.Image, xy: tuple[int, int]) -> Image.Image:
    """轻阴影后贴名片，保证幼儿园标志清晰完整。"""
    x, y = xy
    out = canvas.convert("RGBA")
    sh = Image.new("RGBA", card.size, (0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    out.paste(sh, (x + 7, y + 9), sh)
    out.paste(card, (x, y))
    return out.convert("RGB")


def export_brand_scene_cover() -> Image.Image:
    """版一：AI 实景场景（园所折页 + IICE 物料）。"""
    src_path = BRAND_AI_SCENE if BRAND_AI_SCENE.exists() else IMG / "home-card-brand.jpg"
    out = ensure_banner_size(Image.open(src_path).convert("RGB"), fx=0.50, fy=0.40)
    return ImageEnhance.Contrast(out).enhance(1.03)


def export_brand_flatlay_cover() -> Image.Image:
    """版二：深色 flat lay 风格；幼儿园名片为详情页原图叠印，标志 100% 还原。"""
    src_path = BRAND_FLATLAY_AI if BRAND_FLATLAY_AI.exists() else BRAND_REF_FLATLAY
    base = ensure_banner_size(Image.open(src_path).convert("RGB"), fx=0.50, fy=0.36)

    if BRAND_REF_FLATLAY.exists():
        ref = Image.open(BRAND_REF_FLATLAY).convert("RGB")
        rw, rh = ref.size
        chips = ref.crop((int(rw * 0.01), int(rh * 0.50), int(rw * 0.19), int(rh * 0.99)))
        cw = int(W * 0.075)
        chips = resize_to_width(chips, cw)
        cy = (H - chips.size[1]) // 2 + int(H * 0.04)
        base.paste(chips, (int(W * 0.018), cy))

    k_card, club_card = split_p1_business_cards()
    card_w = int(W * 0.245)
    k_card = resize_to_width(k_card, card_w)
    club_card = resize_to_width(club_card, card_w)
    gap = int(H * 0.028)
    total_h = k_card.size[1] + gap + club_card.size[1]
    y0 = (H - total_h) // 2 + int(H * 0.02)
    x0 = int(W * 0.105)
    base = paste_card_shadow(base, k_card, (x0, y0))
    base = paste_card_shadow(base, club_card, (x0, y0 + k_card.size[1] + gap))

    return ImageEnhance.Contrast(base).enhance(1.04)


def content_bbox(im: Image.Image, threshold: int = 26, pad_ratio: float = 0.025) -> tuple[int, int, int, int]:
    """Bounding box of non-background pixels (studio margins excluded)."""
    im = im.convert("RGB")
    ref = avg_corner_color(im)
    w, h = im.size
    px = im.load()
    xs: list[int] = []
    ys: list[int] = []
    for y in range(h):
        for x in range(w):
            r, g, b = px[x, y]
            if abs(r - ref[0]) + abs(g - ref[1]) + abs(b - ref[2]) > threshold:
                xs.append(x)
                ys.append(y)
    if not xs:
        return (0, 0, w, h)
    pad_x = int(w * pad_ratio)
    pad_y = int(h * pad_ratio)
    return (
        max(0, min(xs) - pad_x),
        max(0, min(ys) - pad_y),
        min(w, max(xs) + pad_x),
        min(h, max(ys) + pad_y),
    )


def fit_native_banner(src_path: Path, *, spotlight: bool = True) -> Image.Image:
    """Place a horizontally composed hero into 21:9 — trim empty margins, not a center crop."""
    src = Image.open(src_path).convert("RGB")
    crop = src.crop(content_bbox(src))
    cw, ch = crop.size
    scale = min(W / cw, H / ch)
    nw, nh = int(cw * scale), int(ch * scale)
    layer = crop.resize((nw, nh), Image.Resampling.LANCZOS)
    inner = avg_corner_color(src)
    outer = tuple(max(0, c - 20) for c in inner)
    canvas = radial_bg((W, H), (0.44, 0.46), inner, outer)
    if spotlight:
        spot = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(spot).ellipse(
            (int(W * 0.08), -int(H * 0.2), int(W * 0.72), int(H * 0.95)),
            fill=(255, 198, 130, 42),
        )
        spot = spot.filter(ImageFilter.GaussianBlur(72))
        canvas = Image.alpha_composite(canvas.convert("RGBA"), spot).convert("RGB")
    px, py = (W - nw) // 2, (H - nh) // 2
    out = blur_side_fill(canvas, layer, px, py)
    refl_h = max(8, int(nh * 0.12))
    refl = ImageOps.flip(layer.crop((0, nh - refl_h, nw, nh)))
    refl = ImageEnhance.Brightness(refl).enhance(0.2)
    mask = Image.linear_gradient("L").resize((nw, refl_h))
    refl.putalpha(mask)
    out = out.convert("RGBA")
    out.alpha_composite(refl, (px, py + nh + 1))
    return out.convert("RGB")


def recompose_brand() -> None:
    scene = export_brand_scene_cover()
    flatlay = export_brand_flatlay_cover()
    save_cover("home-card-brand.jpg", scene)
    save_cover("home-card-brand-scene.jpg", scene)
    save_cover("home-card-brand-flatlay.jpg", flatlay)


def export_ai_scene_cover(
    asset: Path,
    fallback: str,
    *,
    fx: float = 0.5,
    fy: float = 0.4,
    contrast: float = 1.03,
) -> Image.Image:
    src_path = asset if asset.exists() else IMG / fallback
    out = ensure_banner_size(Image.open(src_path).convert("RGB"), fx=fx, fy=fy)
    return ImageEnhance.Contrast(out).enhance(contrast)


def recompose_ui() -> None:
    save_cover(
        "home-card-ui.jpg",
        export_ai_scene_cover(UI_AI, "home-card-ui.jpg", fx=0.50, fy=0.42),
    )


def recompose_pack() -> None:
    save_cover(
        "home-card-pack.jpg",
        export_ai_scene_cover(PACK_AI, "home-card-pack.jpg", fx=0.50, fy=0.44),
    )


def recompose_dataviz() -> None:
    save_cover(
        "data-case-cover.jpg",
        export_ai_scene_cover(DATAVIZ_AI, "data-case-cover.jpg", fx=0.50, fy=0.36),
    )


def recompose_events() -> None:
    save_cover(
        "home-card-events.jpg",
        export_ai_scene_cover(EVENTS_AI, "home-card-events.jpg", fx=0.50, fy=0.34),
    )


def recompose_events_caixin() -> None:
    """会展封面 · 仅财新夜话主视觉（2014 夏季达沃斯）。"""
    save_cover(
        "home-card-events-caixin.jpg",
        export_ai_scene_cover(EVENTS_CAIXIN_AI, "home-card-events-caixin.jpg", fx=0.50, fy=0.36),
    )


def export_cover_contain(
    asset: Path,
    fallback: str,
    *,
    contrast: float = 1.03,
) -> Image.Image:
    """整图缩放进横幅，两侧虚化延伸（保留完整排版）。"""
    src_path = asset if asset.exists() else IMG / fallback
    src = Image.open(src_path).convert("RGB")
    sw, sh = src.size
    scale = min(W / sw, H / sh)
    nw, nh = int(sw * scale), int(sh * scale)
    layer = src.resize((nw, nh), Image.Resampling.LANCZOS)
    inner = avg_corner_color(src)
    outer = tuple(max(0, c - 18) for c in inner)
    canvas = radial_bg((W, H), (0.5, 0.5), inner, outer)
    px, py = (W - nw) // 2, (H - nh) // 2
    out = blur_side_fill(canvas, layer, px, py)
    return ImageEnhance.Contrast(out).enhance(contrast)


def recompose_events_split() -> None:
    """会展封面 · 双案例真实场景（搭建现场两块独立易拉宝）。"""
    src = EVENTS_SPLIT_REAL_AI if EVENTS_SPLIT_REAL_AI.exists() else EVENTS_SPLIT_EDITORIAL_AI
    if src.exists():
        out = export_ai_scene_cover(src, "home-card-events-split.jpg", fx=0.50, fy=0.42)
    else:
        out = compose_events_split_abstract()
    save_cover("home-card-events-split.jpg", out)


def recompose_events_all() -> None:
    recompose_events()
    recompose_events_caixin()
    recompose_events_split()


def recompose_objects() -> None:
    save_cover(
        "home-card-objects.jpg",
        export_ai_scene_cover(OBJECTS_AI, "home-card-objects.jpg", fx=0.50, fy=0.62),
    )


def main() -> None:
    recompose_ui()
    recompose_pack()
    recompose_dataviz()
    recompose_events()
    recompose_objects()


def main_all() -> None:
    recompose_brand()
    main()


if __name__ == "__main__":
    main()
