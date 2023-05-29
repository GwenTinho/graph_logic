import { isValidLabel } from "../util/helper.js";
import IdGraph from "./IdGraph.js";

function toClass(string) {
    switch (string) {
        case "&":
            return "par";
        case "*":
            return "tensor";
        case "^":
            return "prime";
        case ">":
            return "before";
        default:
            return "atom";
    }
}

class TreeNodeData {
    constructor(label, x, y, polarisation, id, isRoot = false) {
        if (!isValidLabel(label)) {
            throw "Invalid label";
        }
        this.x = x;
        this.y = y;
        this.id = id;

        this.class = toClass(label);
        this.canHaveChildren = false;
        this.isRoot = isRoot;
        this.label = label;

        switch (label) {
            case "&":
                this.shownLabel = "⅋";
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            case "*":
                this.shownLabel = "⊗";
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            case "^":
                this.shownLabel = "prime";
                this.graph = new IdGraph(this.id);
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            case ">":
                this.shownLabel = "before";
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            default:
                this.shownLabel = label;
                this.polarisation = polarisation;
                break;
        }
    }

    duplicate(maxId) {
        if (this.class == "prime") {
            const idgData = new TreeNodeData("^", this.x, this.y, this.polarisation, maxId, this.isRoot);
            idgData.graph = this.graph.duplicate(maxId);
            return idgData;
        }

        return new TreeNodeData(this.label, this.x, this.y, this.polarisation, maxId, this.isRoot);
    }

    render(cy) {
        if (this.class === "prime") {
            const contextNode = {
                group: 'nodes',
                data: {
                    id: this.id,
                    label: "",
                },
                renderedPosition: {
                    x: this.x,
                    y: this.y,
                },
            };
            const added = cy.add(contextNode);

            added.addClass(this.class);

            this.graph.render(cy);
            return added;
        }

        const node = {
            group: 'nodes',
            data: {
                id: this.id,
                label: this.shownLabel,
                polarisation: this.polarisation,
            },
            renderedPosition: {
                x: this.x,
                y: this.y,
            },
        };
        const added = cy.add(node);
        added.addClass(this.class);
        if (this.isRoot) added.addClass("root");
        return added;
    }

    negate() {
        if (!this.canHaveChildren) this.polarisation = !this.polarisation;
    }


    serialize() {
        switch (this.class) {
            case "par":
                return {
                    connective: "par",
                };
            case "tensor":
                return {
                    connective: "tensor",
                };
            case "prime":
                return {
                    connective: "prime",
                    graph: this.graph.serialize(),
                };
            case "before":
                return {
                    connective: "before",
                };
            default:
                return {
                    connective: "atom",
                    label: this.label,
                    polarisation: this.polarisation,
                };
        }
    }

    static deserialize(data, id) {
        switch (data.connective) {
            case "par":
                return new TreeNodeData("&", 0, 0, true, id);
            case "tensor":
                return new TreeNodeData("*", 0, 0, true, id);
            case "prime":
                const idgData = new TreeNodeData("^", 0, 0, true, id);
                idgData.graph = IdGraph.deserialize(data.graph, id);
                return idgData;
            case "before":
                return new TreeNodeData(">", 0, 0, true, id);
            default:
                return new TreeNodeData(data.label, 0, 0, data.polarisation, id);
        }
    }
}

export { TreeNodeData };
