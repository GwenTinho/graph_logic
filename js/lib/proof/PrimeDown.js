import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class PrimeDown extends Rule {
    constructor() {
        super('pp', ["par", "prime", "prime"]);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = prime(...this.givenPaths);
            if (newTreeString === undefined) {
                console.log("prime didn't apply");
                return window.tree;
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default PrimeDown;
