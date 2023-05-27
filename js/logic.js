import { handleClick } from "./lib/handlers/clickHandler.js";
import { cleanLayout, clearGraph, duplicateHandler, exportTree, undo } from "./lib/util/helper.js";
import { handleKeyPress } from "./lib/handlers/keypressHandler.js";
import { handleAi, handlePrime, handleRuleClick, handleSPar, handleSimplify } from "./lib/handlers/ruleHandlers.js";
import { style } from "./lib/util/style.js";
import Tree from "./lib/tree/Tree.js";
import RuleHistory from "./lib/proof/RuleHistory.js";


// Initialise global variables

window.tree = new Tree();
window.ruleHistory = new RuleHistory();

window.cy = cytoscape({
    container: document.getElementById('cy'),
    wheelSensitivity: 0.2,
    style: style
});

window.directed = false;

cy.changes = [];

window.mousePosition = { x: 0, y: 0 };

window.isMouseOver = false;

// global variables for rule application
window.applyingRule = false;
window.rule = null;


// Initialise event listeners

document.addEventListener("DOMContentLoaded", event => {
    document.getElementById('upload').addEventListener('change', async evt => {
        try {
            let content = await evt?.target?.files[0]?.text();
            window.tree.addNodeFromJson(content);
            window.tree.render(cy);
            cleanLayout(cy);
        }
        catch (err) {
            console.error(err);
        }
    });
});


const cy_div = document.getElementById('cy');
cy_div.addEventListener("mouseleave", evt => {
    isMouseOver = false;
});
cy_div.addEventListener("mouseover", evt => {
    isMouseOver = true;
});

document.addEventListener('keydown', evt => {

    if (evt.ctrlKey && evt.key == "z") {
        evt.preventDefault();
        undo(cy);
        return;
    }

    if (evt.ctrlKey && evt.key == "s") {
        evt.preventDefault();
        exportTree(tree);
        return;
    }

    if (evt.ctrlKey && evt.key == "d") {
        evt.preventDefault();
        duplicateHandler(cy, tree);
        return;
    }

    if (evt.ctrlKey && evt.key == "o") {
        evt.preventDefault();
        document.getElementById('upload').click();
        return;
    }
});


document.addEventListener('keyup', evt => {
    evt.preventDefault();
    // we dont want to add nodes when the mouse is not over the cy div
    if (!isMouseOver) return;
    // we dont want to add nodes when we are applying a rule
    if (applyingRule) return;

    if (evt.ctrlKey) return;


    handleKeyPress(cy, mousePosition, tree, evt);
});

document.getElementById("download").addEventListener("click", evt => exportTree(tree));
document.getElementById("undo").addEventListener("click", evt => undo(cy));
document.getElementById("clear").addEventListener("click", evt => {
    clearGraph(cy);
    window.applyingRule = false;
    window.rule = null;
    window.tree = new Tree();
    document.getElementById("selected-node-header").innerHTML = "";
    window.ruleHistory.clear();
    window.ruleHistory.render();
});
document.getElementById("center").addEventListener("click", evt => cleanLayout(cy));
document.getElementById("import").addEventListener("click", evt => {
    document.getElementById('upload').click();
});

document.getElementById("duplicate").addEventListener("click", evt => duplicateHandler(cy, tree));

document.getElementById("simplify").addEventListener("click", evt => handleSimplify(tree));


document.getElementById("ai").addEventListener("click", evt => handleAi(tree));
document.getElementById("spar").addEventListener("click", evt => handleSPar(tree));
document.getElementById("prime").addEventListener("click", evt => handlePrime(tree));

// CY EVENTS

cy.on('mousemove', mouseMoveEvent => {
    mousePosition.x = mouseMoveEvent.renderedPosition.x;
    mousePosition.y = mouseMoveEvent.renderedPosition.y;
}, false);


cy.on('click', "node", evt => {
    // we dont want to handle clickes when the mouse is not over the cy div
    if (!isMouseOver) return;

    if (applyingRule) {
        handleRuleClick(cy, evt);
    } else {
        handleClick(cy, tree, evt);
    }
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
