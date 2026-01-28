#!/usr/bin/env python3
import math
import argparse
from pathlib import Path
import shutil

def empty_outdir(outdir: Path) -> None:
    """Delete outdir and recreate it empty."""
    if outdir.exists():
        shutil.rmtree(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

def quantize_q1(x: float, width: int) -> int:
    """
    Quantize x into signed Q1.(width-1).
    Returns signed int in [-2^(width-1), 2^(width-1)-1] with saturation.
    """
    frac_bits = width - 1
    scale = 1 << frac_bits

    q = int(round(x * scale))

    qmax = (1 << (width - 1)) - 1   # e.g. +32767 for 16-bit
    qmin = -(1 << (width - 1))      # e.g. -32768 for 16-bit
    if q > qmax: q = qmax
    if q < qmin: q = qmin
    return q

def to_twos_bin(q: int, width: int) -> str:
    """WIDTH-bit two's-complement binary string (no 0b, no minus)."""
    mask = (1 << width) - 1
    return format(q & mask, f"0{width}b")

def write_stage_full(outdir: Path, stage: int, M: int, width: int) -> None:
    """
    Write full twiddle table for W_M^k = exp(-j*2*pi*k/M), k=0..M-1.
    File format: first M lines = Re, next M lines = Im
    """
    path = outdir / f"stage{stage}.mem"

    re_lines = []
    im_lines = []

    for k in range(M):
        angle = 2.0 * math.pi * k / M
        re = math.cos(angle)
        im = -math.sin(angle)  # e^{-j...}

        qre = quantize_q1(re, width)
        qim = quantize_q1(im, width)

        re_lines.append(to_twos_bin(qre, width))
        im_lines.append(to_twos_bin(qim, width))

    with path.open("w") as f:
        for line in re_lines:
            f.write(line + "\n")
        for line in im_lines:
            f.write(line + "\n")

    print(f"stage{stage}: W_{M} -> wrote {2*M} lines to {path}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--N", type=int, default=1024, help="FFT size (power of 2)")
    ap.add_argument("--width", type=int, default=16, help="Bit-width (16 => Q1.15)")
    ap.add_argument("--out", type=str, default="twiddles", help="Output directory")
    ap.add_argument("--num-stages", type=int, default=None,
                    help="Stages to generate. Default = log2(N).")
    args = ap.parse_args()

    N = args.N
    if N <= 0 or (N & (N - 1)) != 0:
        raise ValueError("N must be a positive power of 2")

    outdir = Path(args.out)
    empty_outdir(outdir)

    default_stages = int(math.log2(N))
    num_stages = args.num_stages if args.num_stages is not None else default_stages

    for s in range(num_stages):
        M = N >> (s+1)  # stage s uses W_{N/2^s}
        if M < 2:
            break
        write_stage_full(outdir, s, M, args.width)

if __name__ == "__main__":
    main()
