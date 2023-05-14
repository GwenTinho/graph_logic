type rule_id =
  | AI_down
  | Prime_down
  | Switch_Par of Rules.selector * Rules.selector * Rules.selector

type proof = { initial : LogicalTree.ltree; steps : rule_id list }

val verify : proof -> LogicalTree.ltree option
