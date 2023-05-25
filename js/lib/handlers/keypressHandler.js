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

    const selected = cy.nodes(':selected');



    if (selected.length == 1 && selected[0].hasClass("before")) throw "Not implemented";

    if (selected.length == 1 && selected[0].hasClass("prime")) {
        const addedId = tree.addNode(string, mousePosition.x, mousePosition.y, true); // check here

        tree.connectRootToNode(selected[0].id(), addedId);

        console.log(selected[0].id())

        tree.render(cy);
        return;
    }

    tree.addNode(string, mousePosition.x, mousePosition.y, true);
    tree.render(cy);




}






export { handleKeyPress };
