#!/usr/bin/env python3
"""Strict, build-only compatibility fixes for the mirrored Forgejo source.

These replacements are intentionally narrow. If upstream edits the affected
functions in an incompatible way, fail instead of silently patching wrong code.
The original source remains untouched in the GitHub mirror commit.
"""
from pathlib import Path


def replace_once(path: str, before: str, after: str) -> None:
    source = Path(path)
    content = source.read_text(encoding="utf-8")
    if content.count(before) == 1:
        source.write_text(content.replace(before, after, 1), encoding="utf-8")
        print(f"Applied build compatibility fix: {path}")
    elif content.count(after) == 1:
        print(f"Already fixed upstream: {path}")
    else:
        raise SystemExit(
            f"Source changed unexpectedly: {path}. "
            "Review the upstream change before updating this compatibility fix."
        )


def main() -> None:
    # GCC -Werror=unused-but-set-variable at util.cpp:946; no other use in
    # UnswizzleImageRows. Preserve other GobSize declarations used elsewhere.
    replace_once(
        "src/video_core/texture_cache/util.cpp",
        """    const std::array level_sizes = CalculateLevelSizes(level_info, num_levels);
    const Extent2D gob = GobSize(bpp_log2, info.block.height, info.tile_width_spacing);
    const u32 layer_size = CalculateLevelBytes(level_sizes, num_levels);
    const u32 layer_stride = AlignLayerSize(layer_size, info.size, level_info.block, tile_size.height,
                                            info.tile_width_spacing);
    // Tiles across one GOB (64 bytes). Runs of blocks are unswizzled one GOB aligned: tile width""",
        """    const std::array level_sizes = CalculateLevelSizes(level_info, num_levels);
    const u32 layer_size = CalculateLevelBytes(level_sizes, num_levels);
    const u32 layer_stride = AlignLayerSize(layer_size, info.size, level_info.block, tile_size.height,
                                            info.tile_width_spacing);
    // Tiles across one GOB (64 bytes). Runs of blocks are unswizzled one GOB aligned: tile width""",
    )

    # MSVC C4457 at lower_to_maxwell.h:1304: a local tensor_mode shadows
    # the existing function parameter. Honor the passed mode unless explicitly
    # overridden by EDEN_NX2_TENSOR, matching the intended caller behavior.
    replace_once(
        "src/shader_recompiler/frontend/ampere/lower_to_maxwell.h",
        """            static const char* const mode_env = std::getenv("EDEN_NX2_TENSOR");
            const std::string_view tensor_mode{mode_env ? mode_env : ""};""",
        """            if (const char* mode_env = std::getenv("EDEN_NX2_TENSOR")) {
                tensor_mode = mode_env;
            }""",
    )


if __name__ == "__main__":
    main()
