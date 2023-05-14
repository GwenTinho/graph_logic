open Interface.InterfaceHelpers
open Js_of_ocaml

let _ =
  Js.export_all
    (object%js
       method decompose = decompose ()
       method getTreeJson = getTreeJson ()
       method getTreeJsonGS = getTreeJsonGS ()
       method recompose = recompose ()

       method isPrime graph =
         let directed = Js.Unsafe.js_expr "directed" |> Js.to_bool in
         isPrimeIdGraph ~directed graph
    end)
