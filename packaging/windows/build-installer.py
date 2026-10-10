#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Zbuduj instalator NSIS z kompletnej paczki Windows, bez danych użytkownika."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--payload', type=Path, required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--makensis', default='makensis')
parser.add_argument('--application-id', default='LoriiTorrent', help='Osobny identyfikator tylko przy izolowanym testowaniu instalatora.')
args = parser.parse_args()
if not re.fullmatch(r'[A-Za-z][A-Za-z0-9.-]{0,63}', args.application_id):
    parser.error('Niedozwolony identyfikator aplikacji.')
payload = args.payload.resolve()
output = args.output.resolve()
root = Path(__file__).resolve().parents[2]
if output.exists():
    parser.error('Plik instalatora już istnieje; wybierz nową nazwę.')
if not (payload / 'bin/qbittorrent.exe').is_file() or not (payload / 'licenses').is_dir():
    parser.error('Niekompletna paczka Windows.')
for path in (payload, output, root):
    if any(character in str(path) for character in ('"', '\n', '\r', '$')):
        parser.error('Ścieżka zawiera znak niedozwolony w parametrze NSIS.')
files = []
directories = []
for path in sorted(payload.rglob('*')):
    relative = path.relative_to(payload)
    if path.is_symlink() or not path.resolve().is_relative_to(payload):
        parser.error('Paczka zawiera dowiązanie lub ścieżkę poza jej katalogiem.')
    if any(character in relative.as_posix() for character in ('"', '\n', '\r', '$')):
        parser.error('Niedozwolona nazwa pliku.')
    if any(part.casefold() in ('profile', 'logs', '.git', '.ssh') for part in relative.parts) or path.suffix.lower() in ('.fastresume', '.torrent', '.log'):
        parser.error('Paczka zawiera dane użytkownika lub metadane robocze.')
    if path.is_file():
        files.append(relative)
    elif path.is_dir():
        directories.append(relative)
output.parent.mkdir(parents=True, exist_ok=True)
build = root / 'build/windows-installer'
build.mkdir(parents=True, exist_ok=True)
uninstall = build / 'uninstall-files.nsh'
lines = ['; Lista wyłącznie plików dostarczonych z programem.']
lines += ['Delete "$INSTDIR\\' + str(path).replace('/', '\\') + '"' for path in files]
lines += ['RMDir "$INSTDIR\\' + str(path).replace('/', '\\') + '"' for path in sorted(directories, key=lambda p: len(p.parts), reverse=True)]
uninstall.write_text('\n'.join(lines) + '\n', encoding='utf-8-sig')
option = '/' if os.name == 'nt' else '-'
command = [args.makensis, option + 'INPUTCHARSET', 'UTF8', option + 'V3',
           option + 'DPAYLOAD_DIR=' + str(payload), option + 'DOUTPUT_FILE=' + str(output),
           option + 'DUNINSTALL_LIST=' + str(uninstall), option + 'DAPP_ID=' + args.application_id,
           str(Path(__file__).with_name('loriitorrent.nsi'))]
subprocess.run(command, check=True)
with output.open('rb') as stream:
    digest = hashlib.file_digest(stream, 'sha256').hexdigest()
output.with_suffix(output.suffix + '.sha256').write_text(digest + '  ' + output.name + '\n', encoding='ascii')
print(json.dumps({'installer': output.name, 'sha256': digest, 'files': len(files)}))
