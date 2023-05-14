open Logic
open Logic.Idgraph

exception READERROR of string

(*K3, K2 graphs complete, e2 e3, n nodes no edges*)

let emptyidg = { nodes = []; edges = [] }
let gs = Parseproofs.read_file_as_id_graphs "idg_simple.json"

let k3, k2, e3, e2 =
  match gs with
  | k3 :: k2 :: e2 :: e3 :: _ -> (k3, k2, e3, e2)
  | _ -> raise (READERROR "Could not find valid graph")

let%test "empty_iso_reflexive" = is_sub_iso emptyidg emptyidg
let%test "empty_iso_subgraph_k3" = is_sub_iso emptyidg k3
let%test "empty_iso_subgraph_k2" = is_sub_iso emptyidg k2
let%test "empty_iso_subgraph_e3" = is_sub_iso emptyidg e3
let%test "empty_iso_subgraph_e2" = is_sub_iso emptyidg e2
let%test "iso_reflexive_k3" = is_sub_iso k3 k3
let%test "iso_reflexive_k2" = is_sub_iso k2 k2
let%test "iso_reflexive_e3" = is_sub_iso e3 e3
let%test "iso_reflexive_e2" = is_sub_iso e2 e2
let%test "iso_sg_k2_k3" = is_sub_iso k2 k3
let%test "iso_sg_e2_k3" = is_sub_iso e2 k3
let%test "iso_sg_e2_k2" = is_sub_iso e2 k2
let%test "iso_sg_e3_k3" = is_sub_iso e3 k3
let%test "iso_sg_e2_e3" = is_sub_iso e2 e3
let%test "not_iso_sg_k3_k2" = not (is_sub_iso k3 k2)
let%test "not_iso_sg_e3_k2" = not (is_sub_iso e3 k2)
let%test "not_iso_sg_k2_e2" = not (is_sub_iso k2 e2)
let%test "not_iso_sg_k3_e3" = not (is_sub_iso k3 e3)
let%test "not_iso_sg_e3_e2" = not (is_sub_iso e3 e2)
