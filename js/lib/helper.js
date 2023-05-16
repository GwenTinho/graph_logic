import { directed_stylesheet, undirected_stylesheet } from "./style.js";

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

function toggleDirected() {
    const stylesheet = directed ? undirected_stylesheet : directed_stylesheet;
    cy.style().selector('.compoundIn').style(stylesheet).update();
    directed = !directed;

    const btn = document.getElementById('ditoggle');
    const disp = directed ? "undirected" : "directed";
    btn.innerText = "Make graph " + disp;
}

function undo(cy) {
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

function cleanLayout(cy) {
    cy.center();
    cy.fit(10);
};

export { weightedBarycenter, toggleDirected, undo, cleanLayout };
