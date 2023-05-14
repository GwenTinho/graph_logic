type bit_matrix = Base.Bool.t Base.Array.t Base.Array.t [@@deriving compare]

exception Incompatible_matrix_size of int * int

let create n m fn : bit_matrix =
  let mat = Array.make_matrix n m false in
  for i = 0 to n - 1 do
    for j = 0 to m - 1 do
      mat.(i).(j) <- fn i j
    done
  done;
  mat

let set (mat : bit_matrix) i j b = mat.(i).(j) <- b

let is_empty (mat : bit_matrix) =
  Array.length mat = 0 || Array.length mat.(0) = 0

let transpose (mat : bit_matrix) : bit_matrix =
  let n = Array.length mat in
  let m = Array.length mat.(0) in
  let mat' = Array.make_matrix m n false in
  for i = 0 to n - 1 do
    for j = 0 to m - 1 do
      mat'.(j).(i) <- mat.(i).(j)
    done
  done;
  mat'

let mul a b =
  if is_empty a || is_empty b then
    raise (Incompatible_matrix_size (Array.length a, Array.length b));
  let n = Array.length a in
  let m = Array.length a.(0) in
  if m <> Array.length b then
    raise (Incompatible_matrix_size (m, Array.length b));
  let p = Array.length b.(0) in
  let c = Array.make_matrix n p false in
  for i = 0 to n - 1 do
    for j = 0 to p - 1 do
      for k = 0 to m - 1 do
        c.(i).(j) <- c.(i).(j) <> (a.(i).(k) && b.(k).(j))
      done
    done
  done;
  c

let copy (mat : bit_matrix) : bit_matrix = Array.copy mat

let to_assoc_list (mat : bit_matrix) : (int * int) list =
  if is_empty mat then []
  else
    let n = Array.length mat in
    let m = Array.length mat.(0) in
    let l = ref [] in
    for i = 0 to n - 1 do
      for j = 0 to m - 1 do
        if mat.(i).(j) then l := (i, j) :: !l
      done
    done;
    !l

let update_rowi (mat : bit_matrix) (row : int) (fn : int -> bool -> bool) : unit
    =
  let m = Array.length mat.(0) in
  for j = 0 to m - 1 do
    mat.(row).(j) <- fn j mat.(row).(j)
  done
