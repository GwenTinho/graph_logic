open Gscore.Id_graph

let g1 : id_graph =
  { nodes = [ 1; 5; 10; 27 ]; edges = [ (1, 5); (5, 10); (10, 27) ] }

let g2 : id_graph =
  { nodes = [ 2; 3; 10; 27 ]; edges = [ (2, 3); (3, 10); (10, 27) ] }

let g3 : id_graph =
  { nodes = [ 3; 2; 10; 27 ]; edges = [ (3, 2); (3, 10); (10, 27) ] }

let g4 : id_graph = { nodes = [ 2; 3; 10 ]; edges = [ (2, 3); (3, 10) ] }
let%test "sub_iso_renaming_left" = is_sub_iso g1 g2
let%test "sub_iso_renaming_right" = is_sub_iso g2 g1
let%test "sub_iso_reordering_left" = is_sub_iso g3 g2
let%test "sub_iso_reordering_right" = is_sub_iso g2 g3
let%test "sub_iso_reordering2_left" = is_sub_iso g3 g1
let%test "sub_iso_reordering2_right" = is_sub_iso g1 g3
let%test "sub_iso_shortened_left1" = is_sub_iso g4 g1
let%test "sub_iso_shortened_left2" = is_sub_iso g4 g2
let%test "sub_iso_shortened_left3" = is_sub_iso g4 g3
let%test "sub_iso_shortened_not_right1" = not (is_sub_iso g1 g4)
let%test "sub_iso_shortened_not_right2" = not (is_sub_iso g2 g4)
let%test "sub_iso_shortened_not_right3" = not (is_sub_iso g3 g4)
