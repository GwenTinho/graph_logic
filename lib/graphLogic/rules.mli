val atomic_identity_down : LogicalTree.ltree -> LogicalTree.ltree

type selector = LogicalTree.ltree list -> int

val switch_par_generic :
  selector -> selector -> selector -> LogicalTree.ltree -> LogicalTree.ltree

val pick_largest : LogicalTree.ltree list -> int
val pick_first : 'a -> int
val pick_first_atom_or_first : LogicalTree.ltree list -> int
val switch_par : LogicalTree.ltree -> LogicalTree.ltree
val prime_down : LogicalTree.ltree -> LogicalTree.ltree
val find_proof : LogicalTree.ltree -> 'a list
val is_valid : LogicalTree.ltree -> bool
