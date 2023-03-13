(* system GS is AI_down, SS_down, p_down *)
(*  *)

(* plan:
   1. use tree from condense to get the "formula" form from a graph
   2. match patterns against it
*)
(*Each node is the graph that is being composed via*)

(*For now we will model empty trees as an none option*)

(*atomic identity down - ai_down*)
val atomic_identity_down : Tree.tree -> Tree.tree

(*switch_par - s&*)
val switch_par: Tree.tree -> Tree.tree

(*prime down - p_down*)
val prime_down: Tree.tree -> Tree.tree

val is_valid: Tree.tree -> bool
val find_proof: Tree.tree -> string list
