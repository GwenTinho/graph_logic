open Base
open LogicalTree
open Fingerprint

let ( let* ) o f = match o with None -> None | Some x -> f x

let find_fitting_pair lst comp =
  let rec aux rem1 rem2 i j =
    match (rem1, rem2) with
    | [], _ -> None
    | _ :: t1, [] -> aux t1 lst (i + 1) (List.length lst - 1)
    | (h1 :: _ as l), h2 :: t2 ->
        if comp h1 h2 then Some (h1, i, h2, j) else aux l t2 i (j + 1)
  in
  aux lst lst 0 0

let find_dual_pair trees = find_fitting_pair trees Equality.is_dual

let find_atomic_dual_pair_index trees =
  let* pair =
    find_fitting_pair trees (fun t1 t2 ->
        match (t1, t2) with
        | Atom a, Atom b -> Equality.is_dual_atom a b
        | _ -> false)
  in
  match pair with
  | Atom a, i, Atom b, j ->
      if Equality.is_dual_atom a b then Some (i, j) else None
  | _ -> None

let find_some_and_apply_index tree f =
  let x = List.find_mapi (successors tree) ~f in
  x

let apply_ai_once pathPar path1 path2 tree =
  let rec aux pathPar path1 path2 current =
    let current = current in
    match current with
    | Par nodes -> (
        match find_atomic_dual_pair_index nodes with
        | None -> default_behavior current
        | Some pair_index -> (
            let i, j = pair_index in
            let rule =
              AI_down
                { par = pathPar; atom1 = path1 @ [ i ]; atom2 = path2 @ [ j ] }
            in
            match Fingerprint.apply_rule tree rule with
            | None -> None
            | Some _ -> Some rule))
    | Atom _ -> None
    | tree -> default_behavior tree
  and default_behavior tree =
    find_some_and_apply_index tree (fun i x ->
        aux (pathPar @ [ i ]) (path1 @ [ i ]) (path2 @ [ i ]) x)
  in
  aux pathPar path1 path2 tree

let apply_prime_once pathPar path1 path2 tree =
  let rec aux pathPar path1 path2 current =
    match current with
    | Par nodes -> (
        match find_dual_pair nodes with
        | None -> default_behavior current
        | Some pair_index -> (
            let _, i, _, j = pair_index in
            let rule =
              Prime_down
                {
                  par = pathPar;
                  prime1 = path1 @ [ i ];
                  prime2 = path2 @ [ j ];
                }
            in
            match Fingerprint.apply_rule tree rule with
            | None -> default_behavior current
            | Some _ -> Some rule))
    | Atom _ -> None
    | tree -> default_behavior tree
  and default_behavior tree =
    find_some_and_apply_index tree (fun i x ->
        aux (pathPar @ [ i ]) (path1 @ [ i ]) (path2 @ [ i ]) x)
  in

  aux pathPar path1 path2 tree

let auto_generic (tree : ltree) (apply_once : ltree -> rule_id option) : proof =
  (*idea: apply once until the tree doesnt change in amount of nodes while keeping track of the rules used*)
  let rec aux tree (rules : rule_id list) =
    let rule = apply_once tree in
    match rule with
    | None -> rules
    | Some rule -> (
        let new_tree_opt = apply_rule tree rule in
        match new_tree_opt with
        | None -> rules
        | Some new_tree -> aux new_tree (rules @ [ rule ]))
  in
  { initial = tree; steps = aux tree [] }

let auto_ai (tree : ltree) : proof =
  auto_generic tree (apply_ai_once [ 0 ] [ 0 ] [ 0 ])

let auto_prime_down (tree : ltree) : proof =
  auto_generic tree (apply_prime_once [ 0 ] [ 0 ] [ 0 ])

let pick_largest trees =
  fst
    (List.foldi trees ~init:(0, 0) ~f:(fun i (max_i, max) t ->
         let new_val = LogicalTree.count_children t in
         if max < new_val then (i, new_val) else (max_i, max)))

let pick_first _ = 0

let pick_first_atom_or_first trees =
  let opt =
    List.findi trees ~f:(fun _ t -> match t with Atom _ -> true | _ -> false)
  in
  match opt with None -> 0 | Some (i, _) -> i

let apply_switch_par_once path_par path_outside path_prime path_prime_subnode
    tree =
  let rec aux path_par path_outside path_prime path_prime_subnode current =
    match current with
    | Par nodes -> (
        let outside_index = pick_first_atom_or_first nodes in
        let prime_index = pick_largest nodes in
        let prime_subnode_index = pick_first nodes in
        let rule =
          Switch_Par
            {
              par = path_par;
              outside = path_outside @ [ outside_index ];
              prime = path_prime @ [ prime_index ];
              inside = path_prime_subnode @ [ prime_subnode_index ];
            }
        in
        match Fingerprint.apply_rule tree rule with
        | None -> default_behavior current
        | Some _ -> Some rule)
    | Atom _ -> None
    | tree -> default_behavior tree
  and default_behavior tree =
    find_some_and_apply_index tree (fun i x ->
        aux (path_par @ [ i ]) (path_outside @ [ i ]) (path_prime @ [ i ])
          (path_prime_subnode @ [ i ])
          x)
  in

  aux path_par path_outside path_prime path_prime_subnode tree

let auto_switch_par (tree : ltree) : proof =
  auto_generic tree (apply_switch_par_once [ 0 ] [ 0 ] [ 0 ] [ 0 ])
