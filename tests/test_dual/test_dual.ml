open Logic
open Logic.Idgraph

exception READERROR of string

(*E4 empty 4 nodes, K4 graph complete*)

let emptyidg = { nodes = []; edges = [] }
let gs = Parseproofs.read_file_as_id_graphs "idg_dual.json"

let e4, k4, h, g =
  match gs with
  | e4 :: k4 :: h :: g :: _ -> (e4, k4, g, h)
  | _ -> raise (READERROR "Could not find valid graph")

(*Not extensive enough*)
let%test "is_dual_e4_k4" = is_dual e4 k4
let%test "is_dual_k4_e4" = is_dual k4 e4
let%test "is_dual_h_g" = is_dual h g
let%test "is_dual_g_h" = is_dual g h

let%test "completion_of_empty_is_empty" =
  is_iso (completetion_graph emptyidg) emptyidg

let%test "complement_of_empty_is_empty" =
  is_iso (id_graph_complement emptyidg) emptyidg

let%test "completion_of_complete_is_complete" =
  is_iso (completetion_graph k4) k4

let p4 = { nodes = [ 1; 2; 3; 4 ]; edges = [ (1, 2); (2, 3); (3, 4) ] }
let%test "p4_is_self_dual" = is_dual p4 p4
