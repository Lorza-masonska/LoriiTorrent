#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Pakuj źródła projektu albo odpowiadające wydaniu źródła bibliotek."""
import argparse
import hashlib
import json
from pathlib import Path
import tarfile
import zipfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--dependencies', action='store_true')
args = parser.parse_args()
output = args.output.resolve()
if output.is_relative_to(root):
    parser.error('Zapisz archiwum poza katalogiem Source, np. w ../Release/Source.')
if output.exists() or output.with_suffix(output.suffix + '.sha256').exists():
    parser.error('Plik wydania już istnieje; wybierz nową nazwę.')
excluded = {'.git', '.agents', '.codex', '.ssh', '__pycache__', '.tools', '.vs', '.vscode', 'build', 'Legacy'}
files = {}
for path in sorted(root.rglob('*')):
    relative = path.relative_to(root)
    if set(relative.parts) & excluded or path.is_dir():
        continue
    if path.is_symlink() or not path.resolve().is_relative_to(root):
        parser.error('Nie można opublikować dowiązania: ' + relative.as_posix())
    if path.suffix.lower() in ('.pyc', '.pyo', '.log', '.fastresume', '.exe', '.dll', '.pdb'):
        continue
    archive_source = relative.parts[:2] == ('dependencies', 'archives')
    if args.dependencies:
        if not (relative.parts[0] in ('dependencies', 'LICENSES') or relative.as_posix() in ('NOTICE.md', 'LICENSE', 'COPYING', 'COPYING.GPLv2', 'COPYING.GPLv3')):
            continue
        if relative.parts[:2] == ('dependencies', 'libtorrent'):
            continue
        if archive_source and not path.name.endswith(('.tar.xz', '.tar.gz', '.tar.bz2', '.dsc', '.diff.gz', '.asc')):
            continue
    elif archive_source:
        continue
    with path.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    files[relative.as_posix()] = {'path': path, 'sha256': digest}
if not files:
    parser.error('Brak plików do publikacji.')
manifest = {'application': 'LoriiTorrent', 'version': '5.2.4-r3',
            'kind': 'dependency-sources' if args.dependencies else 'project-source',
            'files': {name: value['sha256'] for name, value in files.items()}}
output.parent.mkdir(parents=True, exist_ok=True)
prefix = 'LoriiTorrent-5.2.4-r3/'
if args.dependencies:
    import io
    prefix = 'LoriiTorrent-5.2.4-r3-Dependency-Sources/'
    with tarfile.open(output, 'w:gz', compresslevel=1) as bundle:
        for name, value in files.items():
            bundle.add(value['path'], arcname=prefix + name, recursive=False)
        data = (json.dumps(manifest, indent=2) + '\n').encode('utf-8')
        info = tarfile.TarInfo(prefix + 'SOURCE-MANIFEST.json')
        info.size = len(data)
        info.mode = 0o644
        bundle.addfile(info, io.BytesIO(data))
else:
    with zipfile.ZipFile(output, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for name, value in files.items():
            bundle.write(value['path'], prefix + name)
        bundle.writestr(prefix + 'SOURCE-MANIFEST.json', json.dumps(manifest, indent=2) + '\n')
with output.open('rb') as stream:
    digest = hashlib.file_digest(stream, 'sha256').hexdigest()
output.with_suffix(output.suffix + '.sha256').write_text(digest + '  ' + output.name + '\n', encoding='ascii')
print(json.dumps({'archive': output.name, 'files': len(files), 'sha256': digest, 'bytes': output.stat().st_size}))
