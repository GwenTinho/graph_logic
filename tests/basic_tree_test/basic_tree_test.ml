open Gscore

exception READERROR of string

let path = "./graph_test_suite.json"
let graphs = Parsegraph.read_file_as_graphs path

let trees =
  List.map (fun g -> Caml.Option.get (Condense.tree_from_graph g)) graphs

let%test "Equality_same_ids" = List.for_all2 Equality.equal_tree trees trees

let%test "Inequality_pairwise" =
  match trees with
  | t1 :: t2 :: t3 :: _ ->
      (not (Equality.equal_tree t1 t2)) && not (Equality.equal_tree t1 t3)
  | _ -> raise Exit

let%test "Inequality_pairwise_eq" =
  match trees with
  | t1 :: t2 :: t3 :: _ ->
      (not (Equality.equal_tree t1 t2)) && not (Equality.equal_tree t1 t3)
  | _ -> raise Exit

let%test "ineq1" =
  match trees with
  | t1 :: t2 :: _ :: _ -> not (Equality.equal_tree t1 t2)
  | _ -> raise Exit

let%test "ineq2" =
  match trees with
  | t1 :: _ :: t3 :: _ -> not (Equality.equal_tree t1 t3)
  | _ -> raise Exit

let%test "ineq3" =
  match trees with
  | t1 :: t2 :: _ :: _ -> not (Equality.equal_tree t1 t2)
  | _ -> raise Exit

let%test "ineq4" =
  match trees with
  | t1 :: _ :: t3 :: _ -> not (Equality.equal_tree t1 t3)
  | _ -> raise Exit

let%test "Symmetry" =
  List.for_all2
    (fun t1 t2 -> Equality.equal_tree t1 t2 && Equality.equal_tree t2 t1)
    trees trees

let%test "Symmetry_eq" =
  List.for_all2
    (fun t1 t2 -> Equality.equal_tree t1 t2 && Equality.equal_tree t2 t1)
    trees trees
