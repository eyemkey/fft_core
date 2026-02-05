#!/usr/bin/env python3
import argparse
import numpy as np
from pathlib import Path
from py.memio import read_input_mem_signed
import argparse
from py.fft_util import run_fft_and_print, fft_q15_golden

def main(): 
    ap = argparse.ArgumentParser()
    ap.add_argument("--N", type=int, default=1024, help="FFT size (power of 2)")
    ap.add_argument("--WIDTH", type=int, default=16, help="Bit-width (16 => Q1.15)")

    args = ap.parse_args()

    re_q, im_q = read_input_mem_signed("tb/input.mem", N=args.N, WIDTH=args.WIDTH)
    run_fft_and_print(re_q, im_q, frac_bits = 15)

    # fft_q15_golden(re_q, im_q, frac=15)

if __name__ == "__main__":
    main()


