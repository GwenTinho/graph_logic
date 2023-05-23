import { TreeNodeData } from './TreeNodeData.js';

class TreeNode {
    constructor(nodeData, successors) {
        this.nodeData = nodeData;
        this.successors = successors;
    }

    // returns true if the node was added, false otherwise
    addChild(node) {
        if (!this.nodeData.canHaveChildren) {
            return false;
        }
        // the successors are sorted by id to make binary search possible
        // we can use this to insert the new node in the correct position

        // find the index of the first successor with a higher id
        let index = 0;
        while (index < this.successors.length && this.successors[index].nodeData.id < node.nodeData.id) {
            index++;
        }
        // insert the new node at that index
        this.successors.splice(index, 0, node);
        return true;
    }

    getNode(id) {
        if (this.nodeData.id == id) {
            return this;
        }
        // just go through all successors
        for (const successor of this.successors) {
            const node = successor.getNode(id);
            if (node != null) {
                return node;
            }
        }
    }

    dropNode(id) {
        // just go through all successors
        for (let index = 0; index < this.successors.length; index++) {
            const successor = this.successors[index];
            if (successor.nodeData.id == id) {
                this.successors.splice(index, 1);
                return;
            }
            successor.dropNode(id);
        }
    }

    getPath(id) {
        const path = [];
        if (this.nodeData.id == id) {
            return path;
        }

        // keep track of list indicies in for loop
        for (let i = 0; i < this.successors.length; i++) {
            const successor = this.successors[i];
            const path = successor.getPath(id);
            if (path != null) {
                path.push(i);
                return path;
            }
        }
    }

    negate() {
        this.nodeData.negate();
    }


    id() {
        return this.nodeData.id;
    }


    serialize() {
        const out = this.nodeData.serialize();

        if (!this.nodeData.canHaveChildren) return out;

        const successors = [];
        for (const successor of this.successors) {
            successors.push(successor.serialize());
        }

        out.successors = successors;

        return out;
    }

    static deserialize(serialized) {
        const nodeData = NodeData.deserialize(serialized.nodeData);
        const successors = [];
        for (const successor of serialized.successors) {
            successors.push(Node.deserialize(successor));
        }
        return new Node(nodeData, successors);
    }

    render(cy) {
        const to_add = [];

        this.nodeData.render(cy);
        for (const successor of this.successors) {
            successor.render(cy);
            to_add.push({
                group: 'edges',
                data: {
                    source: this.nodeData.id,
                    target: successor.nodeData.id,
                }
            });

        }

        const added = cy.add(to_add);
        cy.changes.push(["add", added]);
        return added;
    }
}

export default TreeNode;
