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

        switch (label) {
            case "&":
                this.label = "⅋";
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            case "*":
                this.label = "⊗";
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            case "^":
                this.label = "prime";
                this.graph = new IdGraph(this.id);
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            case ">":
                this.label = "before";
                this.canHaveChildren = true;
                this.polarisation = true;
                break;
            default:
                this.label = label;
                this.polarisation = polarisation;
                break;
        }
    }

    render(cy) {
        if (this.label == "prime") {
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

            cy.changes.push(["add", added]);
            added.addClass(this.class);

            this.graph.render(cy);
            return added;
        }

        const node = {
            group: 'nodes',
            data: {
                id: this.id,
                label: this.label,
                polarisation: this.polarisation,
            },
            renderedPosition: {
                x: this.x,
                y: this.y,
            },
        };
        const added = cy.add(node);
        cy.changes.push(["add", added]);
        added.addClass(this.class);
        if (this.isRoot) added.addClass("root");
        return added;
    }

    negate() {
        if (!this.canHaveChildren) this.polarisation = !this.polarisation;
    }


    serialize() {
        switch (this.label) {
            case "⅋":
                return {
                    connective: "par",
                };
            case "⊗":
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

    static deserialize(serialized) {
        switch (serialized.connective) {
            case "par":
                return new TreeNodeData("&", 0, 0, true, serialized.id);
            case "tensor":
                return new TreeNodeData("*", 0, 0, true, serialized.id);
            case "prime":
                const data = new TreeNodeData("^", 0, 0, true, serialized.id);
                data.graph = IdGraph.deserialize(serialized.graph);
                return data;
            case "before":
                return new TreeNodeData(">", 0, 0, true, serialized.id);
            default:
                return new TreeNodeData(serialized.label, 0, 0, serialized.polarisation, serialized.id);
        }
    }
}

export { TreeNodeData };