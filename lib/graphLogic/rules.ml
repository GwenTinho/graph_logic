open LogicalTree
open Base

(*Work on tree nodes*)

(*Inference rules*)

type path = int list

let ( let* ) o f = match o with None -> None | Some x -> f x

let compare_paths_up_to_last (path1 : path) (path2 : path) =
  let path1 = List.rev path1 in
  let path2 = List.rev path2 in
  let* pathFromLast1 = List.tl path1 in
  let* pathFromLast2 = List.tl path2 in
  let different = List.exists2 pathFromLast1 pathFromLast2 ~f:( <> ) in
  let different =
    match different with Ok res -> res | Unequal_lengths -> true
  in
  if different then None
  else
    let* last1 = List.hd path1 in
    let* last2 = List.hd path2 in
    Some (last1, last2)

let atomic_identity_down (tree : ltree) pathPar pathAtom1 pathAtom2 =
  (*If the atom paths dont coincide up to the last node return none *)
  LogicalTree.map_at_path tree pathPar ~f:(function
    | Par nodes -> (
        let* idx1, idx2 = compare_paths_up_to_last pathAtom1 pathAtom2 in
        let* a = List.nth nodes idx1 in
        let* b = List.nth nodes idx2 in
        match (a, b) with
        | Atom a, Atom b ->
            if Equality.is_dual_atom a b then
              Some
                (Par (List.filteri nodes ~f:(fun i _ -> i <> idx1 && i <> idx2)))
            else None
        | _ -> None)
    | _ -> None)

let prime_down (tree : ltree) pathPar pathPrime1 pathPrime2 : ltree option =
  LogicalTree.map_at_path tree pathPar ~f:(function
    | Par nodes -> (
        let* idx1, idx2 = compare_paths_up_to_last pathPrime1 pathPrime2 in
        let* prime1 = List.nth nodes idx1 in
        let* prime2 = List.nth nodes idx2 in
        match (prime1, prime2) with
        | Prime (idg1, succ1), Prime (idg2, succ2) ->
            if Idgraph.is_iso idg1 idg2 then
              Some
                (Tensor
                   (Caml.List.map2 (fun t1 t2 -> Par [ t1; t2 ]) succ1 succ2))
            else None
        | _ -> None)
    | _ -> None)

let switch_par (tree : ltree) path_par path_outside path_prime
    path_prime_subnode =
  LogicalTree.map_at_path tree path_par ~f:(function
    | Par nodes ->
        let* idxOutside, idxPrime =
          compare_paths_up_to_last path_outside path_prime
        in
        let* outside = List.nth nodes idxOutside in
        let* prime = List.nth nodes idxPrime in
        let revSubnode = List.rev path_prime_subnode in
        let revPrime = List.rev path_prime in
        let* revSubnodetl = List.tl revSubnode in
        if not (equal_list ( = ) revPrime revSubnodetl) then None
        else
          let* index_in_prime = List.hd revSubnode in
          let new_prime =
            match prime with
            | Prime (idg, succ) ->
                let* inside = List.nth succ index_in_prime in
                let combined = Par [ outside; inside ] in
                let new_succ =
                  List.mapi succ ~f:(fun i v ->
                      if i <> index_in_prime then v else combined)
                in
                Some (Prime (idg, new_succ))
            | Tensor succ ->
                let* inside = List.nth succ index_in_prime in
                let combined = Par [ outside; inside ] in
                let new_succ =
                  List.mapi succ ~f:(fun i v ->
                      if i <> index_in_prime then v else combined)
                in
                Some (Tensor new_succ)
            | Par succ ->
                let* inside = List.nth succ index_in_prime in
                let combined = Par [ outside; inside ] in
                let new_succ =
                  List.mapi succ ~f:(fun i v ->
                      if i <> index_in_prime then v else combined)
                in
                Some (Par new_succ)
            | _ -> None
          in
          let new_nodes =
            List.filter_mapi nodes ~f:(fun i v ->
                match i with
                | i when i = idxOutside -> None
                | i when i = idxPrime -> new_prime
                | _ -> Some v)
          in
          Some (Par new_nodes)
    | _ -> None)
