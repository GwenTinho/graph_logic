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

## Build requirements

* Ocaml 4.13 or later
* Js_of_ocaml 4.0 or later
* Yojson 1.7 or later
* Base 4.13 or later

<p align="right">(<a href="#top">back to top</a>)</p>

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

<p align="right">(<a href="#top">back to top</a>)</p>

## Usage

Building the projects generates a `main.bc.js` file in the `_build/default/src/` subdirectory of `quartic/`. This JavaScript file is then used by `index.html` to run the project. Once the project is built, it is thus only necessary to open `index.html` with the browser of your choice.
