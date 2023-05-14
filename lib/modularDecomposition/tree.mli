type id_graph = {
    nodes : int list;
    edges : (int * int) list;
}

type connective =
  | Atom of Graph.atom
  | Tensor of tree list
  | Par of tree list
  | Before of tree list
  | Prime of id_graph * (tree list)

and tree = {
    connective : connective;
    id: int;
    }

val successors : tree -> tree list

val tree_from_condensed : ?directed:bool -> Graph.graph -> Graph.state -> tree option

val tree_to_graph : ?directed:bool -> tree -> Graph.graph