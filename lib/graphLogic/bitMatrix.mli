type bit_matrix = bool array array

val compare_bit_matrix : bit_matrix -> bit_matrix -> int

exception Incompatible_matrix_size of int * int

val create : int -> int -> (int -> int -> bool) -> bit_matrix
val set : bit_matrix -> int -> int -> bool -> unit
val is_empty : bit_matrix -> bool
val transpose : bit_matrix -> bit_matrix
val mul : bit_matrix -> bit_matrix -> bool array array
val copy : bit_matrix -> bit_matrix
val to_assoc_list : bit_matrix -> (int * int) list
val update_rowi : bit_matrix -> int -> (int -> bool -> bool) -> unit
