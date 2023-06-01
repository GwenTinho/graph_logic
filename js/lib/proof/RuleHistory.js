import Tree from "../tree/Tree.js";

class RuleHistory {
    constructor() {
        this.history = [];
        this.initial = undefined;
    }

    add(rule) {
        switch (rule.name) {
            case "ai":
                this.history.push({
                    type: rule.name,
                    data: {
                        par: rule.givenPaths[0],
                        atom1: rule.givenPaths[1],
                        atom2: rule.givenPaths[2]
                    }
                });
                break;
            case "pp":
                this.history.push({
                    type: rule.name,
                    data: {
                        par: rule.givenPaths[0],
                        prime1: rule.givenPaths[1],
                        prime2: rule.givenPaths[2]
                    }
                });
                break;
            case "sw":
                this.history.push({
                    type: rule.name,
                    data: {
                        par: rule.givenPaths[0],
                        outside: rule.givenPaths[1],
                        prime: rule.givenPaths[2],
                        inside: rule.givenPaths[3]
                    }
                });
                break;
            case "simplify":
                this.history.push({
                    type: rule.name,
                    data: {
                    }
                });
                break;
            default:
                throw new Error("Unknown rule name: " + rule.name);
        }

    }

    serialize() {
        return {
            initial: this.initial,
            steps: this.history
        }
    }

    concat(initial, steps) {
        if (this.history.length === 0) {
            this.initial = initial;
        }
        this.history = this.history.concat(steps);
    }

    fromJSON(dataString) {
        const { initial, steps } = JSON.parse(dataString);
        this.history = steps;
        this.initial = initial;
        window.tree = Tree.deserialize(initial);
    }

    render() {
        const table = document.getElementById("history-body");
        table.innerHTML = "";
        for (const { type, data } of this.history) {
            const tr = document.createElement("tr");
            tr.appendChild(document.createTextNode(type));

            // TODO we dont consider the data yet

            table.appendChild(tr);
        }
    }

    verify() {
        if (this.initial === undefined) {
            return;
        }
        return verify(JSON.stringify(ruleHistory.serialize()))
    }

    clear() {
        this.history = [];
        this.initial = undefined;

    }
}

export default RuleHistory;
