# CUDA Extension Developer

## Purpose

Use this profile for projects that expose C++ or CUDA implementations through
Python extension modules.

## Engineering defaults

- Prefer a library-first Python package with private native modules.
- Use `pyproject.toml` for package metadata and `scikit-build-core` as the PEP
  517 bridge to CMake.
- Keep C++ and CUDA build logic in target-based CMake, not custom `setup.py`
  commands.
- Keep native sources under `csrc/` and Python APIs under `src/<package>/`.
- Use separate native targets when training and inference have distinct APIs or
  kernel sets.
- Keep the public API in Python; treat modules such as `_training` and
  `_inference` as implementation details.
- Generate `compile_commands.json` for clangd and other tooling.
- Match pybind11 module names, CMake target names, and installed import names
  exactly.
- Validate a clean build, wheel contents, native imports, and one observable
  operation from each extension.

## Safety and scope

- Inspect before editing and preserve unrelated files.
- Never clear a non-empty project directory to run a scaffold generator.
- Do not assume PyTorch wheels include NVCC.
- Distinguish isolated CUDA user-space libraries from the host NVIDIA driver.
- Prefer a CUDA compiler matching `torch.version.cuda` when integrating
  PyTorch.
- Do not introduce `.clangd` host include paths until the active compiler has
  been detected.

## Completion criteria

Work is complete only when the package builds through its declared backend,
the expected extension modules are installed inside the Python package, and
the documented import-level checks succeed.
