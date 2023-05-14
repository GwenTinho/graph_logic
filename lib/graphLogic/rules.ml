open LogicalTree
open Base

(*Work on tree nodes*)

(*Inference rules*)

let find_fitting_pair lst comp =
  let rec aux rem1 rem2 =
    match (rem1, rem2) with
    | [], _ -> None
    | _ :: t1, [] -> aux t1 lst
    | (h1 :: _ as l), h2 :: t2 -> if comp h1 h2 then Some (h1, h2) else aux l t2
  in
  aux lst lst


let is_atom tree = match tree with Atom _ -> true | _ -> false
let find_dual_pair trees = find_fitting_pair trees Equality.is_dual

let find_atomic_dual_pair trees =
  let pair_opt = find_fitting_pair trees (fun t1 t2 ->
      match (t1, t2) with
      | Atom a, Atom b -> Equality.is_dual_atom a b
      | _ -> false) in
  match pair_opt with
  | None -> None
  | Some (Atom a,Atom b) -> if Equality.is_dual_atom a b then Some (a, b) else None
  | _ -> None

let propagate_once f tree =
  match tree with
  | Prime (idg, sub) -> Prime (idg, List.map ~f sub)
  | Atom a -> Atom a
  | Tensor sub -> Tensor (List.map ~f sub)
  | Par sub -> Par (List.map ~f sub)

(*atomic identity down - ai_down*)
let rec atomic_identity_down (tree : ltree) =
  match tree with
  | Par nodes ->
      let pair_option = find_atomic_dual_pair nodes in
      let new_tree =
        match pair_option with
        | None -> propagate_once atomic_identity_down tree
        | Some (a, b) ->
            Par
              (List.filter nodes ~f:(function Atom n -> not (Equality.equal_atom n a || Equality.equal_atom n b) | _ -> false)
                   )
      in
      if LogicalTree.count_nodes new_tree = LogicalTree.count_nodes tree then tree
      else atomic_identity_down new_tree
  | _ -> propagate_once atomic_identity_down tree

(*Switch par implementation*)
(*P(M1,...,Mn) & N -> P(M1,...,Mi & N,...,Mn) *)
(*select selects an index from the subnodes*)

(*NOTE there are TWO selection that need to happen, which node to move into the context and where to!*)

type selector = ltree list -> int

(*IMPORTANT THIS ALSO APPLIES TO SMALLER PRIME GRAPHS and fully connected ones!!!*)
let switch_par_generic (select_host_graph : selector)
    (select_outer_graph : selector) (select_inner_node : selector) tree =
  match tree with
  | Par sub ->
      let host_index = select_host_graph sub in
      let outer_index = select_outer_graph sub in
      if host_index = outer_index then tree
      else
        let host = List.nth_exn sub host_index in
        let outer = List.nth_exn sub outer_index in
        let updated_host =
          match host with
          | Atom _ -> tree
          | Par host_sub ->
              let inner_index = select_inner_node host_sub in
              let inner = List.nth_exn host_sub inner_index in
              let new_host_sub =
                List.filteri host_sub ~f:(fun i _ -> i <> inner_index)
              in
              let combined = Par [ inner; outer ] in
              let new_host_sub = combined :: new_host_sub in
              Par new_host_sub
          | Tensor host_sub ->
              let inner_index = select_inner_node host_sub in
              let inner = List.nth_exn host_sub inner_index in
              let new_host_sub =
                List.filteri host_sub ~f:(fun i _ -> i <> inner_index)
              in
              let combined = Par [ inner; outer ] in
              let new_host_sub = combined :: new_host_sub in
              Tensor new_host_sub
          | Prime (idg, host_sub) ->
              let inner_index = select_inner_node host_sub in
              let inner = List.nth_exn host_sub inner_index in
              let new_host_sub =
                List.filteri host_sub ~f:(fun i _ -> i <> inner_index)
              in
              let combined = Par [ inner; outer ] in
              let new_host_sub = combined :: new_host_sub in
              Prime (idg, new_host_sub)
        in
        let new_sub =
          List.filteri sub ~f:(fun i _ -> i <> host_index && i <> outer_index)
        in
        let new_sub = updated_host :: new_sub in
        Par new_sub
  | _ -> tree

let pick_largest trees =
  fst
    (List.foldi trees ~init:(0, 0) ~f:(fun i (max_i, max) t ->
         let new_val = LogicalTree.count_children t in
         if max < new_val then (i, new_val) else (max_i, max)))

let pick_first _ = 0

let pick_first_atom_or_first trees =
  let opt = List.findi trees ~f:(fun _ t -> is_atom t) in
  match opt with None -> 0 | Some (i, _) -> i

let switch_par =
  switch_par_generic pick_largest pick_first_atom_or_first
    pick_first_atom_or_first

(*prime down - p_down*)

let prime_down (tree : ltree) =
  match tree with
  | Par sub -> (
      let pair_option = find_dual_pair sub in
      match pair_option with
      | None -> tree
      | Some (t1, t2) -> (
          match (t1, t2) with
          | Prime (_, sub1), Prime (_, sub2) ->
              Tensor (Caml.List.map2 (fun t1 t2 -> Par [ t1; t2 ]) sub1 sub2)
          | _ -> Par sub))
  | _ -> tree

let find_proof (_ : ltree) = []
let is_valid (_ : ltree) = false
