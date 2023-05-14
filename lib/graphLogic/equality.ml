open LogicalTree
open Base

(*smarter ordering is necessary*)

let order_trees_by_node_count tree_list =
  List.sort tree_list ~compare:(fun t1 t2 ->
      let l1 = count_nodes t1 in
      let l2 = count_nodes t2 in
      Int.compare l1 l2)

let isomorphism_pairing idg1 sub1 idg2 sub2 =
  let isol = Idgraph.find_sub_iso idg1 idg2 in
  let isor = Idgraph.find_sub_iso idg2 idg1 in
  match (isol, isor) with
  | Some _, None -> None
  | None, Some _ -> None
  | None, None -> None
  | Some isol, Some _ ->
      Some
        (List.mapi idg1.nodes ~f:(fun i n ->
             let corresponding_id = Map.find_exn isol n in
             let corresponding_index, _ =
               List.findi_exn idg2.nodes ~f:(fun _ x -> x = corresponding_id)
             in
             let corresponding_sub = List.nth_exn sub2 corresponding_index in
             let original_sub = List.nth_exn sub1 i in
             (original_sub, corresponding_sub)))

let is_dual_atom (a : Quartic.Graph.atom) (b : Quartic.Graph.atom) = equal_bool a.pol (not b.pol) && equal_string  a.label b.label

(*Rethink this*)
let rec is_dual t1 t2 =
  match (simplify t1, simplify t2) with
  (*simplify is necessary, since it removes a lot of edge cases where we have empty lists as subtrees*)
  | None, None -> true
  | Some _, None -> false
  | None, Some _ -> false
  | Some t1, Some t2 -> (
      match (t1, t2) with
      | Prime (idg1, sub1), Prime (idg2, sub2) -> (
          match isomorphism_pairing idg1 sub1 idg2 sub2 with
          | None -> false
          | Some l -> List.for_all l ~f:(fun (x, y) -> is_dual x y))
      | Atom a, Atom b -> is_dual_atom a b
      | Tensor sub1, Tensor sub2 ->
          if List.length sub1 <> List.length sub2 then false
          else
            let sub1 = order_trees_by_node_count sub1 in
            let sub2 = order_trees_by_node_count sub2 in
            Caml.List.for_all2 is_dual sub1 sub2
      | Par sub1, Par sub2 ->
          if List.length sub1 <> List.length sub2 then false
          else
            let sub1 = order_trees_by_node_count sub1 in
            let sub2 = order_trees_by_node_count sub2 in
            Caml.List.for_all2 is_dual sub1 sub2
      | _ -> false)

let equal_atom (a : Quartic.Graph.atom) (b : Quartic.Graph.atom) =
  equal_string a.label b.label && equal_bool a.pol b.pol

let is_empty t =
  match simplify t with None -> true | Some _ -> false
