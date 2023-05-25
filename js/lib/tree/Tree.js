import { cleanLayout, clearGraph } from '../util/helper.js';
import PrimeNode from './PrimeNode.js';
import TreeNode from './TreeNode.js';
import { TreeNodeData } from './TreeNodeData.js';

class Tree {
    constructor() {
        this.roots = [];
        this.maxId = 0;
    }

    addNode(label, x, y, polarisation) {
        let data = new TreeNodeData(label, x, y, polarisation, this.maxId);

        let node = new TreeNode(data, []);
        if (label === "^") {
            node = new PrimeNode(data, []);
        }


        this.maxId++;

        if (this.roots.length === 0) {
            this.roots = [node];
            return;
        }
        this.roots.push(node);
        return this.maxId - 1;
    }


    connectPrimeNode(id1, id2) {
        const node1 = this.getNode(id1);
        const node2 = this.getNode(id2);
        if (node1.data.label != "^" || node2.data.label != "^") {
            throw "Invalid prime node connection";
        }

        node1.data.graph.addEdge(id1, id2);
    }


    connectRootToNode(id1, id2) {
        if (id1 == id2) {
            return;
        }
        const node1 = this.getNode(id1);
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
        clearGraph(cy);

        for (const root of this.roots) {
            root.nodeData.added?.removeClass("root");
            root.render(cy);
            root.nodeData.added.addClass("root");

        }

        cleanLayout(cy);
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
