<div id="top"></div>

[![Build](https://github.com/Remyjck/modular_decomposition/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/Remyjck/modular_decomposition/actions/workflows/main.yml)

Modular Decomposition of Graphs
===


## About The Project

This project aims to provide an interactive way to interact with graphs as proofs. The main functionalities provided are the creation of graphs and the modular decomposition of any inputted graph.

## Prerequisites

Building this project requires the Ocaml package manager [opam](https://opam.ocaml.org/doc/Install.html#Using-your-distribution-39-s-package-system).
* Ubuntu
  ```sh
  add-apt-repository ppa:avsm/ppa
  apt update
  apt install opam
  ```
* macOs
  ```sh
  # Homebrew
  brew install opam

  # MacPort
  port install opam
  ```
* Windows
    It is recommended to use WSL or Cygwin to build this project using windows.

Once opam is installed, it can be used to install Ocaml.

<p align="right">(<a href="#top">back to top</a>)</p>

The project also requires some way of locally hosting an html file, a simple way to do this is using python.

## Build requirements

* Ocaml 4.13 or later
* Js_of_ocaml 4.0 or later
* Yojson 1.7 or later
* Base 4.13 or later

## Installation
1. Clone the repo
   ```sh
   git clone https://github.com/Remyjck/modular_decomposition.git
   ```
2. Go into the Ocaml project directory
   ```sh
   cd quartic
   ```
4. Install opam packages
   ```sh
   opam install . --deps-only
   ```
4. Build the project files
   ```sh
   dune build
   ```



## Usage

Building the projects generates a `main.bc.js` file in the `_build/default/src/` subdirectory of `quartic/`. This JavaScript file is then used by `index.html` to run the project. Once the project is built, we only have to serve the html file locally using python (run from root folder of the project):
   ```sh
   python3 -m http.server
   ```

## Formats:
Trees are given as follows:
```js
{
   "connective": "atom" | "prime" | "par" | "tensor",
   "successors": [Tree] | undefined,
   "graph": {
      "nodes": [int],
      "edges": [{source:int, target:int}]
   } | undefined,
   "label": string | undefined
   "polarisation": bool | undefined
}
```
If the connective is "atom", successors can be undefined and label and polarisation need to be given.
If the connective is prime, a graph needs to be given.

Rule_ids are given by:
```js
{
   "type": "ai" | "pp" | "sw" | "simplify"
   "data": 
      {"par": [int], "atom1": [int], "atom2": [int]} |
      {"par": [int], "prime1": [int], "prime2": [int]} |
      {"par": [int], "outside": [int], "prime": [int], "inside": [int]}

}
```

Where for the "simplify" type no further data is given.

Proofs are then given as follows:
```js
{
   "initial": Tree,
   "steps": [rule_id],
}
```

## References

* [Modular Decomposition of Graphs](https://www.irif.fr/~habib/Documents/cours_4-2015.pdf)
* [Proof System GS] (https://lmcs.episciences.org/10186/pdf)
* [Proof System GV] (https://drops.dagstuhl.de/opus/volltexte/2022/16303/pdf/LIPIcs-FSCD-2022-22.pdf)
