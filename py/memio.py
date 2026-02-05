from py.fixed_point import to_twos_bin, quantize_q1, bin_to_signed_int
from pathlib import Path
import numpy as np
import shutil
import math

def empty_outdir(outdir: Path): 
    """
    Delete outdir and recreate it empty
    """
    if outdir.exists(): 
        shutil.rmtree(outdir)
    outdir.mkdir(parents=True, exist_ok=True)


def write_stage_full(outdir: Path, stage: int, N: int, width: int) -> None: 
    """
    Write full twiddle table for W_M^k = exp(-j*2*pi*k/M), k=0...M-1
    File format: first M lines = Re, next M lines = Im
    """

    path = outdir / f"stage{stage}.mem"
    re_lines = []
    im_lines = []

    M = N >> (stage + 1)

    for k in range(M): 
        angle = 2.0 * math.pi * k / (2*M)

        re = math.cos(angle)
        im = -math.sin(angle)

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


def write_input_mem(path: str, re_f: list[float], im_f: list[float], width: int): 
    """Write tb/input.mem: N lines Re, then N lines Im"""

    assert len(re_f) == len(im_f)
    N = len(re_f)

    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)

    with p.open("w") as f: 
        for n in range(N): 
            qre = quantize_q1(re_f[n], width)
            f.write(to_twos_bin(qre, width) + "\n")
        for n in range(N): 
            qim = quantize_q1(im_f[n], width)
            f.write(to_twos_bin(qim, width) + "\n")

    print(f"Wrote {2*N} lines to {p} (N={N}, WIDTH={width})")

def read_input_mem_signed(path: str, N: int, WIDTH: int = 16): 
    """
    Interprets input.mem as re and im integer inputs
    Returns the re and im integer input arrays
    """
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

    re = np.array([bin_to_signed_int(lines[i], WIDTH) for i in range(N)], dtype = np.int64)
    im = np.array([bin_to_signed_int(lines[N+i], WIDTH) for i in range(N)], dtype = np.int64)

    return re, im