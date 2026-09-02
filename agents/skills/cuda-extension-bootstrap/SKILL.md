---
name: cuda-extension-bootstrap
description: Use this skill to initialize or restructure a Python project that builds C++ or CUDA extension modules with uv, scikit-build-core, CMake, and pybind11. It creates separate training and inference extension boundaries, produces a compilation database, builds wheel and source distributions, and verifies the modules interactively.
compatibility: Requires uv, Python, a supported C++ compiler, CMake/Ninja supplied by the build environment, and NVCC when CUDA is enabled.
allowed-tools: bash glob rg view apply_patch ask_user
---

# CUDA Extension Bootstrap

Use this skill when the user asks to bootstrap a CMake-backed Python native
extension, replace a raw `setup.py`/`CUDAExtension` source list, or establish
separate training and inference modules before implementing real kernels.

## Resources

- Runbook:
  [`../../runbooks/scikit-build-cuda-extension.md`](../../runbooks/scikit-build-cuda-extension.md)
- Engineering profile:
  [`../../profiles/cuda-extension-developer.md`](../../profiles/cuda-extension-developer.md)
- Architecture notes:
  [`references/architecture.md`](references/architecture.md)

## Workflow

1. Inspect the target directory and determine whether it is empty.
2. Ask before changing names, replacing an existing build system, or choosing
   between one native module and separate training/inference modules.
3. Select the distribution name, import-package name, extension names, and
   Python requirement.
4. Follow the bootstrap runbook without deleting unrelated files.
5. Keep generated example cleanup separate from user-authored source cleanup.
6. Build through `uv` so the declared PEP 517 backend is exercised.
7. Verify both native imports and one result from each module.
8. Report the wheel, sdist, and compilation-database locations.

## Required behavior

- Use `uv init --lib --build-backend=scikit`; do not use the unrelated legacy
  `scikit-build` package.
- Do not run an initializer with overwrite semantics on a non-empty project.
- Do not claim CUDA kernel support merely because CMake enables the CUDA
  language.
- Do not claim PyTorch integration until Torch is declared, found, linked, and
  exercised with tensors.
- Treat `.clangd` as an environment-specific adjustment. Generate it only when
  compilation-database discovery or NVCC host-header parsing requires it.
- Keep native modules private and expose stable user-facing APIs from Python.

## Exit criteria

The basic bootstrap is complete when:

```python
from package_name import _inference, _training

assert _training.simple_add(2, 3) == 5
assert _inference.simple_add(4, 5) == 9
```

and the project can produce both a wheel and an sdist through `uv build`.
