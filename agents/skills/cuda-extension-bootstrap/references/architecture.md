# Architecture reference

## Layering

```text
Python public API and autograd wrappers
                  |
                  v
private pybind11 modules: _training and _inference
                  |
                  v
C++ launch and validation layer
                  |
                  v
CUDA kernels
```

The bootstrap runbook initially implements only the first native boundary with
integer functions. This proves packaging and module loading before Torch and
CUDA kernel complexity are introduced.

## Build responsibilities

| Layer | Responsibility |
|---|---|
| `uv` | Environment, dependency locking, command execution |
| `pyproject.toml` | Package metadata and PEP 517 backend |
| `scikit-build-core` | Bridge from Python packaging to CMake |
| CMake | Native targets, compiler options, dependencies, installation |
| pybind11 | Python module bindings |
| NVCC | CUDA compilation |
| NVIDIA driver | Runtime access to the GPU; not isolated by `uv` |

## Naming contract

For each native module, these names must agree:

```text
CMake target:          _training
PYBIND11_MODULE name:  _training
Installed module:      <package>/_training.<extension-suffix>
Python import:         <package>._training
```

The distribution name and import-package name are separate:

```text
Distribution: ch03-transformers
Import:       ch03_transformers
```

## Training and inference split

Keep two modules when they have different kernel sets, optimization flags, or
API contracts. Share validation, launch utilities, and common headers under
`csrc/common/` rather than duplicating them.

Consolidate into one module only when the split creates measurable build or
maintenance costs without preserving a useful boundary.

## Later PyTorch integration

Adding PyTorch requires more than adding it to runtime dependencies:

1. Declare Torch where the isolated build can import it.
2. Add Torch's CMake prefix to `CMAKE_PREFIX_PATH`.
3. Use `find_package(Torch REQUIRED)`.
4. Link the extension against the required Torch libraries.
5. Apply Torch's ABI compile settings.
6. Guard the active CUDA device.
7. Launch on PyTorch's current CUDA stream.
8. Validate device, dtype, shape, layout, and same-device constraints.
9. Exercise the extension with real CUDA tensors.

PyTorch may install isolated CUDA runtime libraries without installing NVCC.
If using an isolated toolkit compiler, select it explicitly through CMake and
keep it compatible with the Torch CUDA build.
