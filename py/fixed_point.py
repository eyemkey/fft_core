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