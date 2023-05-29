type rule_id =
  | AI_down of { par : Rules.path; atom1 : Rules.path; atom2 : Rules.path }
  | Prime_down of { par : Rules.path; prime1 : Rules.path; prime2 : Rules.path }
  | Switch_Par of {
      par : Rules.path;
      outside : Rules.path;
      prime : Rules.path;
      inside : Rules.path;
    }
  | Simplify

type proof = { initial : LogicalTree.ltree; steps : rule_id list }

val apply_rule : LogicalTree.ltree -> rule_id -> LogicalTree.ltree option
val verify : proof -> LogicalTree.ltree option
