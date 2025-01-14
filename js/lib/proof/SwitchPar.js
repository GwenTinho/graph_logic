import Tree from "../tree/Tree.js";
import Rule from "./Rule.js";

class SwitchPar extends Rule {
    constructor() {
        super('sw', ["par", "any", "any", "any"]);
    }

    applyRule() {
        if (this.neededPaths.length === 0) {
            const newTreeString = switchPar(...this.givenPaths);
            if (newTreeString === undefined) {
                console.log("switch didn't apply");
                return window.tree;
            }
            return Tree.deserialize(JSON.parse(newTreeString));
        }
    }
}

export default SwitchPar;
