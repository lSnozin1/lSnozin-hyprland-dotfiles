"""
folder_icon_core.py - Shared SVG generation, symbol, alias, registry,
and .directory engine for folder-icon (CLI) and folder-icon-gui (PySide6).
"""

from datetime import datetime, timezone
from pathlib import Path
import hashlib
import json
import os
import re
import subprocess
import urllib.error
import urllib.request

# ---------------------------------------------------------------------------
# CONFIGURATION & PATHS
# ---------------------------------------------------------------------------

OUTPUT_DIR = Path.home() / ".local" / "share" / "folder-icons"
SYMBOL_DIR = OUTPUT_DIR / "symbols"
ALIAS_FILE = OUTPUT_DIR / "aliases.json"
GUI_STATE_FILE = OUTPUT_DIR / "gui_state.json"
REGISTRY_FILE = OUTPUT_DIR / "registry.json"
LUCIDE_INDEX_FILE = OUTPUT_DIR / "lucide_index.json"

LUCIDE_TREE_API_URL = "https://api.github.com/repos/lucide-icons/lucide/git/trees/main?recursive=1"
LUCIDE_RAW_SVG_URL = "https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/{name}.svg"

# Symbol overlay defaults
SYMBOL_OPACITY = 1.0
SYMBOL_CONTRAST_MODE = "auto"   # "auto", "black", or "white"
SYMBOL_SCALE = 0.45             # 0.45 centered; 0.35 - 0.60 range
MIN_SYMBOL_SCALE = 0.25
MAX_SYMBOL_SCALE = 0.75

BODY_X, BODY_Y, BODY_W, BODY_H = 3, 20, 58, 38

# Heavy internal/build directories skipped during filesystem GC scans
# (Explicitly tracked paths in registry.json are always checked directly)
SKIP_SCAN_DIRS: frozenset[str] = frozenset({
    "node_modules",
    ".git",
    ".hg",
    ".svn",
    "__pycache__",
    ".venv",
    "venv",
    ".cache",
    ".npm",
    ".cargo",
    ".rustup",
    ".gradle",
    ".m2",
    "dist",
    "build",
    "target",
    ".next",
    ".nuxt",
    "prisma",
})

# ---------------------------------------------------------------------------
# BUILT-IN OFFICIAL LUCIDE SYMBOLS (ISC license, https://lucide.dev)
# ---------------------------------------------------------------------------

