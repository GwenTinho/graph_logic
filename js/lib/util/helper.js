import Tree from "../tree/Tree.js";

function isAlphaNumeric(string) {
    return string.length == 1 && (/^[a-zA-Z0-9]/).test(string)
};

function isValidLabel(label) {
    return isAlphaNumeric(label) || label == "&" || label == "*" || label == "^" || label == ">";
}


function undo(cy) {
    // TODO: undo rule application
    // TODO: undo tree manipulation
};

function exportTree() {
    if (!window.tree.isConnected()) return;
    const a = document.createElement("a");
    const string = JSON.stringify(tree.serialize());
    if (!string) { return };
    const file = new Blob([string], { type: "text/plain" });
    a.href = URL.createObjectURL(file);
    a.download = "tree.json";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

function updateProofMode(isProofMode) {
    const proofModeIcon = document.getElementById('proof-mode-icon');

    if (isProofMode) {
        proofModeIcon.classList.remove('ph-lock-simple-open');
        proofModeIcon.classList.add('ph-lock-simple'); // replace with your 'proof mode on' icon
    } else {
        proofModeIcon.classList.remove('ph-lock-simple');
        proofModeIcon.classList.add('ph-lock-simple-open'); // replace with your 'proof mode off' icon
    }
}

function exportProof() {
    if (!window.tree.isConnected() || !window.tree.isAllPrime()) return;
    const a = document.createElement("a");
    const proof = window.ruleHistory.serialize();
    const string = JSON.stringify(proof);
    if (!string) { return };
    const file = new Blob([string], { type: "text/plain" });
    a.href = URL.createObjectURL(file);
    a.download = "proof.json";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);

}

function clearGraph(cy) {
    cy.elements().remove();
}

function cleanLayout(cy) {
    cy.layout({
        name: 'breadthfirst',
        animate: false,
        idealEdgeLength: 120,
        directed: true,
        roots: cy.nodes().roots(),
    }).run();
    cy.center();
    cy.fit(10);
};

function duplicateHandler(cy, tree) {
    const selected = cy.nodes(':selected');
    if (selected.length === 1) {
        tree.duplicate(selected[0].id());
        tree.render(cy);
    }
}

function handleClear() {
    clearGraph(cy);
    window.applyingRule = false;
    window.rule = null;
    window.tree = new Tree();
    document.getElementById("selected-node-header").innerHTML = "";
    window.ruleHistory.clear();
    window.ruleHistory.render();
}


export { undo, cleanLayout, clearGraph, exportTree, isAlphaNumeric, isValidLabel, duplicateHandler, exportProof, handleClear, updateProofMode };
