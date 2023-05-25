type path = int list

val atomic_identity_down_paths :
  LogicalTree.ltree -> path -> path -> path -> LogicalTree.ltree option

val prime_down_paths :
  LogicalTree.ltree -> path -> path -> path -> LogicalTree.ltree option

val switch_par :
  LogicalTree.ltree -> path -> path -> int -> path -> LogicalTree.ltree option
