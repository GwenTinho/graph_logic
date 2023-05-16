import { handleClick } from "./lib/clickHandler.js";
import { handleKeyPress } from "./lib/keypressHandler.js";
import { handleAi, handleApply, handlePrime, handleSPar } from "./lib/ruleHandlers.js";
import { style } from "./lib/style.js";


window.directed = false;
window.tree = {};
window.tree_str = "";
window.isMouseOver = false;
const cy_div = document.getElementById('cy');

window.cy = cytoscape({
    container: document.getElementById('cy'),
    wheelSensitivity: 0.2,
    style: style
});


cy.changes = [];

window.mousePosition = { x: 0, y: 0 };


cy_div.addEventListener("mouseleave", evt => {
    isMouseOver = false;
});
cy_div.addEventListener("mouseover", evt => {
    isMouseOver = true;
});

function updateTree() {
    tree_str = getTreeJsonGS();
    tree = JSON.parse(tree_str);
}

document.addEventListener('keyup', evt => {
    handleKeyPress(cy, mousePosition)(evt);
    updateTree();
});

document.getElementById("download").addEventListener("click", evt => exportTree());
document.getElementById("undo").addEventListener("click", evt => undo(cy));
document.getElementById("clear").addEventListener("click", evt => clearGraph(cy));
document.getElementById("center").addEventListener("click", evt => {
    cy.center();
    cy.fit(10);
});
document.getElementById("import").addEventListener("click", evt => {
    document.getElementById('upload').click();
});

const ai = document.getElementById("ai");
const spar = document.getElementById("spar");
const prime = document.getElementById("prime");
const apply = document.getElementById("apply");

ai.addEventListener("click", evt => handleAi(cy));
spar.addEventListener("click", evt => handleSPar(cy));
prime.addEventListener("click", evt => handlePrime(cy));
apply.addEventListener("click", evt => handleApply(cy));






function exportTree() {
    const a = document.createElement("a");
    updateTree();
    const string = tree_str;
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

function onChange(event) {
    let reader = new FileReader();
    reader.onload = evt => cleanLayout(cy);
    reader.readAsText(event.target.files[0]);

}

document.addEventListener("DOMContentLoaded", event => {
    document.getElementById('upload').addEventListener('change', onChange);
});


cy.on('mousemove', mouseMoveEvent => {
    mousePosition.x = mouseMoveEvent.renderedPosition.x;
    mousePosition.y = mouseMoveEvent.renderedPosition.y;
}, false);


cy.on('click', "node", evt => {
    handleClick(cy, directed)(evt);
    updateTree();
});

cy.on('dblclick', "node", evt => {
    cy.nodes().removeClass('root');
    evt.target.addClass('root');
    evt.target.unselect();
});

cy.on('cxttap', "node", evt => {
    const node = evt.target;
    if (node.selected()) {
        const selected = cy.nodes(':selected');
        for (n of selected) {
            negate(n);
        }
    }
    else {
        negate(node);
    }
    updateTree();
});
