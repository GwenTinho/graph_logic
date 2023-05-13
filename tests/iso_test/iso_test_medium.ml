open Gscore
open Gscore.Id_graph

exception READERROR of string

(*g, h, g <= h*)
let gs = Parsegraph.read_file_as_id_graphs "idg_complex.json"

let g, h =
  match gs with
  | g :: h :: _ -> (g, h)
  | _ -> raise (READERROR "Could not find valid graph")

let%test "iso_sg_g_h" = is_sub_iso g h
let%test "iso_not_sg_h_g" = not (is_sub_iso h g)
