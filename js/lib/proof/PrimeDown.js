import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class PrimeDown extends Rule {
    constructor() {
        super('PrimeDown', ["par", "prime", "prime"]);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = prime(...this.givenPaths);
            if (newTreeString === undefined) {
                throw new Error("prime returned undefined");
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default PrimeDown;
