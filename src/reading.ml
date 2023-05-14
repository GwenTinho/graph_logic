open Quartic
open Base
open Js_of_ocaml

let rec read_prime root id =
  let children = root##children |> Js.to_array |> Array.to_list in
  let nodes = List.map children ~f:(fun c -> 
    let node_id_s = c##id |> Js.to_string in
    Util.remove_rep node_id_s)
  in
  let edge_objs = (Js.Unsafe.coerce root##children)##connectedEdges
    (Js.string ".compoundIn") |> Js.to_array |> Array.to_list
  in
  let edges = List.map edge_objs ~f:(fun edge ->
    let source = edge##source##id |> Js.to_string |> Util.remove_rep in
    let target = edge##target##id |> Js.to_string |> Util.remove_rep in
    (source, target))
  in
  let successors_objs = ((Js.Unsafe.coerce root##children)##outgoers (Js.string "node"))##orphans
    |> Js.to_array |> Array.to_list
  in
  let successors = List.map successors_objs ~f:read_tree in
  let id_graph = {Tree.nodes = nodes; edges = edges} in
  let connective = Tree.Prime (id_graph, successors) in
  {Tree.connective = connective; id = id}

and read_before root id =
  let child_root = root##children (Js.string ".before-root") in
  let children_rep =
    let rec parse_children root acc =
      let next = (root##connectedEdges (Js.string ".before"))##targets##not (root) in
      if next##empty then acc else parse_children next (next :: acc)
    in
    parse_children child_root [child_root]
  in
  let successors = List.map children_rep ~f:(fun cr ->
    let outEdge = cr##connectedEdges (Js.string ".compoundOut") in
    let c = outEdge##target in
    read_tree c)
  in
  {Tree.connective = Tree.Before successors; id = id}

and read_atom node id label =
  let pol = node##data (Js.string "polarisation") |> Js.to_bool in
  let connective = Tree.Atom {Graph.label = label; pol = pol} in
  {Tree.connective = connective; id = id}

and read_tree root =
  let label_string = root##data (Js.string "label") |> Js.to_string in
  let id = root##data (Js.string "id") |> Js.parseInt in
  let classes_js = root##classes |> Js.to_array in
  let classes = Array.map classes_js ~f:(Js.to_string) in
  if Array.mem classes "prime" ~equal:String.equal then read_prime root id else
  if Array.mem classes "before" ~equal:String.equal then read_before (Js.Unsafe.coerce root) id else
  let all_edges = (Js.Unsafe.coerce root)##connectedEdges in
  let edges_to = all_edges##not (all_edges##edges (Js.string ".before")) in
  let successors = edges_to##targets##not root |> Js.to_array |> Array.to_list in
  if List.is_empty successors then read_atom (Js.Unsafe.coerce root) id label_string else
  let tl = List.map successors ~f:read_tree in
  let connective =
    if String.equal label_string "⊗" then 
      Tree.Tensor tl
    else 
      if String.equal label_string "⅋" then
        Tree.Par tl
      else
        raise_s (Sexp.message "error" [])
  in
  {Tree.connective = connective; id = id}