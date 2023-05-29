open Base

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

let apply_rule tree rule =
  match rule with
  | AI_down { par; atom1; atom2 } ->
      Rules.atomic_identity_down tree par atom1 atom2
  | Prime_down { par; prime1; prime2 } ->
      Rules.prime_down tree par prime1 prime2
  | Switch_Par { par; outside; prime; inside } ->
      Rules.switch_par tree par outside prime inside
  | Simplify -> LogicalTree.simplify tree

let verify pf =
  let { initial; steps } = pf in
  let rec aux proof_state = function
    | [] -> if Equality.is_empty proof_state then None else Some proof_state
    | step :: rest ->
        let new_proof_state =
          match step with
          | AI_down { par; atom1; atom2 } -> (
              let res =
                Rules.atomic_identity_down proof_state par atom1 atom2
              in
              match res with None -> Some proof_state | Some x -> Some x)
          | Prime_down { par; prime1; prime2 } -> (
              let res = Rules.prime_down proof_state par prime1 prime2 in
              match res with None -> Some proof_state | Some x -> Some x)
          | Switch_Par { par; outside; prime; inside } -> (
              let res = Rules.switch_par proof_state par outside prime inside in
              match res with None -> Some proof_state | Some x -> Some x)
          | Simplify -> LogicalTree.simplify proof_state
        in
        if Poly.( = ) new_proof_state None then None
        else aux (Option.value_exn new_proof_state) rest
  in
  aux initial steps
