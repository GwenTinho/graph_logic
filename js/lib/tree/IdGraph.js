// implementation of index graphs

class IdGraph {
    constructor() {
        this.nodes = {};
        this.adjacency = {};
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
        // redo render using new format
        for (const id in this.nodes) {
            const { x, y } = this.nodes[id];
            const node = {
                group: 'nodes',
                data: {
                    id: id + "prime-representative",
                    label: ""
                },
                renderedPosition: {
                    x: x,
                    y: y,
                },
            };
            const added = cy.add(node);
            cy.changes.push(["add", added]);
            added.addClass('inCompound');

            for (const target of this.adjacency[id]) {
                const edge = {
                    data: {
                        source: id + "prime-representative",
                        target: target + "prime-representative",
                    },
                };
                const added = cy.add(edge);
                cy.changes.push(["add", added]);
                added.addClass('compoundOut');
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
