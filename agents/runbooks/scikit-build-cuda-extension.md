# Bootstrap a scikit-build CUDA extension

## Outcome

Create a library-first Python package that:

- is managed by `uv`;
- uses `scikit-build-core` as its PEP 517 build backend;
- uses CMake for C++ and CUDA configuration;
- builds separate private pybind11 modules for training and inference;
- emits `build/compile_commands.json` for language-server tooling;
- builds both an sdist and a platform wheel; and
- can import and exercise both modules from IPython.

This runbook establishes the extension boundary only. Integrating PyTorch
tensors and adding `.cu` kernels are later steps.

## Inputs

Choose these values before editing:

| Input | Example |
|---|---|
| Distribution name | `ch03-transformers` |
| Import package | `ch03_transformers` |
| Training extension | `_training` |
| Inference extension | `_inference` |
| Python requirement | `>=3.12.11` |

Distribution names may contain hyphens. Python import-package names must use
valid identifiers, normally underscores.

## Prerequisites

- Work in an empty directory, or inspect and preserve every existing file.
- Never empty an existing directory as part of this runbook.
- `uv` is available.
- A supported C++ compiler is available.
- NVCC is available because the generated CMake project enables CUDA.

Check the toolchain when needed:

```bash
uv --version
c++ --version
nvcc --version
```

## 1. Initialize the Python library

Run from the target directory:

```bash
uv init --lib --build-backend=scikit .
```

The option is `--build-backend=scikit`, not `--backend=scikit`. `uv` generates
a `scikit-build-core` project; no global `scikit-build` installation is needed.

Expected initial files include:

```text
CMakeLists.txt
pyproject.toml
src/main.cpp
src/<import-package>/__init__.py
src/<import-package>/_core.pyi
src/<import-package>/py.typed
```

## 2. Replace the generated example

Create:

```text
csrc/
├── inference/
│   └── binding.cpp
└── training/
    └── binding.cpp
```

Remove the generated example files:

```text
src/main.cpp
src/<import-package>/_core.pyi
```

Remove the generated `_core` import and example function from
`src/<import-package>/__init__.py`. Keep the empty `__init__.py` and
`py.typed`.

## 3. Configure CMake

Replace `CMakeLists.txt`, substituting the chosen import-package name in the
install destination:

```cmake
cmake_minimum_required(VERSION 3.24...4.0)
project(${SKBUILD_PROJECT_NAME} LANGUAGES CXX CUDA)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(pybind11 CONFIG REQUIRED)

function(add_native_extension target)
  pybind11_add_module(${target} MODULE ${ARGN})
  target_compile_features(${target} PRIVATE cxx_std_17)
  set_target_properties(
    ${target}
    PROPERTIES
      CUDA_STANDARD 17
      CUDA_STANDARD_REQUIRED ON
  )
  install(TARGETS ${target} DESTINATION ch03_transformers)
endfunction()

add_native_extension(_training csrc/training/binding.cpp)
add_native_extension(_inference csrc/inference/binding.cpp)
```

The pybind11 module names in C++ must exactly match the CMake target names.

## 4. Stabilize the local build directory

Use a predictable development build directory in `pyproject.toml`:

```toml
[tool.scikit-build]
minimum-version = "build-system.requires"
build-dir = "build"
```

Ensure native sources participate in uv's cache key:

```toml
[tool.uv]
cache-keys = [
    { file = "pyproject.toml" },
    { file = "CMakeLists.txt" },
    { file = "src/**/*" },
    { file = "csrc/**/*.{h,hpp,cuh,c,cc,cpp,cu}" },
]
```

After a local wheel or editable build, CMake should emit:

```text
build/compile_commands.json
```

Whether clangd discovers that path automatically depends on the editor
integration. Add `.clangd` or `--compile-commands-dir` only when the active
environment requires it.

## 5. Add minimal bindings

`csrc/training/binding.cpp`:

```cpp
#include <pybind11/pybind11.h>

int training_simple_add(int a, int b) {
  return a + b;
}

PYBIND11_MODULE(_training, module) {
  module.def("simple_add", &training_simple_add);
}
```

`csrc/inference/binding.cpp`:

```cpp
#include <pybind11/pybind11.h>

int inference_simple_add(int a, int b) {
  return a + b;
}

PYBIND11_MODULE(_inference, module) {
  module.def("simple_add", &inference_simple_add);
}
```

## 6. Add the interactive development dependency

```bash
uv add --dev ipython
```

This records IPython in the development dependency group and synchronizes the
local project environment.

## 7. Build distributions

For a direct local wheel build:

```bash
uv build --wheel
```

For the complete distribution flow:

```bash
uv build
```

The complete flow creates:

```text
dist/<distribution>-<version>.tar.gz
dist/<distribution>-<version>-<python>-<abi>-<platform>.whl
```

The sdist contains buildable project source. It does not embed the compiler,
NVIDIA driver, or downloaded build dependencies. The wheel contains compiled
extensions and is platform- and Python-ABI-specific.

## 8. Verify from IPython

Start:

```bash
uv run ipython
```

Run:

```python
from ch03_transformers import _inference, _training

assert _training.simple_add(2, 3) == 5
assert _inference.simple_add(4, 5) == 9

print(_training.__file__)
print(_inference.__file__)
```

Both paths must identify compiled extension modules ending in a platform
extension suffix such as `.so` on Linux.

## Troubleshooting

### Module has no export function

Confirm that `PYBIND11_MODULE(_training, ...)` matches the `_training` CMake
target exactly, and likewise for `_inference`.

### A previous module is imported

Rebuild and reinstall the local package rather than trusting an earlier
environment:

```bash
uv build --wheel --clear
uv pip install --reinstall dist/*.whl
```

### Native edits do not trigger a rebuild

Confirm that `[tool.uv].cache-keys` includes `csrc/**/*`.

### CMake cannot find NVCC

Inspect the selected compiler:

```bash
command -v nvcc
nvcc --version
```

An isolated CUDA compiler may be installed separately, but CMake must still be
pointed at it through `CUDACXX` or `CMAKE_CUDA_COMPILER`.

### clangd cannot resolve CUDA host headers

First confirm that `build/compile_commands.json` exists and is being consumed.
If NVCC's implicit host C++ paths are still missing, generate a project
`.clangd` file that adds the host compiler's `-isystem` directories.
