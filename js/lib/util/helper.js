function weightedBarycenter(parent, x, y) {
    const children = parent.children();
    const distances = children.map(c => {
        const cx = c.renderedPosition().x;
        const dx = cx - x;
        const cy = c.renderedPosition().y;
        const dy = cy - y;
        return Math.sqrt(dx * dx + dy * dy);
    });
    const max = Math.max(...distances);
    const temp_weights = distances.map(d => { return max / d });
    const total = temp_weights.reduce((acc, w) => acc + w, 0);
    const weights = temp_weights.map(d => { return d / total });
    const barycenter = children.reduce((acc, c, i) => {
        const w = weights[i];
        const pos = c.renderedPosition();
        const x = pos.x * w;
        const y = pos.y * w;
        return { x: acc.x + x, y: acc.y + y }
    }, { x: 0, y: 0 });
    return barycenter;
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
    if (change == "replace") {
        eles.remove();
        undo(cy);
        cleanLayout(cy);
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
        name: 'cose-bilkent',
        animate: false,
        idealEdgeLength: 120,
    }).run();
    cy.center();
    cy.fit(10);
};

export { weightedBarycenter, undo, cleanLayout, clearGraph, exportTree };
