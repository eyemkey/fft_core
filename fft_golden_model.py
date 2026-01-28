#!/usr/bin/env python3
import argparse
import numpy as np
from pathlib import Path

def read_input_mem_signed(path: str, N: int, WIDTH: int = 16): 
    p = Path(path)
    lines = []
    for raw in p.read_text().splitlines(): 
        s = raw.strip()
        if not s: 
            continue
        if s.startswith("//"):
            continue
        if "//" in s: 
            s = s.split("//", 1)[0].strip()

        if s: 
            lines.append(s)

    if len(lines) < 2 * N: 
        raise ValueError(f"{path}: expected >= {2*N} data lines, got {len(lines)}")

    def bin_to_signed_int(b: str) -> int: 
        if len(b) != WIDTH or any(c not in "01" for c in b): 
            raise ValueError(f"Bad word '{b}': expected {WIDTH}-bit binary string")
        
        u = int(b, 2)

        if u & (1 << (WIDTH-1)):
            u -= 1 << WIDTH

        return u

    re = np.array([bin_to_signed_int(lines[i]) for i in range(N)], dtype = np.int64)
    im = np.array([bin_to_signed_int(lines[N+i]) for i in range(N)], dtype = np.int64)

    print(re)
    print(im)

    return re, im


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
    re_q, im_q = read_input_mem_signed("tb/input.mem", N=16, WIDTH=16)
    run_fft_and_print(re_q, im_q, frac_bits = 15)

    # fft_q15_golden(re_q, im_q, frac=15)

if __name__ == "__main__":
    main()


