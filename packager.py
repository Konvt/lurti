import zipfile
from pathlib import Path

root = Path('.')
target = root / 'lurti.zip'
prefix = 'lurti/'
files = [
  'LICENSE',
  'README.md',
  'init.lua',
]
dirs = [
  'core',
  'collections',
  'static',
  'dynamic',
]

with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as z:
  for f in files:
    path = root / f
    if path.is_file():
      z.write(path, arcname=prefix + f)
  for d in dirs:
    base = root / d
    for file in base.rglob('*'):
      if file.is_file():
        z.write(file, arcname=prefix + str(file.relative_to(root)))
