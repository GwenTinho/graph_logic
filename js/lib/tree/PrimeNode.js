import TreeNode from "./TreeNode.js";

class PrimeNode extends TreeNode {
    constructor(nodeData, successors) {
        super(nodeData, successors);
        if (this.nodeData.label !== "prime") throw "Cannot make a PrimeNode with a non-prime nodeData";

    }

    addChild(node) {
        const { x, y, id } = node.nodeData;
        this.nodeData.graph.addNode(x, y, id);
        this.successors.push(node); // might be problematic for orderings
        return true;
    }

    render(cy) {
        const to_add = [];
        this.nodeData.render(cy);

        for (const successor of this.successors) {
            successor.render(cy);
            const id = successor.id();
            to_add.push({
                group: 'edges',
                data: {
                    source: id + "prime-representative",
                    target: id,
                },
            });
        }

        const added = cy.add(to_add);
        cy.changes.push(["add", added]);
        added.addClass('compoundOut');
        return added;

    }

}

export default PrimeNode;
