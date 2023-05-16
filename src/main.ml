open Interface.InterfaceHelpers
open Js_of_ocaml

let _ =
  Js.export_all
    (object%js
       method getTreeJsonGS = getTreeJsonGS ()
       method decompose = decompose ()
       method recompose = recompose ()

       method isPrime graph =
         let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
         isPrimeIdGraph ~directed graph
    end)
