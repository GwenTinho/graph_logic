import { handleClick } from "./lib/handlers/clickHandler.js";
import { cleanLayout, duplicateHandler, exportProof, exportTree, handleClear, undo } from "./lib/util/helper.js";
import { handleKeyPress } from "./lib/handlers/keypressHandler.js";
import { handleAi, handleAutoAi, handleAutoPrime, handleAutoSPar, handlePrime, handleRuleClick, handleSPar, handleSimplify } from "./lib/handlers/ruleHandlers.js";
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

    document.getElementById('upload-proof').addEventListener('change', async evt => {
        try {
            let content = await evt?.target?.files[0]?.text();
            RuleHistory.fromJson(content);
            window.tree.render(cy);
            window.ruleHistory.render();
            cleanLayout(cy);
        }
        catch (err) {
            console.error(err);
        }
    });
});

// Toggle the dropdown menu
document.querySelector(".dropbtn").addEventListener("click", function () {
    document.querySelector(".dropdown-content").classList.toggle("show");
});

// Close the dropdown menu if the user clicks outside of it
window.addEventListener("click", function (event) {
    if (!event.target.matches(".dropbtn")) {
        const dropdowns = document.querySelectorAll(".dropdown-content");
        for (let i = 0; i < dropdowns.length; i++) {
            const dropdown = dropdowns[i];
            if (dropdown.classList.contains("show")) {
                dropdown.classList.remove("show");
            }
        }
    }
});


const cy_div = document.getElementById('cy');
cy_div.addEventListener("mouseleave", evt => {
    isMouseOver = false;
});
cy_div.addEventListener("mouseover", evt => {
    isMouseOver = true;
});

document.addEventListener('keydown', evt => {

    if (evt.key == "Delete") {
        evt.preventDefault();
        handleClear();
        return;
    }

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

document.getElementById("download").addEventListener("click", evt => exportTree());
document.getElementById("export-proof").addEventListener("click", evt => exportProof());
document.getElementById("import-proof").addEventListener("click", evt => {
    document.getElementById('upload-proof').click();
});
document.getElementById("verify").addEventListener("click", evt => {
    const verifies = ruleHistory.verify();
    if (verifies) {
        alert("The proof is correct!");
    }
    else {
        alert("The proof is incorrect!");
    }
});
document.getElementById("undo").addEventListener("click", evt => undo(cy));
document.getElementById("clear").addEventListener("click", evt => handleClear());
document.getElementById("center").addEventListener("click", evt => cleanLayout(cy));
document.getElementById("import").addEventListener("click", evt => {
    document.getElementById('upload').click();
});

document.getElementById("duplicate").addEventListener("click", evt => duplicateHandler(cy, tree));

document.getElementById("simplify").addEventListener("click", evt => handleSimplify(tree));


document.getElementById("ai").addEventListener("click", evt => handleAi(tree));
document.getElementById("spar").addEventListener("click", evt => handleSPar(tree));
document.getElementById("prime").addEventListener("click", evt => handlePrime(tree));
document.getElementById("auto-ai").addEventListener("click", evt => handleAutoAi(tree));
document.getElementById("auto-spar").addEventListener("click", evt => handleAutoSPar(tree));
document.getElementById("auto-prime").addEventListener("click", evt => handleAutoPrime(tree));

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
