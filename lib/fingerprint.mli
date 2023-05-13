type rule_id =
  | AI_down
  | Prime_down
  | Switch_Par of Rules.selector * Rules.selector * Rules.selector

type proof = { initial : Tree.tree; expected : Tree.tree; steps : rule_id list }

(*Takes a proof as input and returns None on success and Some result on failure, together with the output*)
val verify : proof -> Tree.tree option
