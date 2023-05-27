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
        this.adjacency[id1].push(id2);
        //this.adjacency[id2].push(id1); undirected edges
    }

    duplicate(newParentId) {
        const graph = new IdGraph(newParentId);
        for (const id in this.nodes) {
            graph.addNode(this.nodes[id].x, this.nodes[id].y, id);
        }

        for (const id in this.adjacency) {
            for (const target of this.adjacency[id]) {
                graph.addEdge(id, target);
            }
        }

        return graph;
    }

    isValid() {
        // check if graph is a prime graph

        return isPrime(this.serialize());
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
            cy.changes.push(["add", added]);
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
                cy.changes.push(["add", added]);
                added.addClass('compoundIn');
            }
        }
    }

    serialize() {
        // serialize as a list of nodes and a list of edges
        const nodes = [];
        const edges = [];
        for (const id in this.nodes) {
            nodes.push(id);
        }

        for (const id in this.adjacency) {
            for (const target of this.adjacency[id]) {
                edges.push([id, target]);
            }
        }

        return {
            nodes: nodes,
            edges: edges,
        };
    }

    static deserialize(data) {
        // deserialize from a list of nodes and a list of edges

        const graph = new IdGraph();
        for (const node of data.nodes) {
            graph.addNode(0, 0, node.id);
        }

        for (const edge of data.edges) {
            graph.addEdge(edge[0], edge[1]);
        }

        return graph;
    }
}

export default IdGraph;