LUCIDE_SYMBOLS: dict[str, str] = {
    "activity": "<path d=\"M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2\" />",
    "bike": "<circle cx=\"18.5\" cy=\"17.5\" r=\"3.5\" />\n  <circle cx=\"5.5\" cy=\"17.5\" r=\"3.5\" />\n  <circle cx=\"15\" cy=\"5\" r=\"1\" />\n  <path d=\"M12 17.5V14l-3-3 4-3 2 3h2\" />",
    "book": "<path d=\"M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H19a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H6.5a1 1 0 0 1 0-5H20\" />",
    "briefcase": "<path d=\"M16 20V4a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16\" />\n  <rect width=\"20\" height=\"14\" x=\"2\" y=\"6\" rx=\"2\" />",
    "clock": "<circle cx=\"12\" cy=\"12\" r=\"10\" />\n  <path d=\"M12 6v6l4 2\" />",
    "code": "<path d=\"m16 18 6-6-6-6\" />\n  <path d=\"m8 6-6 6 6 6\" />",
    "coffee": "<path d=\"M10 2v2\" />\n  <path d=\"M14 2v2\" />\n  <path d=\"M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1\" />\n  <path d=\"M6 2v2\" />",
    "cuboid": "<path d=\"M10 22v-8\" />\n  <path d=\"M2.336 8.89 10 14l11.715-7.029\" />\n  <path d=\"M22 14a2 2 0 0 1-.971 1.715l-10 6a2 2 0 0 1-2.138-.05l-6-4A2 2 0 0 1 2 16v-6a2 2 0 0 1 .971-1.715l10-6a2 2 0 0 1 2.138.05l6 4A2 2 0 0 1 22 8z\" />",
    "dumbbell": "<path d=\"M17.596 12.768a2 2 0 1 0 2.829-2.829l-1.768-1.767a2 2 0 0 0 2.828-2.829l-2.828-2.828a2 2 0 0 0-2.829 2.828l-1.767-1.768a2 2 0 1 0-2.829 2.829z\" />\n  <path d=\"m2.5 21.5 1.4-1.4\" />\n  <path d=\"m20.1 3.9 1.4-1.4\" />\n  <path d=\"M5.343 21.485a2 2 0 1 0 2.829-2.828l1.767 1.768a2 2 0 1 0 2.829-2.829l-6.364-6.364a2 2 0 1 0-2.829 2.829l1.768 1.767a2 2 0 0 0-2.828 2.829z\" />\n  <path d=\"m9.6 14.4 4.8-4.8\" />",
    "eighth-notes": "<path d=\"M21 16V3a1 1 0 0 0-1.28-.96l-10 2.917a1 1 0 0 0-.72.96V19\" />\n  <circle cx=\"18\" cy=\"16\" r=\"3\" />\n  <circle cx=\"6\" cy=\"19\" r=\"3\" />",
    "flag": "<path d=\"M4 22V4a1 1 0 0 1 .4-.8A6 6 0 0 1 8 2c3 0 5 2 7.333 2q2 0 3.067-.8A1 1 0 0 1 20 4v10a1 1 0 0 1-.4.8A6 6 0 0 1 16 16c-3 0-5-2-8-2a6 6 0 0 0-4 1.528\" />",
    "flower": "<circle cx=\"12\" cy=\"12\" r=\"3\" />\n  <path d=\"M12 16.5A4.5 4.5 0 1 1 7.5 12 4.5 4.5 0 1 1 12 7.5a4.5 4.5 0 1 1 4.5 4.5 4.5 4.5 0 1 1-4.5 4.5\" />\n  <path d=\"M12 7.5V9\" />\n  <path d=\"M7.5 12H9\" />\n  <path d=\"M16.5 12H15\" />\n  <path d=\"M12 16.5V15\" />\n  <path d=\"m8 8 1.88 1.88\" />\n  <path d=\"M14.12 9.88 16 8\" />\n  <path d=\"m8 16 1.88-1.88\" />\n  <path d=\"M14.12 14.12 16 16\" />",
    "folder": "<path d=\"M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z\" />",
    "gamepad": "<line x1=\"6\" x2=\"10\" y1=\"12\" y2=\"12\" />\n  <line x1=\"8\" x2=\"8\" y1=\"10\" y2=\"14\" />\n  <line x1=\"15\" x2=\"15.01\" y1=\"13\" y2=\"13\" />\n  <line x1=\"18\" x2=\"18.01\" y1=\"11\" y2=\"11\" />\n  <rect width=\"20\" height=\"12\" x=\"2\" y=\"6\" rx=\"2\" />",
    "gem": "<path d=\"M10.5 3 8 9l4 13 4-13-2.5-6\" />\n  <path d=\"M17 3a2 2 0 0 1 1.6.8l3 4a2 2 0 0 1 .013 2.382l-7.99 10.986a2 2 0 0 1-3.247 0l-7.99-10.986A2 2 0 0 1 2.4 7.8l2.998-3.997A2 2 0 0 1 7 3z\" />\n  <path d=\"M2 9h20\" />",
    "gift": "<path d=\"M12 7v14\" />\n  <path d=\"M20 11v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8\" />\n  <path d=\"M7.5 7a1 1 0 0 1 0-5A4.8 8 0 0 1 12 7a4.8 8 0 0 1 4.5-5 1 1 0 0 1 0 5\" />\n  <rect x=\"3\" y=\"7\" width=\"18\" height=\"4\" rx=\"1\" />",
    "globe": "<circle cx=\"12\" cy=\"12\" r=\"10\" />\n  <path d=\"M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20\" />\n  <path d=\"M2 12h20\" />",
    "hammer": "<path d=\"m15 12-9.373 9.373a1 1 0 0 1-3.001-3L12 9\" />\n  <path d=\"m18 15 4-4\" />\n  <path d=\"m21.5 11.5-1.914-1.914A2 2 0 0 1 19 8.172v-.344a2 2 0 0 0-.586-1.414l-1.657-1.657A6 6 0 0 0 12.516 3H9l1.243 1.243A6 6 0 0 1 12 8.485V10l2 2h1.172a2 2 0 0 1 1.414.586L18.5 14.5\" />",
    "heart": "<path d=\"M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5\" />",
    "image": "<rect width=\"18\" height=\"18\" x=\"3\" y=\"3\" rx=\"2\" ry=\"2\" />\n  <circle cx=\"9\" cy=\"9\" r=\"2\" />\n  <path d=\"m21 15-3.086-3.086a2 2 0 0 0-2.828 0L6 21\" />",
    "leaf": "<path d=\"M11 20a10 10 0 0010-10 25.9 25.9 0 00-1.04-7.281 1 1 0 00-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0011 20\" />\n  <path d=\"M2 21a5 5 0 012.911-4.544C7.613 15.212 8.351 15.24 11 13\" />",
    "lightbulb": "<path d=\"M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5\" />\n  <path d=\"M9 18h6\" />\n  <path d=\"M10 22h4\" />",
    "message-circle": "<path d=\"M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719\" />",
    "message-square": "<path d=\"M22 17a2 2 0 0 1-2 2H6.828a2 2 0 0 0-1.414.586l-2.202 2.202A.71.71 0 0 1 2 21.286V5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2z\" />",
    "notebook-text": "<path d=\"M2 6h4\" />\n  <path d=\"M2 10h4\" />\n  <path d=\"M2 14h4\" />\n  <path d=\"M2 18h4\" />\n  <rect width=\"16\" height=\"20\" x=\"4\" y=\"2\" rx=\"2\" />\n  <path d=\"M9.5 8h5\" />\n  <path d=\"M9.5 12H16\" />\n  <path d=\"M9.5 16H14\" />",
    "palette": "<path d=\"M12 22a1 1 0 0 1 0-20 10 9 0 0 1 10 9 5 5 0 0 1-5 5h-2.25a1.75 1.75 0 0 0-1.4 2.8l.3.4a1.75 1.75 0 0 1-1.4 2.8z\" />\n  <circle cx=\"13.5\" cy=\"6.5\" r=\".5\" fill=\"currentColor\" />\n  <circle cx=\"17.5\" cy=\"10.5\" r=\".5\" fill=\"currentColor\" />\n  <circle cx=\"6.5\" cy=\"12.5\" r=\".5\" fill=\"currentColor\" />\n  <circle cx=\"8.5\" cy=\"7.5\" r=\".5\" fill=\"currentColor\" />",
    "paw-print": "<circle cx=\"11\" cy=\"4\" r=\"2\" />\n  <circle cx=\"18\" cy=\"8\" r=\"2\" />\n  <circle cx=\"20\" cy=\"16\" r=\"2\" />\n  <path d=\"M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z\" />",
    "plane": "<path d=\"M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z\" />",
    "settings": "<path d=\"M9.671 4.136a2.34 2.34 0 0 1 4.659 0 2.34 2.34 0 0 0 3.319 1.915 2.34 2.34 0 0 1 2.33 4.033 2.34 2.34 0 0 0 0 3.831 2.34 2.34 0 0 1-2.33 4.033 2.34 2.34 0 0 0-3.319 1.915 2.34 2.34 0 0 1-4.659 0 2.34 2.34 0 0 0-3.32-1.915 2.34 2.34 0 0 1-2.33-4.033 2.34 2.34 0 0 0 0-3.831A2.34 2.34 0 0 1 6.35 6.051a2.34 2.34 0 0 0 3.319-1.915\" />\n  <circle cx=\"12\" cy=\"12\" r=\"3\" />",
    "shield-x": "<path d=\"M20 13c0 5-3.5 7.5-7.66 8.95a1 1 0 0 1-.67-.01C7.5 20.5 4 18 4 13V6a1 1 0 0 1 1-1c2 0 4.5-1.2 6.24-2.72a1.17 1.17 0 0 1 1.52 0C14.51 3.81 17 5 19 5a1 1 0 0 1 1 1z\" />\n  <path d=\"m14.5 9.5-5 5\" />\n  <path d=\"m9.5 9.5 5 5\" />",
    "shopping-cart": "<path d=\"m2.05 2.05 1.099-.028a1 1 0 0 1 1.008.815l2.69 14.347A1 1 0 0 0 7.83 18H18\" />\n  <path d=\"M4.563 5h16.435a1 1 0 0 1 .981 1.204l-1.026 6.226A2 2 0 0 1 18.962 14H6.25\" />\n  <circle cx=\"18\" cy=\"20\" r=\"2\" />\n  <circle cx=\"8\" cy=\"20\" r=\"2\" />",
    "sparkle": "<path d=\"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z\" />",
    "sparkles": "<path d=\"M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z\" />\n  <path d=\"M20 2v4\" />\n  <path d=\"M22 4h-4\" />\n  <circle cx=\"4\" cy=\"20\" r=\"2\" />",
    "square-chevron-right": "<rect width=\"18\" height=\"18\" x=\"3\" y=\"3\" rx=\"2\" />\n  <path d=\"m10 8 4 4-4 4\" />",
    "star": "<path d=\"M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z\" />",
    "terminal": "<path d=\"M12 19h8\" />\n  <path d=\"m4 17 6-6-6-6\" />",
    "webcam": "<circle cx=\"12\" cy=\"10\" r=\"8\" />\n  <circle cx=\"12\" cy=\"10\" r=\"3\" />\n  <path d=\"M7 22h10\" />\n  <path d=\"M12 22v-4\" />",
}

