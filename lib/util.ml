open Base

let disjoint s1 s2 =
  let diff = Set.diff s1 s2 in
  (* O(l1 + l2) *)
  Set.equal s1 diff (* O(l1 + l2) *)

let complement_map set map =
  Map.filter_keys map ~f:(fun ele -> Set.mem set ele |> not)
  |> Map.map ~f:(Fn.flip Set.diff set)

let intersect_map set map =
  Map.filter_keys map ~f:(Set.mem set) |> Map.map ~f:(Fn.flip Set.inter set)

let remove_id id map =
  Map.remove map id |> Map.map ~f:(fun v -> Set.remove v id)

let find_fitting_pair lst comp =
  let rec aux rem1 rem2 =
    match (rem1, rem2) with
    | [], _ -> None
    | _ :: t1, [] -> aux t1 lst
    | (h1 :: _ as l), h2 :: t2 -> if comp h1 h2 then Some (h1, h2) else aux l t2
  in
  aux lst lst

module ISet = struct
  type t = Base.Set.M(Int).t [@@deriving compare, sexp, hash]
end

include Comparable.Make (ISet)

module IMap = struct
  type t = ISet.t Base.Map.M(Int).t [@@deriving compare, sexp, hash]
end

include Comparable.Make (IMap)
