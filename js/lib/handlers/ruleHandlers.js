import AiDown from "../proof/AiDown.js";
import Auto from "../proof/Auto.js";
import PrimeDown from "../proof/PrimeDown.js";
import Simplify from "../proof/Simplify.js";
import SwitchPar from "../proof/SwitchPar.js";


// check if tree is valid before a proof TODO
function isValid(tree) {
    if (!tree.isConnected()) {
        const a = document.createElement("a");
        a.href = "#dontsee";
        a.id = "dontsee";
        a.setAttribute("role", "button");
        a.classList.add("secondary");
        a.onclick = function () { showNonConnected = false; closeModal() };
        a.innerText = "Don't show this again";
        openModal(
            "Could not get graph",
            `The drawn decomposition tree is not connected.
            Please ensure that all nodes are connected to the root (select a root by double clicking a node).`,
            a
        )
        return false;
    }

    if (!tree.isAllPrime()) {
        const a = document.createElement("a");
        a.href = "#dontsee";
        a.id = "dontsee";
        a.setAttribute("role", "button");
        a.classList.add("secondary");
        a.onclick = function () { showNonPrime = false; closeModal() };
        a.innerText = "Don't show this again";
        openModal(
            "Could not get graph",
            `The drawn decomposition tree contains a non-prime node.
            Please ensure that all prime nodes are prime.`,
            a
        )
        return false;
    }

    return true;
};

// TODO:
// - check if tree is valid before a proof
// - that is verify the tree is connected and that each prime node is actually prime
// - if not, show a modal with the error and a link to the documentation
// - if the user clicks the link, set a cookie to not show the modal again
// - if the user clicks the close button, close the modal and do nothing
// - if the application passes, then proceed with the proof
// - on procedure, show each currently needed node type required to proceed in the selected-node-header field
// - for that we need to keep track of the current state of the proof

function handleRuleClick(cy, evt) {
    const success = rule.getGivenPath(evt.target, window.tree);
    if (success) {
        const gotNextRule = rule.nextRule();
        // flash the button green for a second to indicate success
        document.getElementById("selected-node").classList.add("success");
        setTimeout(() => {
            document.getElementById("selected-node").classList.remove("success");
        }, 200);

        if (!gotNextRule) {
            if (ruleHistory.initial === undefined) {
                ruleHistory.initial = window.tree.serialize();
            }
            window.tree = rule.applyRule();

            window.tree.render(cy);
            ruleHistory.add(rule);
            ruleHistory.render();
            applyingRule = false;
            rule = null;
            document.getElementById("selected-node-header").innerHTML = "";
        }
    }
}

function handleAi(tree) {
    if (!isValid(tree)) return;
    applyingRule = true;
    rule = new AiDown();
    rule.nextRule();
}

function handleSPar(tree) {
    if (!isValid(tree)) return;
    applyingRule = true;
    rule = new SwitchPar();
    rule.nextRule();
}

function handlePrime(tree) {
    if (!isValid(tree)) return;
    applyingRule = true;
    rule = new PrimeDown();
    rule.nextRule();
}

function handleSimplify(tree) {
    if (!isValid(tree)) return;
    applyingRule = true;
    rule = new Simplify();
    window.tree = rule.applyRule();
    ruleHistory.add(rule);
    ruleHistory.render();
    window.tree.render(cy);
}

function handleAutoPrime() {
    if (!isValid(tree)) return;
    const auto = new Auto();
    auto.pp();

}

function handleAutoSPar() {
    if (!isValid(tree)) return;
    const auto = new Auto();
    auto.sw();
}

function handleAutoAi() {
    if (!isValid(tree)) return;
    const auto = new Auto();
    auto.ai();
}


export { handleAi, handleSPar, handlePrime, handleRuleClick, handleSimplify, handleAutoAi, handleAutoPrime, handleAutoSPar };
