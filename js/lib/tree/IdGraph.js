// implementation of index graphs

class IdGraph {
    constructor() {
        this.nodes = [];
        this.adjacency = [];
    }

    addNode(x, y, id) {
        this.nodes.push({
            x: x,
            y: y,
            id: id,
        });
    }

    addEdge(id1, id2) {
        this.edges.push({ source: id1, target: id2 });
    }

    isValid() {
        // check if graph is a prime graph
    }

    render(cy) {
        for (const { x, y, id } of this.nodes) {
            const node = {
                group: 'nodes',
                data: {
                    id: id,
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
        }


        for (const { source, target } of this.edges) {
            const edge = {
                data: {
                    source: source,
                    target: target,
                },
            };
            const added = cy.add(edge);
            cy.changes.push(["add", added]);
            added.addClass('compoundOut');
        }
    }
}

export default IdGraph;
