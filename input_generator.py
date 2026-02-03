#!/usr/bin/env python3
import math
import random
from pathlib import Path
from py.fixed_point import quantize_q1, to_twos_bin
from py.memio import write_input_mem

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
    N = 8
    WIDTH = 16
    out = "tb/input.mem"

    # Pick ONE:
    # re, im = zero(N) #PASSED
    re, im = impulse(N, amp=0.5, idx=0) #PASSED
    # re, im = dc(N, amp=0.25)
    # re, im = tone_real(N, k0=3, amp=0.5)
    # re, im = tone_complex(N, k0=3, amp=0.5)
    # re, im = random_complex(N, amp=0.5, seed=123)

    write_input_mem(out, re, im, WIDTH)
