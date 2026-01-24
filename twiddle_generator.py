#!/usr/bin/env python3
import math
from pathlib import Path

def to_twos_complement(x: int, width: int) -> int:
    """Return x as unsigned two's complement with given width."""
    mask = (1 << width) - 1
    return x & mask

def quantize_q1(x: float, width: int) -> int:
    """
    Quantize x in [-1, 1] to signed WIDTH-bit two's complement.
    Uses scale = 2^(W-1)-1 to avoid +1 overflow.
    """
    scale = (1 << (width - 1)) - 1
    v = int(round(x * scale))
    v = max(-scale, min(scale, v))  # clamp
    return v

def write_stage_mem(N: int, WIDTH: int, stage: int, out_dir: Path):
    delay = N >> (stage + 1)
    if delay < 1:
        return

    out_path = out_dir / f"stage{stage}.mem"
    hex_digits = (2 * WIDTH + 3) // 4  # bits->hex chars (ceil)

    lines = []
    for m in range(delay):
        k = m * (1 << stage)  # exponent
        angle = -2.0 * math.pi * k / N
        re = math.cos(angle)
        im = math.sin(angle)

        qre = quantize_q1(re, WIDTH)
        qim = quantize_q1(im, WIDTH)

        word = (to_twos_complement(qre, WIDTH) << WIDTH) | to_twos_complement(qim, WIDTH)
        lines.append(f"{word:0{hex_digits}X}")

    out_path.write_text("\n".join(lines) + "\n")
    print(f"Wrote {out_path} ({delay} entries)")

def main():
    N = 1024
    WIDTH = 16
    max_stages = 15  # stage0..stage14
    out_dir = Path("twiddles")
    out_dir.mkdir(parents=True, exist_ok=True)

    # sanity
    if N & (N - 1):
        raise ValueError("N must be a power of 2")

    stages = int(math.log2(N))
    if stages > max_stages:
        raise ValueError(f"N={N} has {stages} stages > {max_stages}. Increase max_stages or limit N.")

    for s in range(stages):
        write_stage_mem(N, WIDTH, s, out_dir)

if __name__ == "__main__":
    main()
