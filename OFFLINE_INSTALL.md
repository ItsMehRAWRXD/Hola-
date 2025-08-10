# Offline install for `mypkg`

This archive contains:
- Source code under `src/`
- Prebuilt wheel under `dist/` (for the build environment's Python and platform)
- `get-pip.py` to bootstrap pip if needed

## Option A: Install prebuilt wheel (recommended)

```bash
# On target machine (no internet required)
python -m pip install --no-index --find-links dist/ mypkg
python -c "import mypkg; print(mypkg.add(2,3))"
```

## Option B: Build from source (requires local toolchain)

Requirements:
- Python 3.9+
- C/C++ compiler and Python headers (e.g., build-essential, python3-dev)

Steps:
```bash
python3 -m venv .venv --without-pip
. .venv/bin/activate
python get-pip.py
pip install --no-index --find-links dist/ wheel setuptools
python setup.py build_ext --inplace
pip install -e .
python -c "import mypkg; print(mypkg.add(2,3))"
```

Notes:
- The wheel is specific to the Python version and platform it was built on.
- If ABI does not match, use Option B.