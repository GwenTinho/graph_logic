open Logic.BitMatrix

let m = create 3 3 (fun _ _ -> false)
let m2 = create 3 3 (fun _ _ -> false)
let%test "matrix equality" = m = m2
let m3 = create 3 4 (fun _ _ -> false)
let%test "matrix inequality" = m <> m3

let%test "matrix incompatible" =
  try
    ignore (mul m3 m);
    false
  with Incompatible_matrix_size _ -> true

let%test "matrix compatible" =
  try
    ignore (mul m m3);
    true
  with Incompatible_matrix_size _ -> false

let a = create 3 3 (fun i j -> i = j || i = 2 - j)
let id = create 3 3 (fun i j -> i = j)
let b = create 3 3 (fun _ _ -> true)
let%test "matrix mul1" = mul a id = a
let c = create 3 3 (fun i _ -> i = 1)
let%test "matrix mul2" = mul a b = c
let%test "matrix transpose1" = transpose a = a
let%test "matrix transpose2" = transpose b = b
let%test "matrix transpose3" = transpose c <> c
let%test "matrix transpose3" = transpose id = id
