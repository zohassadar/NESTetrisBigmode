import re

codes_raw = """
29Trainer+1,14
FasterDas+1,0C
SlowFall,0A
TransitionTrainer,A5
"""

hexcodes = list("APZLGITYEOXUKSVN")

codes = {v: k for k, v in enumerate(hexcodes)}


def addr_data_to_code(addr, data, compare=False):
    base = addr - 0x8000
    n = [0] * (8 if compare is not False else 6)

    # Address
    n[3] |= (base >> 12) & 7
    n[5] |= (base >> 8) & 7
    n[4] |= (base >> 8) & 8
    n[2] |= (base >> 4) & 7
    n[1] |= (base >> 4) & 8
    n[4] |= base & 7
    n[3] |= base & 8

    # Data
    n[1] |= (data >> 4) & 7
    n[0] |= (data >> 4) & 8
    n[0] |= data & 7

    if compare is not False:
        n[2] |= 8
        n[7] |= data & 8

        # Compare
        n[7] |= (compare >> 4) & 7
        n[6] |= (compare >> 4) & 8
        n[6] |= compare & 7
        n[5] |= compare & 8
    else:
        n[5] |= data & 8

    return "".join(map(lambda x: hexcodes[x], n))


labels = open("tetris.lbl").readlines()

label_map = {}

for label_raw in labels:
    _, addr, label = label_raw.split()
    addr = addr[2:]
    if ".@GG_" in label:
        label = label.replace(".@GG_", "")
        addr = int(addr, 16)
        label_map.update({label: addr})

codes = re.findall(r"\s*(\w+)(?:([-+]\d+))?,([0-9a-f]{2})", codes_raw, re.I)

for label, offset, value in codes:
    address = label_map[label]
    offset = int(offset) if offset else 0
    address = address + offset
    value = int(value, 16)
    code = addr_data_to_code(address, value)
    print(f"{label:22}{code:>16}")
