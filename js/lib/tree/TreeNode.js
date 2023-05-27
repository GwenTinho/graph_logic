import { TreeNodeData } from './TreeNodeData.js';

class TreeNode {
    constructor(nodeData, successors = []) {
        this.nodeData = nodeData;
        this.successors = successors;
    }

    // returns true if the node was added, false otherwise
    addChild(node) {
        if (!this.nodeData.canHaveChildren) {
            return false;
        }

        // find the index of the first successor with a higher id
        let index = 0;
        while (index < this.successors.length && this.successors[index].nodeData.id < node.nodeData.id) {
            index++;
        }
        // insert the new node at that index
        node.nodeData.isRoot = false;
        this.successors.splice(index, 0, node);
        return true;
    }

    // implement duplicate
    duplicate(maxId) {
        // we need to keep new ids unique
        // so we need to find the max id in the tree
        // and then add 1 to it
        const subtreeMaxId = this.findMaxId();

        const nodeData = this.nodeData.duplicate(subtreeMaxId + maxId + 1);
        const successors = [];
        for (const successor of this.successors) {
            successors.push(successor.duplicate(subtreeMaxId + maxId + 1));
        }
        return new TreeNode(nodeData, successors);
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

    findMaxId() {
        let maxId = this.nodeData.id;
        for (const successor of this.successors) {
            const id = successor.findMaxId();
            if (id > maxId) {
                maxId = id;
            }
        }
        return maxId;
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
            if (path !== undefined) {
                path.unshift(i);
                return path;
            }
        }
    }

    negate() {
        this.nodeData.negate();
        for (const successor of this.successors) {
            successor.negate();
        }
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

    static deserialize(data, idref = { id: 0 }) {
        const nodeData = TreeNodeData.deserialize(data, idref.id);
        const successors = [];
        if (!nodeData.canHaveChildren) return new TreeNode(nodeData);
        for (const successor of data.successors) {
            idref.id++;
            successors.push(TreeNode.deserialize(successor, idref));
        }
        return new TreeNode(nodeData, successors);
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
