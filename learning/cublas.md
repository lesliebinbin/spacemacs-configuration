# cuBLAS Mental Model

When learning cuBLAS, it is useful to separate four different concepts:

1. Raw memory layout
2. Matrix interpretation (column-major)
3. Transpose operation (`OP_N` / `OP_T`)
4. Mathematical multiplication

A lot of confusion comes from mixing these together.

---

## Core Pipeline

```text
consecutive memory
        ↓
interpret memory as stored column-major matrix A
        ↓
apply OP_N / OP_T to stored matrix A
        ↓
obtain mathematical operand op(A)
        ↓
perform op(A) @ op(B)
```

The key observation is:

**`OP_T` is applied after cuBLAS has already interpreted the memory as a column-major matrix.**

It does NOT change the memory layout.

It only changes the mathematical view of the matrix.

---

# Example 1

Suppose:

```cpp
float A[] = {1, 2, 3, 4, 5, 6};
```

Memory:

```text
[1][2][3][4][5][6]
```

Assume:

```cpp
m = 2;
k = 3;
lda = 2;
```

cuBLAS interprets this as a stored column-major matrix:

```text
A_stored =

| 1 3 5 |
| 2 4 6 |
```

because columns are filled first:

```text
Column 0: 1 2
Column 1: 3 4
Column 2: 5 6
```

---

## OP_N

```cpp
transa = CUBLAS_OP_N;
```

Then:

```text
op(A) = A_stored

       | 1 3 5 |
       | 2 4 6 |
```

Shape:

```text
2 x 3
```

---

## OP_T

```cpp
transa = CUBLAS_OP_T;
```

Then:

```text
op(A) = transpose(A_stored)

       | 1 2 |
       | 3 4 |
       | 5 6 |
```

Shape:

```text
3 x 2
```

Notice:

The memory never changed.

Only the mathematical interpretation changed.

---

# Important Distinction

Many C/C++ programmers look at

```cpp
float A[] = {1,2,3,4,5,6};
```

and mentally think:

```text
| 1 2 3 |
| 4 5 6 |
```

because they are accustomed to row-major storage.

cuBLAS does NOT think this way.

cuBLAS first interprets the memory as column-major:

```text
| 1 3 5 |
| 2 4 6 |
```

and only then applies `OP_N` or `OP_T`.

---

# Mental Formula

Always think:

```text
memory
   ↓
stored matrix
   ↓
op(...)
   ↓
GEMM
```

NOT:

```text
memory
   ↓
row-major matrix
   ↓
GEMM
```

---

# Understanding lda / ldb / ldc

A common misconception is:

```text
lda = number of columns
```

This is wrong.

`lda`, `ldb`, and `ldc` are strides.

More precisely:

```text
leading dimension
```

means:

```text
distance between starts of adjacent columns
```

for column-major matrices.

---

## Column-Major Case

Matrix:

```text
| a b c |
| d e f |
```

stored as:

```text
[a d b e c f]
```

Memory:

```text
a d | b e | c f
^     ^     ^
```

The start of each column is separated by:

```text
2 elements
```

therefore:

```cpp
lda = 2;
```

which happens to equal:

```text
number of rows
```

for a tightly packed column-major matrix.

---

## Row-Major Case

If the same matrix were stored row-major:

```text
| a b c |
| d e f |
```

memory would be:

```text
[a b c d e f]
```

Rows are contiguous.

The distance between starts of adjacent rows is:

```text
3 elements
```

Therefore the stride would be:

```text
3
```

which equals the number of columns.

---

# Why This Matters

For a dense matrix:

Column-major:

```text
stride = number_of_rows
```

Row-major:

```text
stride = number_of_columns
```

This is why many programmers say:

```text
lda = rows
```

for cuBLAS.

It is usually true.

But the more correct statement is:

```text
lda = stride between columns
```

and for a dense column-major matrix, that stride happens to equal the row count.

---

# GEMM Dimension Rule

cuBLAS computes:

```text
C = alpha * op(A) * op(B) + beta * C
```

Dimensions:

```text
op(A) : m x k
op(B) : k x n
C     : m x n
```

For example:

```cpp
m = 2;
n = 2;
k = 3;
```

means:

```text
op(A) : 2 x 3
op(B) : 3 x 2
C     : 2 x 2
```

regardless of whether `OP_N` or `OP_T` is used.

Changing `OP_N`/`OP_T` changes how cuBLAS obtains `op(A)` and `op(B)` from the stored matrices, but the final dimensions of `op(A)` and `op(B)` must still satisfy:

```text
(m x k) @ (k x n)
```

before the multiplication can be performed.
