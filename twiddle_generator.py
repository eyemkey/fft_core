#!/usr/bin/env python3
import math
import argparse
from pathlib import Path
import shutil
from py.fixed_point import quantize_q1, to_twos_bin
from py.memio import empty_outdir, write_stage_full


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--N", type=int, default=1024, help="FFT size (power of 2)")
    ap.add_argument("--width", type=int, default=16, help="Bit-width (16 => Q1.15)")
    ap.add_argument("--out", type=str, default="twiddles", help="Output directory")
    ap.add_argument("--num-stages", type=int, default=None, help="Stages to generate. Default = log2(N).")
    args = ap.parse_args()

    N = args.N
    if N <= 0 or (N & (N - 1)) != 0:
        raise ValueError("N must be a positive power of 2")

    outdir = Path(args.out)
    empty_outdir(outdir)

    default_stages = int(math.log2(N))
    num_stages = args.num_stages if args.num_stages is not None else default_stages

    for s in range(num_stages):
        write_stage_full(outdir, s, N, args.width)

if __name__ == "__main__":
    main()
