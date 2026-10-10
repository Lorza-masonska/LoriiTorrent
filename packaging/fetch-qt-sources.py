#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Pobierz oryginalne źródła Qt użyte przez wydanie Windows i sprawdź SHA256."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import urllib.request

root = Path(__file__).resolve().parents[1]
destination = root / 'dependencies/archives/windows'
destination.mkdir(parents=True, exist_ok=True)

def fetch(module):
    name = f'{module}-everywhere-src-6.10.3.tar.xz'
    url = f'https://download.qt.io/official_releases/qt/6.10/6.10.3/submodules/{name}'
    with urllib.request.urlopen(url + '.sha256', timeout=30) as response:
        expected = response.read().decode('ascii').split()[0].lower()
    if len(expected) != 64 or any(c not in '0123456789abcdef' for c in expected):
        raise ValueError('Nieprawidłowa suma kontrolna: ' + name)
    target = destination / name
    if not target.exists():
        partial = target.with_suffix(target.suffix + '.partial')
        with urllib.request.urlopen(url, timeout=60) as response, partial.open('xb') as output:
            while block := response.read(1024 * 1024):
                output.write(block)
        if hashlib.file_digest(partial.open('rb'), 'sha256').hexdigest() != expected:
            raise ValueError('Niezgodne SHA256: ' + name)
        partial.rename(target)
    with target.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != expected:
        raise ValueError('Niezgodne SHA256 istniejącego pliku: ' + name)
    return {'file': name, 'version': '6.10.3', 'url': url, 'sha256': actual, 'bytes': target.stat().st_size}

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
    results = list(pool.map(fetch, ['qtbase', 'qtsvg', 'qttools', 'qttranslations']))
(root / 'dependencies/qt-windows-sources.json').write_text(json.dumps(results, indent=2) + '\n')
print(json.dumps({'pobrano_i_sprawdzono': len(results), 'bajty': sum(item['bytes'] for item in results)}))
