#!/usr/bin/env python3
import argparse
import numpy as np
from pathlib import Path
from py.memio import read_input_mem_signed
import argparse


def run_fft_and_print(re_q: np.ndarray, im_q: np.ndarray, frac_bits: int=15):
    N = len(re_q)
    if len(im_q) != N: 
        raise ValueError("re_q and im_q must have same length")

    scale = 1.0 / (1 << frac_bits)
    x = (re_q.astype(np.float64) * scale) + 1j * (im_q.astype(np.float64) * scale)

    X = np.fft.fft(x, n=N)

    print("k\tRe\t\t\tIm\t\t\t|X|")
    for k in range(N): 
        print(f"{k}\t{X[k].real: .12e}\t{X[k].imag: .12e}\t{abs(X[k]): .12e}")

    return X


def fft_q15_golden(re_q, im_q, frac=15):
    N = len(re_q)
    x = (re_q / (1<<frac)) + 1j*(im_q / (1<<frac))
    X = np.fft.fft(x)

    # quantize back to q15
    Xre_q = np.rint(np.real(X) * (1<<frac)).astype(int)
    Xim_q = np.rint(np.imag(X) * (1<<frac)).astype(int)

    for k in range(N):
        print(f"X[{k}] = {Xre_q[k]} + j{Xim_q[k]}")

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


