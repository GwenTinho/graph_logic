import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class Simplify extends Rule {
    constructor() {
        super('simplify', []);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = simplify();
            if (newTreeString === undefined) {
                return new Tree();
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default Simplify;
