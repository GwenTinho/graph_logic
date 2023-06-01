import TreeNode from "./TreeNode.js";

class PrimeNode extends TreeNode {
    constructor(nodeData) {
        super(nodeData);
        if (this.nodeData.class !== "prime") throw "Cannot make a PrimeNode with a non-prime nodeData";

    }

    addChild(node) {
        const { x, y, id } = node.nodeData;
        this.nodeData.graph.addNode(x, y + 100, id);
        node.nodeData.isRoot = false;
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
                    source: (this.nodeData.id + id) + "prime-representative",
                    target: id,
                },
            });
        }

        const added = cy.add(to_add);
        added.addClass('compoundOut');
        return added;

    }

    dropNode(id) {
        for (let index = 0; index < this.successors.length; index++) {
            const successor = this.successors[index];
            if (successor.nodeData.id == id) {
                this.successors.splice(index, 1);
                this.nodeData.graph.dropNode(id);
                return;
            }
            successor.dropNode(id);
        }
    }

}

export default PrimeNode;
