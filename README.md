# mypkg

Minimal offline C++ extension POC for Python using setuptools.build_meta.

## Build

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip wheel setuptools
python3 setup.py build_ext --inplace
```

## Use

```python
import mypkg
print(mypkg.add(2, 3))  # 5
```

## Test

```bash
python3 tests/test_native.py
```

No external dependencies are required beyond a C/C++ toolchain and Python headers (e.g., `build-essential` and `python3-dev` on Debian/Ubuntu).