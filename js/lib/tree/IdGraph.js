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

    isValid() {
        // check if graph is a prime graph
    }

    render(cy) {

        // first render all nodes
        for (const id in this.nodes) {
            const { x, y } = this.nodes[id];


            const node = {
                group: 'nodes',
                data: {
                    id: id + "prime-representative",
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
                        source: id + "prime-representative",
                        target: target + "prime-representative",
                    },
                };
                const added = cy.add(innerEdge);
                cy.changes.push(["add", added]);
                added.addClass('compoundIn');
            }
        }
    }

    serialize() {
        // TODO
    }

    static deserialize() {
        // TODO
    }
}

export default IdGraph;
