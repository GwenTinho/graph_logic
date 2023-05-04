open Base

type rule_id =
  | AI_down
  | Prime_down
  | Switch_Par of Rules.selector * Rules.selector * Rules.selector

type proof = { initial : Tree.tree; expected : Tree.tree; steps : rule_id list }

let verify pf =
  let { initial; expected; steps } = pf in
  let rec aux proof_state = function
    | [] ->
        if Equality.equal_tree proof_state expected then None
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
        let new_proof_state =
          match Equality.simplify new_proof_state with
          | Some t -> t
          | None -> Tree.empty_tree ()
        in
        aux new_proof_state rest
  in
  aux initial steps
