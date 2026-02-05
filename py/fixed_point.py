import math
from typing import List, Tuple

def quantize_q1(x: float, width: int) -> int: 
    """
    Quantize x into signed Q1.(width-1).
    Returns signed int in [-2^(width-1), 2^(width-1)-1] with saturation
    """
    
    frac_bits = width - 1
    scale = 1 << frac_bits

    q = int(round(x * scale))

    qmax = (1 << (width-1)) - 1 #01111...
    qmin = -(1 << (width-1))    #111111...

    if q > qmax: q = qmax   # +32767 for 16bit
    if q < qmin: q = qmin   # -32768 for 16bit
    return q


def to_twos_bin(q: int, width: int) -> str:
    """WIDTH-bit two-s complement binary string"""

    mask = (1 << width) - 1     #mask everything except lowest 16 bits
    return format(q & mask, f"0{width}b")


def bin_to_signed_int(b: str, width: int) -> int: 
    if len(b) != width or any(c not in "01" for c in b): 
        raise ValueError(f"Bad word '{b}': expected {width}-bit binary string")

    u = int(b, 2)

    if u & (1 << (width-1)):    #if first bit is 1
        u -= 1 << width         #subtract 2*max to get 2's complement
    
    return u


def l1_norm_real(x: List[float]) -> float: 
    """
    Return sum_n |x[n]|
    """
    return sum(abs(v) for v in x)

def l1_norm_complex(re: List[float], im: List[float]) -> float:
    """
    Return sum_n sqrt(|z[n]|) where z[n] = re[n] + j*im[n]
    """
    if len(re) != len(im): 
        raise ValueError("re and im must have same length")
    return sum(math.hypot(a, b) for a, b in zip(re, im))

def scale_frame_l1_real(x: List[float], headroom: float = 0.95) -> Tuple[List[float], float]:
    """
    Scale real frame so sum |x[n]| <= headroom
    Guarantees max_k |FFT(x)[k]| <= headroom 
    Returns (x_scaled, gain).
    """
    if not(0.0 < headroom < 1.0):
        raise ValueError("headroom must be in (0,1)")
    s = l1_norm_real(x)
    if s == 0: 
        return x[:], 1.0
    
    g = headroom / s
    return [v * g for v in x], g

def scale_frame_l1_complex(re: List[float], im: List[float], headroom: float = 0.95) -> Tuple[List[float], List[float], float]:
    """
    Scale complex frame so sum |x[n]| <= headroom
    Guarantee: max_k |FFT(x)[k]| <= headroom
    Returns (re_scaled, im_scaled, gain)
    """    

    if not (0.0 < headroom < 1.0):
        raise ValueError("headroom must be in (0,1)")

    s = l1_norm_complex(re, im)
    if s == 0:
        return re[:], im[:], 1.0

    g = headroom / s
    return [a * g for a in re], [b * g for b in im], g


def quantize_frame_q1(re: List[float], im: List[float], width: int) -> Tuple[List[int], List[int]]:
    """
    Quantize complex frame using quantize_q1()
    """
    if len(re) != len(im):
        raise ValueError("re and im must have same length")
    
    re_q = [quantize_q1(a, width) for a in re]
    im_q = [quantize_q1(b, width) for b in im]
    return re_q, im_q

