"""rbxl_audit.py - read-only audit of a binary .rbxl: bytes per class/property chunk, and a few
single-instance settings (Workspace streaming, Lighting technology) that the Studio MCP cannot read.
Usage: python tools/rbxl_audit.py ClimbAndCollect.rbxl  (needs lz4 + zstandard on sys.path)
"""
import struct
import sys
from collections import defaultdict

import lz4.block
import zstandard

ZSTD_MAGIC = b"\x28\xb5\x2f\xfd"


def chunks(buf):
    pos = 32
    while pos < len(buf):
        name = buf[pos:pos + 4]
        clen, ulen, _ = struct.unpack_from("<III", buf, pos + 4)
        pos += 16
        if clen == 0:
            data = buf[pos:pos + ulen]
            pos += ulen
        else:
            raw = buf[pos:pos + clen]
            pos += clen
            if raw[:4] == ZSTD_MAGIC:
                data = zstandard.ZstdDecompressor().decompress(raw, max_output_size=ulen)
            else:
                data = lz4.block.decompress(raw, uncompressed_size=ulen)
        yield name.rstrip(b"\x00").decode(), clen or ulen, data
        if name == b"END\x00":
            break


def rstr(d, p):
    n = struct.unpack_from("<I", d, p)[0]
    return d[p + 4:p + 4 + n].decode("utf-8", "replace"), p + 4 + n


def deinterleave(d, p, count, width=4):
    out = []
    for i in range(count):
        b = bytes(d[p + j * count + i] for j in range(width))
        out.append(int.from_bytes(b, "big"))
    return out


def unzig(v):
    return (v >> 1) ^ -(v & 1)


def unrot_float(v):
    v = ((v >> 1) | ((v & 1) << 31)) & 0xFFFFFFFF
    return struct.unpack(">f", v.to_bytes(4, "big"))[0]


def main(path):
    buf = open(path, "rb").read()
    classes = {}
    count = {}
    by_class = defaultdict(int)
    by_prop = defaultdict(int)
    single = {}
    for name, size, d in chunks(buf):
        if name == "INST":
            cid = struct.unpack_from("<i", d, 0)[0]
            cname, p = rstr(d, 4)
            n = struct.unpack_from("<I", d, p + 1)[0]
            classes[cid] = cname
            count[cname] = n
            by_class[cname] += size
        elif name == "PROP":
            cid = struct.unpack_from("<i", d, 0)[0]
            pname, p = rstr(d, 4)
            t = d[p]
            p += 1
            cname = classes.get(cid, "?")
            by_class[cname] += size
            by_prop[cname + "." + pname] += size
            if cname in ("Workspace", "Lighting") and count.get(cname) == 1:
                if t == 0x12:
                    single[cname + "." + pname] = deinterleave(d, p, 1)[0]
                elif t == 0x03:
                    single[cname + "." + pname] = unzig(deinterleave(d, p, 1)[0])
                elif t == 0x04:
                    single[cname + "." + pname] = round(unrot_float(deinterleave(d, p, 1)[0]), 3)
                elif t == 0x02:
                    single[cname + "." + pname] = bool(d[p])
        else:
            by_class["<" + name + ">"] += size
    total = len(buf)
    print(f"file {total/1e6:.1f} MB, classes {len(classes)}")
    print("-- top classes by stored bytes (compressed chunks)")
    for k, v in sorted(by_class.items(), key=lambda x: -x[1])[:14]:
        print(f"{v/1e6:8.2f} MB  {k}  (instances {count.get(k, '-')})")
    print("-- top properties")
    for k, v in sorted(by_prop.items(), key=lambda x: -x[1])[:12]:
        print(f"{v/1e6:8.2f} MB  {k}")
    print("-- single-instance settings")
    for k in sorted(single):
        if any(s in k for s in ("Stream", "Technology", "GlobalShadows", "Model", "Signal", "Integrity", "Fog", "Physics")):
            print(f"{k} = {single[k]}")


if __name__ == "__main__":
    main(sys.argv[1])
