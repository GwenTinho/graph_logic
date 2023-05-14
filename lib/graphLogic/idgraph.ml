open Base
open Slap.D
open Slap.Size
open Poly

type id_graph = { nodes : int list; edges : (int * int) list }

let idg_of_tidg (tig: Quartic.Tree.id_graph) = { nodes = tig.nodes; edges = tig.edges }
let tidg_of_idg (tig: id_graph): Quartic.Tree.id_graph = { nodes = tig.nodes; edges = tig.edges }

let isEdge (a, b) idg =
  let { nodes = _; edges } = idg in
  (*use the or statement because we are working with undirected edges*)
  List.exists edges ~f:(fun (c, d) -> (a = c && b = d) || (a = d && b = c))

let length idg =
  let { nodes; edges = _ } = idg in
  List.length nodes

let length_edges idg =
  (*we are not working with a set so this is a lot less reliable ISSUE TODO*)
  let { nodes = _; edges } = idg in
  List.length edges

(*We are passing the dimension since we need to keep the scope outside this function*)
(*NOTE the Slap library creates matricies that are 1 indexed, this means that we want to avoid indexing at all costs*)
let adj_mat idg dim =
  let { nodes; edges = _ } = idg in
  let nodes = List.to_array nodes in
  let m =
    Mat.init dim dim (fun i j ->
        (*fill symetrically*)
        if isEdge (nodes.(i - 1), nodes.(j - 1)) idg then 1.0 else 0.0)
  in
  m

let mul a b = gemm ~transa:Slap.Common.normal a ~transb:Slap.Common.normal b
let mulT a b = gemm ~transa:Slap.Common.normal a ~transb:Slap.Common.trans b

let degrees idg dim =
  let m = adj_mat idg dim in
  let v = Mat.fold_top (fun acc vec -> Vec.add acc vec) (Vec.make0 dim) m in
  Vec.to_array v

let genInitialPerm idg1 idg2 dim1 dim2 =
  let degArr1 = degrees idg1 dim1 in
  let degArr2 = degrees idg2 dim2 in
  Mat.init dim1 dim2 (fun i j ->
      if degArr2.(j - 1) >= degArr1.(i - 1) then 1.0 else 0.0)

let permToAssoc idg1 idg2 perm =
  let nodes1 = Array.of_list idg1.nodes in
  let nodes2 = Array.of_list idg2.nodes in
  let perm_assoc =
    List.concat_mapi (Mat.to_list perm) ~f:(fun j l ->
        List.mapi l ~f:(fun i e -> (i, j, e)))
  in
  let filtered = List.filter perm_assoc ~f:(fun (_, _, e) -> e = 1.0) in
  let filtered = List.map filtered ~f:(fun (i, j, _) -> (i, j)) in
  let filtered =
    List.map filtered ~f:(fun (i, j) -> (nodes1.(i), nodes2.(j)))
  in
  Map.of_alist_exn (module Int) filtered

let setImmut a i v =
  let cpy = Array.copy a in
  let () = cpy.(i) <- v in
  cpy

let isIso perm matA matB = matA <= mulT perm (mul perm matB)

(*TODO implement prune*)
let refine perm = perm

(*PSEUDOCODE
  https://adriann.github.io/Ullman%20subgraph%20isomorphism.html
*)

(*Finds some isomorphism between matA and matB returns a Some iso on success*)
let ullmann_find perm matA matB =
  let lastRow = to_int (Mat.dim1 matA) in
  let lastCol = to_int (Mat.dim1 matB) in
  let rec aux freeVert perm currentRow currentColumn =
    let perm = refine perm in
    if currentRow = lastRow && isIso perm matA matB then Some perm
    else if currentColumn = lastCol then None
    else if freeVert.(currentColumn) then
      aux freeVert perm currentRow (currentColumn + 1)
    else
      let perm = Mat.copy perm in
      let () =
        Mat.replace_alli perm (fun i j a ->
            match (i, j, a) with
            | i, j, _ when i = currentRow + 1 && j = currentColumn + 1 -> 1.0
            | i, _, _ when i = currentRow + 1 -> 0.0
            | _, _, a -> a)
      in
      (*We are now in the for loop*)
      (*Mark c as used*)
      let freeVert = setImmut freeVert currentColumn true in
      aux freeVert perm (currentRow + 1) currentColumn
  in
  aux (Array.create ~len:lastCol false) perm 0 0

let find_sub_iso idg1 idg2 =
  let ( >>= ) = Option.( >>= ) in
  let return = Option.return in
  let l1 = length idg1 in
  let l2 = length idg2 in
  if (*We want empty graphs to be trivial subgraphs*)
     l1 > l2 then None
  else
    let module Dim1 = (val of_int_dyn l1 : SIZE) in
    let module Dim2 = (val of_int_dyn l2 : SIZE) in
    let m0 = genInitialPerm idg1 idg2 Dim1.value Dim2.value in
    let adj1 = adj_mat idg1 Dim1.value in
    let adj2 = adj_mat idg2 Dim2.value in
    ullmann_find m0 adj1 adj2 >>= fun perm ->
    return (permToAssoc idg1 idg2 perm)

let is_sub_iso idg1 idg2 =
  match find_sub_iso idg1 idg2 with Some _ -> true | None -> false

let is_iso idg1 idg2 =
  match (find_sub_iso idg1 idg2, find_sub_iso idg2 idg1) with
  | Some _, Some _ -> true
  | _ -> false

let find_iso idg1 idg2 =
  match (find_sub_iso idg1 idg2, find_sub_iso idg2 idg1) with
  | Some m1, Some _ -> Some m1
  | _ -> None

(*fills out all possible edges of the graph TODO, not very optimal but hey*)
let completetion_graph g =
  let ( >>= ) = List.( >>= ) in
  let { nodes; edges = _ } = g in
  let edges =
    nodes >>= fun x ->
    List.filter_map nodes ~f:(fun y -> if x = y then None else Some (x, y))
  in
  { nodes; edges }

let edge_diff idg1 idg2 =
  let { nodes = _; edges = e1 } = idg1 in
  let { nodes = _; edges = e2 } = idg2 in
  List.filter e1 ~f:(fun x ->
      not
        (List.mem e2 x ~equal:(fun (a, b) (c, d) ->
             (a = c && b = d) || (a = d && b = c))))

let id_graph_complement g =
  let compl = completetion_graph g in
  let edges = edge_diff compl g in
  { g with edges }

(*is_dual checks whether two graphs are in a dual relationship up to isomorphism*)
let is_dual g1 g2 = is_iso (id_graph_complement g2) g1

(*TODO write tests for this*)