DEFAULT_ALIASES: dict[str, str] = {
    "pulse": "activity",
    "cart": "shopping-cart",
    "paw": "paw-print",
    "music": "eighth-notes",
    "chat": "message-circle",
}


class FolderIconError(Exception):
    """Domain error raised for invalid arguments, symbols, colors, or file operations."""


# ---------------------------------------------------------------------------
# DIRECTORY & STATE HELPERS
# ---------------------------------------------------------------------------

def ensure_dirs() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    SYMBOL_DIR.mkdir(parents=True, exist_ok=True)


def load_gui_state() -> dict:
    """Load persisted GUI preferences (recent colors, last directory, etc.)."""
    default_state = {
        "recent_colors": [
            "#ff6996",
            "#f4a6c0",
            "#3daee9",
            "#a855f7",
            "#ec4899",
            "#22c55e",
            "#f59e0b",
            "#ef4444",
        ],
        "last_folder": str(Path.home()),
    }
    if not GUI_STATE_FILE.exists():
        return default_state
    try:
        data = json.loads(GUI_STATE_FILE.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            default_state.update(data)
    except Exception:
        pass
    return default_state


def save_gui_state(state: dict) -> None:
    ensure_dirs()
    GUI_STATE_FILE.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# FOLDER REGISTRY (Tracks folder -> cached icon mappings)
# ---------------------------------------------------------------------------

def load_registry() -> dict[str, dict[str, str]]:
    """Load tracked folder -> icon mappings from registry.json."""
    if not REGISTRY_FILE.exists():
        return {}
    try:
        data = json.loads(REGISTRY_FILE.read_text(encoding="utf-8"))
        folders = data.get("folders") if isinstance(data, dict) else None
        if isinstance(folders, dict):
            cleaned: dict[str, dict[str, str]] = {}
            for folder_key, entry in folders.items():
                if isinstance(entry, dict) and isinstance(entry.get("icon"), str):
                    cleaned[str(folder_key)] = {
                        "icon": entry["icon"],
                        "updated_at": str(entry.get("updated_at", "")),
                    }
            return cleaned
    except Exception:
        pass
    return {}


def save_registry(folders: dict[str, dict[str, str]]) -> None:
    ensure_dirs()
    payload = {"folders": dict(sorted(folders.items()))}
    REGISTRY_FILE.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


def register_folder_icon(dir_path: Path, icon_abs: Path) -> None:
    """Record or update a folder's applied icon in registry.json."""
    folders = load_registry()
    folders[str(dir_path.resolve())] = {
        "icon": str(icon_abs.resolve()),
        "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    save_registry(folders)


def unregister_folder_icon(dir_path: Path) -> None:
    """Remove a folder entry from registry.json if present."""
    folders = load_registry()
    key = str(dir_path.resolve())
    if key in folders:
        del folders[key]
        save_registry(folders)


# ---------------------------------------------------------------------------
# SYMBOL & ALIAS RESOLUTION
# ---------------------------------------------------------------------------

def load_user_aliases() -> dict[str, str]:
    """Load user aliases from aliases.json; initialize with defaults if missing."""
    ensure_dirs()
    if not ALIAS_FILE.exists():
        save_user_aliases(DEFAULT_ALIASES)
        return dict(DEFAULT_ALIASES)
    try:
        data = json.loads(ALIAS_FILE.read_text(encoding="utf-8"))
        if isinstance(data, dict):
            return {str(k).lower(): str(v).lower() for k, v in data.items()}
    except Exception:
        pass
    return dict(DEFAULT_ALIASES)


def save_user_aliases(aliases: dict[str, str]) -> None:
    ensure_dirs()
    ALIAS_FILE.write_text(json.dumps(aliases, indent=2) + "\n", encoding="utf-8")


def validate_and_extract_svg(content: str) -> str:
    """
    Validate Lucide-compatible SVG markup and return inner vector elements.
    Raises FolderIconError if prerequisites are not met.
    """
    svg_open = re.search(r"<svg\b([^>]*)>", content, flags=re.DOTALL | re.IGNORECASE)
    if not svg_open or not re.search(r"</svg\s*>", content, flags=re.IGNORECASE):
        raise FolderIconError("File does not contain a valid <svg>...</svg> root element.")

    attrs = svg_open.group(1)
    viewbox_match = re.search(r'\bviewBox\s*=\s*["\']([^"\']+)["\']', attrs, flags=re.IGNORECASE)
    if viewbox_match:
        normalized_vb = " ".join(viewbox_match.group(1).split())
        if normalized_vb != "0 0 24 24":
            raise FolderIconError(f"Expected viewBox='0 0 24 24', got '{normalized_vb}'.")

    inner = re.sub(r"<\?xml.*?\?>", "", content, flags=re.DOTALL)
    inner = re.sub(r"<!--.*?-->", "", inner, flags=re.DOTALL)
    inner = re.sub(r"^.*?<svg\b[^>]*>", "", inner, flags=re.DOTALL | re.IGNORECASE)
    inner = re.sub(r"</svg\s*>.*$", "", inner, flags=re.DOTALL | re.IGNORECASE).strip()

    if not inner or "<" not in inner:
        raise FolderIconError("SVG contains no inner vector shapes.")
    return inner


def parse_custom_svg(svg_file: Path) -> str | None:
    try:
        content = svg_file.read_text(encoding="utf-8")
        return validate_and_extract_svg(content)
    except Exception:
        return None


def import_custom_svg(
    source_path: Path,
    custom_name: str | None = None,
    overwrite: bool = False,
) -> tuple[str, Path]:
    """
    Validate a Lucide SVG file and copy it into SYMBOL_DIR/<name>.svg.
    Raises FolderIconError on invalid SVG or naming collision when overwrite=False.
    """
    if not source_path.is_file():
        raise FolderIconError(f"Source SVG not found: {source_path}")

    raw_name = (custom_name if custom_name else source_path.stem).strip().lower()
    raw_name = re.sub(r"[^a-z0-9_-]+", "-", raw_name).strip("-")
    if not raw_name or raw_name == "none":
        raise FolderIconError(f"Invalid symbol name: '{raw_name or source_path.stem}'.")

    content = source_path.read_text(encoding="utf-8")
    validate_and_extract_svg(content)

    ensure_dirs()
    dest = SYMBOL_DIR / f"{raw_name}.svg"
    if dest.exists() and not overwrite:
        raise FolderIconError(f"Custom symbol '{raw_name}' already exists at {dest}.")

    dest.write_text(content, encoding="utf-8")
    return raw_name, dest


def save_custom_svg_content(
    svg_content: str,
    symbol_name: str,
    overwrite: bool = False,
) -> tuple[str, Path]:
    """
    Validate raw 24x24 Lucide SVG text and write it into SYMBOL_DIR/<name>.svg.
    """
    raw_name = re.sub(r"[^a-z0-9_-]+", "-", symbol_name.strip().lower()).strip("-")
    if not raw_name or raw_name == "none":
        raise FolderIconError(f"Invalid symbol name: '{symbol_name}'.")

    validate_and_extract_svg(svg_content)

    ensure_dirs()
    dest = SYMBOL_DIR / f"{raw_name}.svg"
    if dest.exists() and not overwrite:
        raise FolderIconError(f"Custom symbol '{raw_name}' already exists at {dest}.")

    dest.write_text(svg_content, encoding="utf-8")
    return raw_name, dest


def delete_custom_svg(name: str) -> None:
    target = SYMBOL_DIR / f"{name.lower()}.svg"
    if not target.exists():
        raise FolderIconError(f"Custom symbol '{name}' does not exist.")
    target.unlink()


def load_custom_symbols(
    return_invalid: bool = False,
) -> dict[str, str] | tuple[dict[str, str], list[str]]:
    """Scan SYMBOL_DIR for *.svg files matching 24x24 Lucide SVG prerequisites."""
    custom: dict[str, str] = {}
    invalid: list[str] = []

    if not SYMBOL_DIR.exists():
        return (custom, invalid) if return_invalid else custom

    for svg_file in sorted(SYMBOL_DIR.glob("*.svg")):
        name = svg_file.stem.lower()
        if name == "none":
            invalid.append(f"{svg_file.name} (reserved name 'none')")
            continue
        inner = parse_custom_svg(svg_file)
        if inner:
            custom[name] = inner
        else:
            invalid.append(f"{svg_file.name} (must be a valid 24x24 Lucide SVG)")

    return (custom, invalid) if return_invalid else custom


def resolve_alias_target(name: str, aliases: dict[str, str]) -> str:
    """Follow alias chains safely while guarding against cycles."""
    visited: set[str] = set()
    current = name
    while current in aliases and current not in visited:
        visited.add(current)
        current = aliases[current]
    return current


def canonical_symbol_name(
    symbol: str | None,
    aliases: dict[str, str] | None = None,
) -> str | None:
    """Resolve an optional symbol or alias to its canonical symbol name (or None)."""
    if not symbol:
        return None
    cleaned = symbol.strip().lower()
    if not cleaned or cleaned == "none":
        return None
    active_aliases = aliases if aliases is not None else load_user_aliases()
    return resolve_alias_target(cleaned, active_aliases)


def get_all_symbols() -> tuple[dict[str, str], dict[str, str]]:
    """
    Return (resolved_symbols_dict, aliases_dict).
    resolved_symbols_dict contains official + custom symbols + valid aliases.
    """
    base_symbols = dict(LUCIDE_SYMBOLS)
    custom_symbols = load_custom_symbols()
    assert isinstance(custom_symbols, dict)
    base_symbols.update(custom_symbols)

    aliases = load_user_aliases()
    all_symbols = dict(base_symbols)
    for alias_name in aliases:
        target = resolve_alias_target(alias_name, aliases)
        if target in base_symbols:
            all_symbols[alias_name] = base_symbols[target]

    return all_symbols, aliases


def check_alias_plan(target_name: str, alias_name: str) -> dict:
    """
    Validate a proposed alias mapping and return normalized names + conflict warnings.
    Raises FolderIconError on hard errors (reserved 'none', self-alias, empty names).
    """
    target = target_name.strip().lower()
    alias = alias_name.strip().lower()

    if not target or not alias:
        raise FolderIconError("Both target symbol and alias name must be non-empty.")
    if alias == "none" or target == "none":
        raise FolderIconError("'none' is reserved for folders without a symbol and cannot be aliased.")

    aliases = load_user_aliases()
    custom_symbols = load_custom_symbols()
    assert isinstance(custom_symbols, dict)
    known_targets = set(LUCIDE_SYMBOLS.keys()) | set(custom_symbols.keys())

    chained_from: str | None = None
    if target in aliases:
        chained_from = target
        target = resolve_alias_target(target, aliases)

    if alias == target:
        raise FolderIconError(f"Cannot alias '{alias}' to itself.")

    warnings: list[str] = []
    if chained_from:
        warnings.append(f"'{chained_from}' is an alias for '{target}'; pointing '{alias}' -> '{target}'.")
    if target not in known_targets:
        warnings.append(f"Target symbol '{target}' does not exist in built-in or custom symbols.")
    if alias in LUCIDE_SYMBOLS:
        warnings.append(f"'{alias}' conflicts with a built-in Lucide symbol and will override it.")
    if alias in custom_symbols:
        warnings.append(f"'{alias}' conflicts with a custom SVG in {SYMBOL_DIR} and will override it.")
    if alias in aliases and aliases[alias] != target:
        warnings.append(f"Alias '{alias}' already points to '{aliases[alias]}' and will be replaced.")

    return {
        "target": target,
        "alias": alias,
        "warnings": warnings,
        "already_identical": aliases.get(alias) == target,
    }


def set_alias(target_name: str, alias_name: str) -> None:
    aliases = load_user_aliases()
    aliases[alias_name.strip().lower()] = target_name.strip().lower()
    save_user_aliases(aliases)


def remove_alias(alias_name: str) -> None:
    aliases = load_user_aliases()
    key = alias_name.strip().lower()
    if key not in aliases:
        raise FolderIconError(f"Alias '{key}' does not exist.")
    del aliases[key]
    save_user_aliases(aliases)


# ---------------------------------------------------------------------------
# LIVE LUCIDE INDEX & SVG FETCHER
# ---------------------------------------------------------------------------

def fetch_lucide_icon_index(force_refresh: bool = False) -> list[str]:
    """
    Return sorted list of official Lucide icon names.
    Uses local cache unless force_refresh=True or cache does not exist.
    """
    if not force_refresh and LUCIDE_INDEX_FILE.exists():
        try:
            data = json.loads(LUCIDE_INDEX_FILE.read_text(encoding="utf-8"))
            icons = data.get("icons") if isinstance(data, dict) else None
            if isinstance(icons, list) and icons:
                return [str(name) for name in icons]
        except Exception:
            pass

    req = urllib.request.Request(
        LUCIDE_TREE_API_URL,
        headers={
            "User-Agent": "folder-icon/1.0",
            "Accept": "application/vnd.github+json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            payload = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        raise FolderIconError(f"GitHub API returned HTTP {exc.code} while fetching Lucide index.") from exc
    except Exception as exc:
        raise FolderIconError(f"Failed to fetch Lucide icon list: {exc}") from exc

    tree = payload.get("tree", []) if isinstance(payload, dict) else []
    names: list[str] = []
    for entry in tree:
        if not isinstance(entry, dict):
            continue
        path_str = str(entry.get("path", ""))
        if path_str.startswith("icons/") and path_str.endswith(".svg"):
            stem = path_str[len("icons/"):-len(".svg")].lower()
            if stem and "/" not in stem:
                names.append(stem)

    if not names:
        raise FolderIconError("Lucide icon list came back empty from GitHub.")

    sorted_names = sorted(set(names))
    ensure_dirs()
    LUCIDE_INDEX_FILE.write_text(
        json.dumps(
            {
                "updated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
                "icons": sorted_names,
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    return sorted_names


def fetch_lucide_icon_svg(icon_name: str) -> str:
    """Download and validate a 24x24 SVG from Lucide's official repository."""
    cleaned = icon_name.strip().lower()
    if not re.fullmatch(r"[a-z0-9-]+", cleaned):
        raise FolderIconError(f"Invalid Lucide icon name: '{icon_name}'.")

    url = LUCIDE_RAW_SVG_URL.format(name=cleaned)
    req = urllib.request.Request(url, headers={"User-Agent": "folder-icon/1.0"})
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            svg_text = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        raise FolderIconError(f"Could not download '{cleaned}.svg' (HTTP {exc.code}).") from exc
    except Exception as exc:
        raise FolderIconError(f"Network error downloading '{cleaned}.svg': {exc}") from exc

    validate_and_extract_svg(svg_text)
    return svg_text


# ---------------------------------------------------------------------------
# COLOR & SCALE UTILITIES
# ---------------------------------------------------------------------------

def parse_hex(color: str) -> tuple[int, int, int]:
    cleaned = color.strip().lstrip("#")
    if not re.fullmatch(r"[0-9a-fA-F]{6}", cleaned):
        raise FolderIconError(f"Expected 6-digit hex color (e.g. #3daee9), got: '{color}'")
    return int(cleaned[0:2], 16), int(cleaned[2:4], 16), int(cleaned[4:6], 16)


def normalize_hex(color: str) -> str:
    r, g, b = parse_hex(color)
    return to_hex(r, g, b)


def to_hex(r: int, g: int, b: int) -> str:
    return f"#{r:02x}{g:02x}{b:02x}"


def parse_scale(value: str | float) -> float:
    """
    Parse and validate symbol scale ratio (e.g. 0.45 or 45%).
    Raises FolderIconError if outside [MIN_SYMBOL_SCALE, MAX_SYMBOL_SCALE].
    """
    try:
        if isinstance(value, str):
            raw = value.strip()
            if raw.endswith("%"):
                ratio = float(raw[:-1].strip()) / 100.0
            else:
                num = float(raw)
                ratio = num / 100.0 if num > 1.0 else num
        else:
            ratio = float(value)
    except ValueError as exc:
        raise FolderIconError(f"Invalid scale value: '{value}'.") from exc

    if not (MIN_SYMBOL_SCALE <= ratio <= MAX_SYMBOL_SCALE):
        raise FolderIconError(
            f"Scale {ratio:.2f} out of range ({MIN_SYMBOL_SCALE:.2f} to {MAX_SYMBOL_SCALE:.2f})."
        )
    return round(ratio, 4)


def luminance(r: int, g: int, b: int) -> float:
    def chan(c: int) -> float:
        s = c / 255.0
        return s / 12.92 if s <= 0.04045 else ((s + 0.055) / 1.055) ** 2.4
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)


def contrast_color(r: int, g: int, b: int, mode: str = "auto") -> str:
    if mode == "black":
        return "#000000"
    if mode == "white":
        return "#ffffff"
    return "#ffffff" if luminance(r, g, b) < 0.179 else "#000000"


# ---------------------------------------------------------------------------
# SVG GENERATION
# ---------------------------------------------------------------------------

def build_symbol_preview_svg(
    symbol: str,
    all_symbols: dict[str, str],
    stroke_color: str = "#f4f4f5",
) -> str:
    """Render a standalone 24x24 Lucide symbol SVG for GUI thumbnails."""
    markup = all_symbols.get(symbol, "")
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <g fill="none"
     color="{stroke_color}"
     stroke="{stroke_color}"
     stroke-width="2"
     stroke-linecap="round"
     stroke-linejoin="round">
    {markup}
  </g>
</svg>
"""


def build_folder_svg(
    hex_color: str,
    symbol: str | None,
    symbol_color: str | None,
    all_symbols: dict[str, str],
    contrast_mode: str = SYMBOL_CONTRAST_MODE,
    scale_ratio: float = SYMBOL_SCALE,
) -> str:
    r, g, b = parse_hex(hex_color)
    folder_fill = to_hex(r, g, b)
    canon_symbol = canonical_symbol_name(symbol)

    folder_body_path = (
        "M 4 6 L 4 11 L 4 20 L 3 20 L 3 21 L 3 21 C 3 21 3 21 3 21 "
        "L 3 57 L 3 58 L 4 58 L 60 58 L 61 58 L 61 57 L 61 21 L 61 21 "
        "L 61 16 L 60 16 L 60 11 C 60 11 60 11 60 11 L 60 11 L 60 10 "
        "L 32 10 L 28 6 L 4 6 z"
    )
    tab_shadow_path = (
        "M 4 6 L 4 11 L 4 20 L 22 20 L 26 16 L 60 16 L 60 11 C 60 11 "
        "60 11 60 11 L 60 11 L 60 10 L 32 10 L 28 6 L 4 6 z"
    )
    highlight_path = (
        "M 28 6 L 31 11 L 33 11 L 60 11 L 60 10 L 33 10 L 32 10 L 28 6 z "
        "M 26 16 L 22 20 L 3 20 L 3 21 L 23 21 L 26 16 z"
    )
    edge_shadow_path = (
        "M 26 16 L 20 19 L 4 19 L 4 20 L 22 20 L 26 16 z "
        "M 3 57 L 3 58 L 4 58 L 60 58 L 61 58 L 61 57 L 60 57 L 4 57 L 3 57 z"
    )

    folder_layers = f"""  <!-- folder body - change fill= to recolor -->
  <path fill="{folder_fill}"
        d="{folder_body_path}"/>
  <!-- tab shadow (black @ 33% opacity - works with any hue) -->
  <path fill="#000000" fill-opacity="0.33"
        d="{tab_shadow_path}"/>
  <!-- white edge highlight -->
  <path fill="#ffffff" fill-opacity="0.2"
        d="{highlight_path}"/>
  <!-- dark bottom/tab edge -->
  <path fill="#000000" fill-opacity="0.2" fill-rule="evenodd"
        d="{edge_shadow_path}"/>"""

    symbol_layer = ""
    lookup_key = canon_symbol if (canon_symbol and canon_symbol in all_symbols) else symbol
    if lookup_key and lookup_key in all_symbols:
        display_name = canon_symbol or lookup_key
        sym_color = (
            normalize_hex(symbol_color)
            if symbol_color
            else contrast_color(r, g, b, contrast_mode)
        )

        body_cx = BODY_X + BODY_W / 2
        body_cy = BODY_Y + BODY_H / 2
        icon_size = min(BODY_W, BODY_H) * scale_ratio
        scale = icon_size / 24.0
        tx = body_cx - 12 * scale
        ty = body_cy - 12 * scale

        symbol_markup = all_symbols[lookup_key]
        symbol_layer = f"""
  <!-- symbol overlay: '{display_name}' -->
  <g fill="none"
     fill-opacity="{SYMBOL_OPACITY}"
     color="{sym_color}"
     stroke="{sym_color}"
     stroke-opacity="{SYMBOL_OPACITY}"
     stroke-width="2"
     stroke-linecap="round"
     stroke-linejoin="round"
     transform="translate({tx:.4f},{ty:.4f}) scale({scale:.6f})">
    {symbol_markup}
  </g>"""

    resolved_sym_color = (
        normalize_hex(symbol_color)
        if symbol_color
        else ("auto -> " + contrast_color(r, g, b, contrast_mode) if canon_symbol else "n/a")
    )
    scale_comment = f"{scale_ratio:.4f}" if canon_symbol else "n/a"
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
  <!--
    Generated by folder-icon.
    Folder color : {folder_fill}
    Symbol       : {canon_symbol or 'none'}
    Symbol color : {resolved_sym_color}
    Symbol scale : {scale_comment}
  -->
{folder_layers}{symbol_layer}
</svg>
"""


# ---------------------------------------------------------------------------
# CACHE NAMING (Omit-Default Hybrid + Canonical Symbol Resolution)
# ---------------------------------------------------------------------------

def icon_filename(
    symbol: str | None,
    hex_color: str,
    symbol_color: str | None = None,
    contrast_mode: str = SYMBOL_CONTRAST_MODE,
    scale_ratio: float = SYMBOL_SCALE,
    aliases: dict[str, str] | None = None,
) -> str:
    """
    Build cache SVG filename using Omit-Default Hybrid naming:
      - Resolves aliases to their canonical symbol name.
      - Uses '<symbol>-<hex>.svg' when style options match defaults.
      - Appends '-<6char-sha256>' only when custom scale or glyph color is used.
    """
    color = normalize_hex(hex_color).lstrip("#").lower()
    canon = canonical_symbol_name(symbol, aliases)
    base_name = canon if canon else "none"

    if canon is None:
        return f"none-{color}.svg"

    eff_color: str | None = None
    if symbol_color:
        eff_color = normalize_hex(symbol_color)
    elif contrast_mode == "white":
        eff_color = "#ffffff"
    elif contrast_mode == "black":
        eff_color = "#000000"

    norm_scale = round(float(scale_ratio), 4)
    default_scale = round(float(SYMBOL_SCALE), 4)

    if eff_color is None and norm_scale == default_scale:
        return f"{base_name}-{color}.svg"

    payload = f"color={eff_color or 'auto'}|scale={norm_scale:.4f}"
    digest = hashlib.sha256(payload.encode("utf-8")).hexdigest()[:6]
    return f"{base_name}-{color}-{digest}.svg"


def icon_path(
    symbol: str | None,
    hex_color: str,
    out_dir: Path | None = None,
    symbol_color: str | None = None,
    contrast_mode: str = SYMBOL_CONTRAST_MODE,
    scale_ratio: float = SYMBOL_SCALE,
    aliases: dict[str, str] | None = None,
) -> Path:
    base = out_dir if out_dir else OUTPUT_DIR
    return base / icon_filename(
        symbol=symbol,
        hex_color=hex_color,
        symbol_color=symbol_color,
        contrast_mode=contrast_mode,
        scale_ratio=scale_ratio,
        aliases=aliases,
    )


def write_icon(svg: str, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(svg, encoding="utf-8")


# ---------------------------------------------------------------------------
# .DIRECTORY & DOLPHIN THUMBNAIL OPERATIONS
# ---------------------------------------------------------------------------

def read_desktop_file(path: Path) -> list[str]:
    if not path.exists():
        return []
    return path.read_text(encoding="utf-8").splitlines(keepends=True)


def get_existing_directory_contents(dir_path: Path) -> str | None:
    """Return existing .directory text if present, otherwise None."""
    dot_dir = dir_path / ".directory"
    if not dot_dir.exists():
        return None
    return dot_dir.read_text(encoding="utf-8")


def _extract_desktop_icon_value(lines: list[str]) -> str | None:
    """Extract Icon= value inside [Desktop Entry] from .directory lines."""
    in_desktop = False
    for line in lines:
        stripped = line.strip()
        if stripped == "[Desktop Entry]":
            in_desktop = True
            continue
        if stripped.startswith("[") and stripped != "[Desktop Entry]":
            in_desktop = False
            continue
        if in_desktop and stripped.startswith("Icon="):
            value = stripped[len("Icon="):].strip()
            return value if value else None
    return None


def _parse_svg_header_metadata(svg_path: Path) -> dict[str, str]:
    """Read metadata comment fields from a generated folder-icon SVG."""
    meta: dict[str, str] = {}
    if not svg_path.is_file():
        return meta
    try:
        head = svg_path.read_text(encoding="utf-8")[:600]
    except Exception:
        return meta

    for key, label in (
        ("folder_color", "Folder color"),
        ("symbol", "Symbol"),
        ("symbol_color", "Symbol color"),
        ("symbol_scale", "Symbol scale"),
    ):
        match = re.search(rf"{re.escape(label)}\s*:\s*(.+)", head)
        if match:
            meta[key] = match.group(1).strip()
    return meta


def inspect_directory_icon(dir_path: Path) -> dict:
    """
    Inspect <dir_path>/.directory and return current icon metadata.
    Keys: exists, icon, is_managed, icon_exists, metadata, raw
    """
    dot_dir = dir_path / ".directory"
    if not dot_dir.exists():
        return {
            "exists": False,
            "icon": None,
            "is_managed": False,
            "icon_exists": False,
            "metadata": {},
            "raw": None,
        }

    try:
        raw = dot_dir.read_text(encoding="utf-8")
    except Exception:
        raw = ""

    lines = raw.splitlines(keepends=True)
    icon_val = _extract_desktop_icon_value(lines)

    is_managed = False
    icon_exists = False
    metadata: dict[str, str] = {}

    if icon_val:
        candidate = Path(icon_val).expanduser()
        if candidate.is_absolute():
            icon_exists = candidate.is_file()
            try:
                is_managed = candidate.resolve().parent == OUTPUT_DIR.resolve()
            except Exception:
                is_managed = False
            if icon_exists and candidate.suffix.lower() == ".svg":
                metadata = _parse_svg_header_metadata(candidate)

    return {
        "exists": True,
        "icon": icon_val,
        "is_managed": is_managed,
        "icon_exists": icon_exists,
        "metadata": metadata,
        "raw": raw,
    }


def refresh_dolphin_thumbnail(dir_path: Path) -> None:
    """
    Nudge filesystem timestamps and KDE's KDirNotify D-Bus signal so open
    Dolphin windows repaint folder icons without manual F5 refreshes.
    """
    try:
        os.utime(dir_path, None)
        dot_dir = dir_path / ".directory"
        if dot_dir.exists():
            os.utime(dot_dir, None)
    except Exception:
        pass

    try:
        dir_uri = dir_path.resolve().as_uri()
        dot_uri = (dir_path.resolve() / ".directory").as_uri()
        subprocess.run(
            [
                "dbus-send",
                "--session",
                "--type=signal",
                "/KDirNotify",
                "org.kde.KDirNotify.FilesChanged",
                f"array:string:{dir_uri},{dot_uri}",
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=1.5,
            check=False,
        )
    except Exception:
        pass


def apply_desktop_icon(dir_path: Path, icon_abs: Path) -> Path:
    """Write or update Icon= inside <dir_path>/.directory, update registry, and refresh Dolphin."""
    if not dir_path.is_dir():
        raise FolderIconError(f"Not a directory: {dir_path}")

    resolved_icon = icon_abs.resolve()
    dot_dir = dir_path / ".directory"
    lines = read_desktop_file(dot_dir)
    new_lines: list[str] = []
    in_desktop_section = False
    icon_written = False
    icon_line = f"Icon={resolved_icon}\n"

    if not lines:
        new_lines = ["[Desktop Entry]\n", icon_line]
    else:
        for line in lines:
            stripped = line.strip()
            if stripped == "[Desktop Entry]":
                in_desktop_section = True
                new_lines.append(line)
                continue
            if stripped.startswith("[") and stripped != "[Desktop Entry]":
                if in_desktop_section and not icon_written:
                    new_lines.append(icon_line)
                    icon_written = True
                in_desktop_section = False
            if in_desktop_section and stripped.startswith("Icon="):
                new_lines.append(icon_line)
                icon_written = True
                continue
            new_lines.append(line)

        if not icon_written:
            if in_desktop_section:
                new_lines.append(icon_line)
            else:
                new_lines.append("[Desktop Entry]\n")
                new_lines.append(icon_line)

    dot_dir.write_text("".join(new_lines), encoding="utf-8")

    if resolved_icon.parent == OUTPUT_DIR.resolve():
        register_folder_icon(dir_path, resolved_icon)

    refresh_dolphin_thumbnail(dir_path)
    return dot_dir


def reset_desktop_icon(dir_path: Path) -> dict:
    """
    Remove Icon= from <dir_path>/.directory.
    Deletes .directory completely if no other settings remain, updates registry,
    and refreshes Dolphin thumbnails.
    """
    if not dir_path.is_dir():
        raise FolderIconError(f"Not a directory: {dir_path}")

    dot_dir = dir_path / ".directory"
    unregister_folder_icon(dir_path)

    if not dot_dir.exists():
        return {"status": "noop", "dot_dir": dot_dir}

    lines = read_desktop_file(dot_dir)
    new_lines: list[str] = []
    in_desktop_section = False
    removed_any = False

    for line in lines:
        stripped = line.strip()
        if stripped == "[Desktop Entry]":
            in_desktop_section = True
            new_lines.append(line)
            continue
        if stripped.startswith("[") and stripped != "[Desktop Entry]":
            in_desktop_section = False
        if in_desktop_section and stripped.startswith("Icon="):
            removed_any = True
            continue
        new_lines.append(line)

    meaningful = [
        ln.strip()
        for ln in new_lines
        if ln.strip() and ln.strip() != "[Desktop Entry]"
    ]

    if not meaningful:
        dot_dir.unlink()
        refresh_dolphin_thumbnail(dir_path)
        return {"status": "deleted", "dot_dir": dot_dir}

    if removed_any:
        dot_dir.write_text("".join(new_lines), encoding="utf-8")
        refresh_dolphin_thumbnail(dir_path)
        return {"status": "updated", "dot_dir": dot_dir}

    return {"status": "noop", "dot_dir": dot_dir}


# ---------------------------------------------------------------------------
# CACHE GARBAGE COLLECTION & REGISTRY SYNC
# ---------------------------------------------------------------------------

def _managed_icon_target(dir_path: Path, cache_root: Path) -> Path | None:
    """
    Return the resolved SVG path inside cache_root if dir_path/.directory
    actively points to one of our managed SVGs; otherwise return None.
    """
    dot_dir = dir_path / ".directory"
    if not dot_dir.is_file():
        return None
    try:
        lines = dot_dir.read_text(encoding="utf-8").splitlines()
    except Exception:
        return None

    icon_val = _extract_desktop_icon_value(lines)
    if not icon_val:
        return None

    candidate = Path(icon_val).expanduser()
    if not candidate.is_absolute():
        return None
    try:
        resolved = candidate.resolve()
        if resolved.parent == cache_root:
            return resolved
    except Exception:
        return None
    return None


def scan_cache_usage(scan_root: Path | None = None) -> dict:
    """
    Synchronize registry.json against live .directory files (including changes made
    manually in Dolphin) and partition cached SVGs in OUTPUT_DIR into 'in_use' and 'orphaned'.
    """
    ensure_dirs()
    cache_root = OUTPUT_DIR.resolve()
    root = (scan_root if scan_root else Path.home()).expanduser().resolve()

    registry = load_registry()
    synced_registry: dict[str, dict[str, str]] = {}
    now_iso = datetime.now(timezone.utc).isoformat(timespec="seconds")

    # 1. Verify every tracked folder in registry.json directly (even if inside skipped dirs)
    for folder_str, entry in registry.items():
        folder_path = Path(folder_str)
        if not folder_path.is_dir():
            continue
        live_icon = _managed_icon_target(folder_path, cache_root)
        if live_icon is not None:
            synced_registry[folder_str] = {
                "icon": str(live_icon),
                "updated_at": entry.get("updated_at") or now_iso,
            }

    # 2. Walk scan_root (including ~/.local, skipping heavy build/VCS dirs)
    #    to discover any folders styled or reassigned directly in Dolphin
    if root.is_dir():
        for dirpath_str, dirnames, filenames in os.walk(root, topdown=True, followlinks=False):
            dirnames[:] = [d for d in dirnames if d not in SKIP_SCAN_DIRS]
            if ".directory" not in filenames:
                continue
            current_dir = Path(dirpath_str)
            resolved_dir_str = str(current_dir.resolve())
            if resolved_dir_str in synced_registry:
                continue
            live_icon = _managed_icon_target(current_dir, cache_root)
            if live_icon is not None:
                synced_registry[resolved_dir_str] = {
                    "icon": str(live_icon),
                    "updated_at": now_iso,
                }

    save_registry(synced_registry)

    # 3. Map each referenced SVG to the list of folders using it
    icon_users: dict[Path, list[str]] = {}
    for folder_str, entry in synced_registry.items():
        icon_p = Path(entry["icon"]).resolve()
        icon_users.setdefault(icon_p, []).append(folder_str)

    in_use: list[dict] = []
    orphaned: list[dict] = []

    for svg_file in sorted(OUTPUT_DIR.glob("*.svg")):
        resolved_svg = svg_file.resolve()
        try:
            size_bytes = svg_file.stat().st_size
        except Exception:
            size_bytes = 0

        users = sorted(icon_users.get(resolved_svg, []))
        record = {
            "path": svg_file,
            "name": svg_file.name,
            "size": size_bytes,
            "folders": users,
            "metadata": _parse_svg_header_metadata(svg_file),
        }
        if users:
            in_use.append(record)
        else:
            orphaned.append(record)

    return {
        "in_use": in_use,
        "orphaned": orphaned,
        "total_count": len(in_use) + len(orphaned),
        "orphaned_bytes": sum(item["size"] for item in orphaned),
    }


def delete_cached_icons(paths: list[Path]) -> list[Path]:
    """Delete specified cached SVG files inside OUTPUT_DIR safely."""
    cache_root = OUTPUT_DIR.resolve()
    deleted: list[Path] = []

    for item in paths:
        try:
            resolved = item.expanduser().resolve()
        except Exception:
            continue
        if resolved.parent != cache_root or resolved.suffix.lower() != ".svg":
            continue
        if resolved.is_file():
            resolved.unlink()
            deleted.append(resolved)

    return deleted