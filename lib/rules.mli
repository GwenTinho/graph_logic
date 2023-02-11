(* system GS is AI_down, SS_down, p_down *)
(*  *)

(* plan:
   1. use tree from condense to get the "formula" form from a graph
   2. match patterns against it
*)
(*Each node is the graph that is being composed via*)

(*atomic identity down - ai_down*)
val atomic_identity_down: Tree.tree -> Tree.tree

(*super switch down - ss_down*)
val super_switch_down: Tree.tree -> Tree.tree

(*prime down - p_down*)
val prime_down: Tree.tree -> Tree.tree
