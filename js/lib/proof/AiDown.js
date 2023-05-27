import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class AiDown extends Rule {
    constructor() {
        super('AiDown', ["par", "atom", "atom"]);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = ai(...this.givenPaths);
            if (newTreeString === undefined) {
                throw new Error("ai returned undefined");
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default AiDown;
