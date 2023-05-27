function isAlphaNumeric(string) {
    return string.length == 1 && (/^[a-zA-Z0-9]/).test(string)
};

function isValidLabel(label) {
    return isAlphaNumeric(label) || label == "&" || label == "*" || label == "^" || label == ">";
}


function undo(cy) { // TODO refactor
    if (cy.changes.length == 0) { return };
    const [change, eles, ...rest] = cy.changes.pop();
    if (change == "add") {
        eles.remove();
        return;
    }
    if (change == "remove") {
        eles.restore();
        return;
    }
};

function exportTree(tree) {
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

function clearGraph(cy) {
    const removed = cy.elements().remove();
    cy.changes.push(["remove", removed]);
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

export { undo, cleanLayout, clearGraph, exportTree, isAlphaNumeric, isValidLabel };
