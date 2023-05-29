import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class AiDown extends Rule {
    constructor() {
        super('ai', ["par", "atom", "atom"]);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = ai(...this.givenPaths);
            if (newTreeString === undefined) {
                console.log("ai didn't apply");
                return window.tree;
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default AiDown;
