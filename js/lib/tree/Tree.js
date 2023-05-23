import TreeNode from './TreeNode.js';
import { TreeNodeData } from './TreeNodeData.js';

class Tree {
    constructor() {
        this.roots = [];
        this.maxId = 0;
    }

    addNode(label, x, y, polarisation) {
        let data = new TreeNodeData(label, x, y, polarisation, this.maxId);
        const node = new TreeNode(data, []);
        this.maxId++;

        if (this.roots.length === 0) {
            this.roots = [node];
            return;
        }
        this.roots.push(node);
    }

    addPrimeNode(x, y) {
        let data = new TreeNodeData("^", x, y, undefined, this.maxId);
        const node = new TreeNode(data, []);
        this.maxId++;

        data.graph.addNode(x, y, this.maxId);

        if (!this.roots?.length) {
            this.roots = [node];
            return;
        }
        this.roots.push(node);
    }

    connectPrimeNode(id1, id2) {
        const node1 = this.getNode(id1);
        const node2 = this.getNode(id2);
        if (node1.data.label != "^" || node2.data.label != "^") {
            throw "Invalid prime node connection";
        }

        node1.data.graph.addEdge(id1, id2);
    }


    connectRoots(id1, id2) {
        if (id1 == id2) {
            return;
        }
        const node1 = this.getRoot(id1);
        const node2idx = this.getRootIndex(id2);
        if (node1) {
            const node2 = this.roots[node2idx];
            if (node1.addChild(node2)) {
                this.dropRootIndex(node2idx);
            }
        }

    }

    getRoot(id) {
        for (const root of this.roots) {
            if (root.getNode(id)) {
                return root;
            }
        }
    }

    getRootIndex(id) {
        for (let index = 0; index < this.roots.length; index++) {
            const root = this.roots[index];
            if (root.getNode(id)) {
                return index;
            }
        }
    }

    dropRootIndex(index) {
        this.roots.splice(index, 1);
    }

    dropRoot(id) {
        for (let index = 0; index < this.roots.length; index++) {
            const root = this.roots[index];
            if (root.getNode(id)) {
                this.roots.splice(index, 1);
                return;
            }
        }
    }

    dropNode(id) {
        for (let index = 0; index < this.roots.length; index++) {
            const root = this.roots[index];
            if (root.getNode(id)) {
                root.dropNode(id);
                if (!root.successors?.length) {
                    this.roots.splice(index, 1);
                }
                return;
            }
        }
    }

    getNode(id) {
        for (const root of this.roots) {
            const node = root.getNode(id);
            if (node != null) {
                return node;
            }
        }
    }

    getPath(id) {
        for (let index = 0; index < roots.length; index++) {
            const root = roots[index];
            const path = root.getPath(id);
            if (path != null) {
                path.unshift(index);
                return path;
            }
        }
    }

    negate(id) {
        const node = this.getNode(id);
        node.negate();
    }

    render(cy) {

        for (const root of this.roots) {
            const renderv = root.nodeData.render(cy);
            renderv.addClass("root");
            root.render(cy);
            renderv.removeClass("root");
        }
    }

    isConnected() {
        return this.roots.length <= 1;
    }

    serialize() {
        if (this.isConnected()) {
            return this.roots?.[0].serialize();
        }
    }

    updateMaxId() {
        let maxId = 0;
        for (const root of this.roots) {
            const id = root.findMaxId();
            if (id > maxId) {
                maxId = id;
            }
        }
        this.maxId = maxId;
    }

    static deserialize(data) {
        const tree = new Tree();

        if (data) {
            const root = TreeNode.deserialize(data);
            tree.roots.push(root);
            tree.updateMaxId();
        }

        return tree;
    }
}

export default Tree;
