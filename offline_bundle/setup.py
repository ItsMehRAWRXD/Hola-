from setuptools import setup, Extension, find_packages

extension_modules = [
    Extension(
        name="mypkg._native",
        sources=["src/mypkg/_native.cpp"],
        language="c++",
        extra_compile_args=["-O2"],
    )
]

setup(
    name="mypkg",
    version="0.1.0",
    description="Minimal C++ extension POC via setuptools.build_meta",
    python_requires=">=3.9",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    ext_modules=extension_modules,
)