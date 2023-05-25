import { handleClick } from "./lib/handlers/clickHandler.js";
import { cleanLayout, clearGraph, exportTree } from "./lib/util/helper.js";
import { handleKeyPress } from "./lib/handlers/keypressHandler.js";
import { handleAi, handleApply, handlePrime, handleSPar } from "./lib/handlers/ruleHandlers.js";
import { style } from "./lib/util/style.js";
import Tree from "./lib/tree/Tree.js";


// Initialise global variables

window.tree = new Tree();
window.ruleHistory = [];

window.cy = cytoscape({
    container: document.getElementById('cy'),
    wheelSensitivity: 0.2,
    style: style
});

cy.changes = [];

window.mousePosition = { x: 0, y: 0 };

window.isMouseOver = false;


// Initialise event listeners

document.addEventListener("DOMContentLoaded", event => {
    document.getElementById('upload').addEventListener('change', async evt => {
        try {
            let content = await evt?.target?.files[0]?.text();
            window.tree = Tree.deserialize(JSON.parse(content));
            cleanLayout(cy);
        }
        catch (err) {
            console.error(err);
        }
    });
});


const cy_div = document.getElementById('cy');
cy_div.addEventListener("mouseleave", function (evt) {
    isMouseOver = false;
});
cy_div.addEventListener("mouseover", function (evt) {
    isMouseOver = true;
});


document.addEventListener('keyup', evt => {
    if (!isMouseOver) return;
    handleKeyPress(cy, mousePosition, tree, evt);
});

document.getElementById("download").addEventListener("click", evt => exportTree(tree));
document.getElementById("undo").addEventListener("click", evt => undo(cy));
document.getElementById("clear").addEventListener("click", evt => {
    clearGraph(cy)
    window.tree = new Tree();
});
document.getElementById("center").addEventListener("click", evt => cleanLayout(cy));
document.getElementById("import").addEventListener("click", evt => {
    document.getElementById('upload').click();
});

document.getElementById("ai").addEventListener("click", evt => handleAi(tree));
document.getElementById("spar").addEventListener("click", evt => handleSPar(tree));
document.getElementById("prime").addEventListener("click", evt => handlePrime(tree));
document.getElementById("apply").addEventListener("click", evt => handleApply(tree));

// CY EVENTS

cy.on('mousemove', mouseMoveEvent => {
    mousePosition.x = mouseMoveEvent.renderedPosition.x;
    mousePosition.y = mouseMoveEvent.renderedPosition.y;
}, false);


cy.on('click', "node", evt => {
    handleClick(cy, tree, evt);
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
        for (const n of selected) {
            tree.negate(n.id());
            n.data('polarisation', !node.data('polarisation'));
            tree.render(cy);
        }
    }
    else {
        tree.negate(node.id());
        node.data('polarisation', !node.data('polarisation'));
        tree.render(cy);
    }
});
