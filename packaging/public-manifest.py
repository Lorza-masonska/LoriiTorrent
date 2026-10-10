#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Zapisz publiczny manifest silnika bez lokalnych ścieżek kompilatora."""
import argparse
import json
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('input', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
data = json.loads(args.input.read_text(encoding='utf-8-sig'))
keys = ('commit', 'version', 'variant', 'patch_mode', 'patches', 'linkage', 'submodules', 'source_diff_sha256')
public = {key: data[key] for key in keys if key in data}
args.output.write_text(json.dumps(public, indent=2) + '\n', encoding='utf-8')
