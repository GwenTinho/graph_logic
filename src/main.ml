open InterfaceHelpers
open Js_of_ocaml

let _ =
  Js.export_all
    (object%js
       method decompose = decompose ()
       method recompose = recompose ()
       method ai path1 path2 pathPar = ai_down path1 path2 pathPar

       method isPrime graph =
         let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
         isPrimeIdGraph ~directed graph
    end)
