import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class SwitchPar extends Rule {
    constructor() {
        super('SwitchPar', ["par", "any", "any", "any"]);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = switchPar(...this.givenPaths);
            if (newTreeString === undefined) {
                throw new Error("switchPar returned undefined");
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default SwitchPar;
