#!/usr/bin/env python3
import math
import random
from pathlib import Path

def q1_quantize(x: float, width: int) -> int:
    """Quantize to signed Q1.(width-1), return signed int."""
    frac = width - 1
    scale = 1 << frac
    q = int(round(x * scale))
    qmax = (1 << (width - 1)) - 1
    qmin = -(1 << (width - 1))
    if q > qmax: q = qmax
    if q < qmin: q = qmin
    return q

def to_twos_bin(q: int, width: int) -> str:
    """Signed int -> width-bit two's complement binary string."""
    return format(q & ((1 << width) - 1), f"0{width}b")

def write_input_mem(path: str, re_f: list[float], im_f: list[float], width: int):
    """Write tb/input.mem: N lines Re, then N lines Im."""
    assert len(re_f) == len(im_f)
    N = len(re_f)

    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)

    with p.open("w") as f:
        for n in range(N):
            f.write(to_twos_bin(q1_quantize(re_f[n], width), width) + "\n")
        for n in range(N):
            f.write(to_twos_bin(q1_quantize(im_f[n], width), width) + "\n")

    print(f"Wrote {2*N} lines to {p} (N={N}, WIDTH={width})")

# ---- Stimulus generators ----

def zero(N: int): 
    re = [0.0] * N
    im = [0.0] * N
    return re, im

def impulse(N: int, amp: float = 0.5, idx: int = 0):
    re = [0.0] * N
    im = [0.0] * N
    re[idx] = amp
    return re, im

def dc(N: int, amp: float = 0.25):
    re = [amp] * N
    im = [0.0] * N
    return re, im

def tone_real(N: int, k0: int, amp: float = 0.5):
    """x[n] = amp*cos(2*pi*k0*n/N) (real only)."""
    re = [amp * math.cos(2 * math.pi * k0 * n / N) for n in range(N)]
    im = [0.0] * N
    return re, im

def tone_complex(N: int, k0: int, amp: float = 0.5):
    """x[n] = amp*exp(-j*2*pi*k0*n/N)."""
    re = [amp * math.cos(2 * math.pi * k0 * n / N) for n in range(N)]
    im = [-amp * math.sin(2 * math.pi * k0 * n / N) for n in range(N)]
    return re, im

def random_complex(N: int, amp: float = 0.5, seed: int = 1):
    random.seed(seed)
    re = [(2*random.random()-1) * amp for _ in range(N)]
    im = [(2*random.random()-1) * amp for _ in range(N)]
    return re, im

if __name__ == "__main__":
    N = 16
    WIDTH = 16
    out = "tb/input.mem"

    # Pick ONE:
    re, im = zero(N)
    # re, im = impulse(N, amp=0.5, idx=0)
    # re, im = dc(N, amp=0.25)
    # re, im = tone_real(N, k0=3, amp=0.5)
    # re, im = tone_complex(N, k0=3, amp=0.5)
    # re, im = random_complex(N, amp=0.5, seed=123)

    write_input_mem(out, re, im, WIDTH)
