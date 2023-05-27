import { isValidLabel } from "../util/helper.js";

function handleKeyPress(cy, mousePosition, tree, evt) {
    if (evt.key == "Shift") return;

    if (evt.key == "Backspace") {
        const id = cy.elements(':selected').id();
        const removed = cy.elements(':selected').remove();
        cy.changes.push(["remove", removed]);
        tree.dropNode(id);
        tree.render(cy);
        return;
    }

    const string = evt.key;

    if (!isValidLabel(string)) return;

    const selected = cy.nodes(':selected');



    if (selected.length == 1 && selected[0].hasClass("before")) throw "Not implemented";

    if (selected.length == 1 && selected[0].hasClass("prime")) {
        const addedId = tree.addNode(string, mousePosition.x, mousePosition.y, true); // check here

        tree.connectRootToNode(selected[0].id(), addedId);

        tree.render(cy);
        window.ruleHistory.clear();
        window.ruleHistory.render();
        return;
    }

    if (selected.length == 1 && (selected[0].hasClass("par") || selected[0].hasClass("tensor"))) {
        const addedId = tree.addNode(string, mousePosition.x, mousePosition.y, true);

        tree.connectRootToNode(selected[0].id(), addedId);

        tree.render(cy);
        window.ruleHistory.clear();
        window.ruleHistory.render();
        return;
    }

    tree.addNode(string, mousePosition.x, mousePosition.y, true);
    // reset rulehistory
    window.ruleHistory.clear();
    window.ruleHistory.render();

    tree.render(cy);
}






export { handleKeyPress };
