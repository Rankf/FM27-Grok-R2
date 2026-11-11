"""Reconstruct the already-tested full ZIP exactly from published R2 bytes."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import urllib.parse
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--base', type=Path)
parser.add_argument('--publish', action='store_true')
args = parser.parse_args()
recipe = json.loads((ROOT / 'release/full-r21-recipe.json').read_text(encoding='utf8'))
if args.base:
    source = args.base.read_bytes()
else:
    with urllib.request.urlopen(recipe['base_url'], timeout=120) as response:
        source = response.read()
assert hashlib.sha256(source).hexdigest() == recipe['base_sha256'], 'Base ZIP mismatch'
parts = []
for operation in recipe['operations']:
    if 'literal' in operation:
        parts.append(base64.b64decode(operation['literal'], validate=True))
    else:
        offset, length = operation['offset'], operation['length']
        assert offset >= 0 and length >= 0 and offset + length <= len(source)
        parts.append(source[offset:offset + length])
data = b''.join(parts)
assert len(data) == recipe['output_size']
assert hashlib.sha256(data).hexdigest() == recipe['output_sha256'], 'Full ZIP mismatch'
assert Path(recipe['output_name']).name == recipe['output_name']
out = ROOT / 'dist'
out.mkdir(exist_ok=True)
archive = out / recipe['output_name']
archive.write_bytes(data)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    prefix = 'FM27_Grok_26385295_R21_Test/'
    manifest = json.loads(z.read(prefix + 'manifest.json'))
    assert manifest['installerRevision'] == 'R2.1'
    for variant, files in manifest['variants'].items():
        for name, digest in files.items():
            assert hashlib.sha256(z.read(prefix + f'bundles/{variant}/{name}')).hexdigest() == digest
    for name, record in manifest['files'].items():
        assert hashlib.sha256(z.read(prefix + 'originals/' + name)).hexdigest() == record['base']
    for name, digest in manifest['skinHashes'].items():
        assert hashlib.sha256(z.read(prefix + name)).hexdigest() == digest
checksum = out / 'SHA256SUMS_R21_FULL.txt'
checksum.write_bytes((recipe['output_sha256'] + '  ' + archive.name + '\n').encode('ascii'))
print('Exact full ZIP verified:', archive.name, recipe['output_sha256'], flush=True)

if args.publish:
    repo = os.environ['GITHUB_REPOSITORY']
    assert repo == 'Rankf/FM27-Grok-R2'
    token = os.environ['GH_TOKEN']
    def request(url, payload=None, content_type='application/json'):
        headers = {'Authorization': 'Bearer ' + token, 'Accept': 'application/vnd.github+json',
                   'User-Agent': 'FM27-full-package-builder', 'Content-Type': content_type}
        with urllib.request.urlopen(urllib.request.Request(url, data=payload, headers=headers), timeout=180) as r:
            return json.load(r)
    url = f'https://api.github.com/repos/{repo}/releases/tags/r2.1-test'
    release = request(url)
    for file in [archive, checksum]:
        payload = file.read_bytes()
        digest = 'sha256:' + hashlib.sha256(payload).hexdigest()
        existing = next((a for a in release['assets'] if a['name'] == file.name), None)
        if existing:
            assert existing['state'] == 'uploaded' and existing['digest'] == digest
            print('Already verified:', file.name, flush=True)
            continue
        upload = release['upload_url'].split('{')[0] + '?' + urllib.parse.urlencode({'name': file.name})
        asset = request(upload, payload, 'application/zip' if file.suffix == '.zip' else 'text/plain')
        assert asset['state'] == 'uploaded' and asset['size'] == len(payload) and asset['digest'] == digest
        print('Published and verified:', asset['browser_download_url'], flush=True)
