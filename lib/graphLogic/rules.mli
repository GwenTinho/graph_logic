type path = int list

val atomic_identity_down :
  LogicalTree.ltree -> path -> path -> path -> LogicalTree.ltree option

val prime_down :
  LogicalTree.ltree -> path -> path -> path -> LogicalTree.ltree option

val switch_par :
  LogicalTree.ltree -> path -> path -> path -> path -> LogicalTree.ltree option
