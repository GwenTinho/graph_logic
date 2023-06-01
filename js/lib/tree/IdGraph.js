// implementation of index graphs

class IdGraph {
    constructor(id) {
        this.nodes = {};
        this.adjacency = {};
        this.parentId = id;
    }

    isEmpty() {
        return Object.keys(this.nodes).length == 0;
    }

    addNode(x, y, id) {
        this.nodes[id] = { x: x, y: y };
        this.adjacency[id] = [];
    }

    addEdge(id1, id2) {
        this.adjacency[id1].push(parseInt(id2));
        //this.adjacency[id2].push(id1); undirected edges
    }

    dropNode(id) {
        delete this.nodes[id];
        delete this.adjacency[id];
        for (const id2 in this.adjacency) {
            const index = this.adjacency[id2].indexOf(parseInt(id));
            if (index > -1) {
                this.adjacency[id2].splice(index, 1);
            }
        }
    }

    duplicate(newParentId) {
        const graph = new IdGraph(newParentId);
        for (const id in this.nodes) {
            graph.addNode(this.nodes[id].x, this.nodes[id].y, parseInt(id));
        }

        for (const id in this.adjacency) {
            for (const target of this.adjacency[id]) {
                graph.addEdge(parseInt(id), parseInt(target));
            }
        }

        return graph;
    }

    isValid() {
        // check if graph is a prime graph

        return isPrimeGS(this.serialize());
    }

    render(cy) {

        // first render all nodes
        for (const id in this.nodes) {
            const { x, y } = this.nodes[id];


            const node = {
                group: 'nodes',
                data: {
                    id: (this.parentId + parseInt(id)) + "prime-representative",
                    label: "",
                    parent: this.parentId,
                },
                renderedPosition: {
                    x: x,
                    y: y,
                },
            };
            const added = cy.add(node);
            added.addClass('inCompound');
        }

        // then render all edges
        for (const id in this.adjacency) {
            for (const target of this.adjacency[id]) {
                const innerEdge = {
                    data: {
                        source: (this.parentId + parseInt(id)) + "prime-representative",
                        target: (this.parentId + parseInt(target)) + "prime-representative",
                    },
                };
                const added = cy.add(innerEdge);
                added.addClass('compoundIn');
            }
        }
    }

    serialize() {
        // serialize as a list of nodes and a list of edges
        const nodes = [];
        const edges = [];
        for (const id in this.nodes) {
            nodes.push(parseInt(id));
        }

        for (const id in this.adjacency) {
            for (const target of this.adjacency[id]) {
                edges.push({ source: parseInt(id), target: parseInt(target) });
            }
        }

        return {
            nodes: nodes,
            edges: edges,
        };
    }

    static deserialize(data, id) {
        // deserialize from a list of nodes and a list of edges

        const graph = new IdGraph(id);
        for (const id of data.nodes) {
            graph.addNode(0, 0, id);
        }

        for (const { source, target } of data.edges) {
            graph.addEdge(source, target);
        }

        return graph;
    }
}

export default IdGraph;
