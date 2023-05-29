import Tree from "../tree/Tree.js";

class Auto {
    constructor() {

    }

    ai() {
        const res = autoAI();
        if (res === undefined) {
            throw new Error("autoAI returned undefined");
        }

        const { initial, steps } = JSON.parse(res);

        for (const step of steps) {
            switch (step.type) {
                case "ai":
                    const newTreeString = ai(step.data.par, step.data.atom1, step.data.atom2);
                    if (newTreeString === undefined) {
                        console.log("ai didn't apply");
                        return window.tree;
                    }
                    window.tree = Tree.deserialize(JSON.parse(newTreeString));

                    break;
                default:
                    throw new Error("Unknown rule name: " + step.type);
            }
        }
        window.ruleHistory.concat(initial, steps);
        window.tree.render(window.cy);
        window.ruleHistory.render();
    }

    pp() {
        const res = autoPrime();
        if (res === undefined) {
            throw new Error("autoPP returned undefined");
        }

        const { initial, steps } = JSON.parse(res);

        for (const step of steps) {
            switch (step.type) {
                case "pp":
                    const newTreeString = prime(step.data.par, step.data.prime1, step.data.prime2);
                    if (newTreeString === undefined) {
                        console.log("prime didn't apply");
                        return window.tree;
                    }
                    window.tree = Tree.deserialize(JSON.parse(newTreeString));

                    break;
                default:
                    throw new Error("Unknown rule name: " + step.type);
            }
        }
        window.ruleHistory.concat(initial, steps);
        window.tree.render(window.cy);
        window.ruleHistory.render();
    }

    sw() {
        const res = autoSwitch();
        if (res === undefined) {
            throw new Error("autoSW returned undefined");
        }

        const { initial, steps } = JSON.parse(res);

        for (const step of steps) {
            switch (step.type) {
                case "sw":
                    const newTreeString = switchPar(step.data.par, step.data.outside, step.data.prime, step.data.inside);
                    if (newTreeString === undefined) {
                        console.log("switch didn't apply");
                        return window.tree;
                    }
                    window.tree = Tree.deserialize(JSON.parse(newTreeString));

                    break;
                default:
                    throw new Error("Unknown rule name: " + step.type);
            }
        }
        window.ruleHistory.concat(initial, steps);
        window.tree.render(window.cy);
        window.ruleHistory.render();
    }
}

export default Auto;
