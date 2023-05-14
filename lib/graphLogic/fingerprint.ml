open Base

type rule_id =
  | AI_down
  | Prime_down
  | Switch_Par of Rules.selector * Rules.selector * Rules.selector

type proof = { initial : LogicalTree.ltree; steps : rule_id list }

let verify pf =
  let { initial; steps } = pf in
  let rec aux proof_state = function
    | [] ->
        if Equality.is_empty proof_state then None
        else Some proof_state
    | step :: rest ->
        let new_proof_state =
          match step with
          | AI_down -> Rules.atomic_identity_down proof_state
          | Prime_down -> Rules.prime_down proof_state
          | Switch_Par (select_host_graph, select_outer_graph, select_inner_node)
            ->
              Rules.switch_par_generic select_host_graph select_outer_graph
                select_inner_node proof_state
        in
          match LogicalTree.simplify new_proof_state with
          | Some new_proof_state -> aux new_proof_state rest
          | None -> None
  in
  aux initial steps

