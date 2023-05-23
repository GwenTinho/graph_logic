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

    if (string == "^") {
        tree.addPrimeNode(mousePosition.x, mousePosition.y);
        tree.render(cy);
        return;
    }


    if (selected.length == 1 && selected[0].hasClass("before")) throw "Not implemented";

    if (selected.length == 1 && selected[0].hasClass("prime")) {
        const node = tree.getNode(selected[0].id());
        // TODO check if node is prime and if so, add a prime node
        if (node.label == "^") {
            // we give the new node the same id since it represents the same node
            node.nodeData.graph.addNode(mousePosition.x, mousePosition.y, node.id);
            // TODO think about how to model this
        }


        selected.data('label', "");
        const id_rep = new_id + "-rep";
        const barycenter = weightedBarycenter(selected[0], mousePosition.x, mousePosition.y);
        let x_coord = 0.6 * barycenter.x + 0.4 * mousePosition.x;
        let y_coord = 0.6 * barycenter.y + 0.4 * mousePosition.y;
        if (!selected.isParent()) {
            x_coord = selected.renderedPosition().x;
            y_coord = selected.renderedPosition().y;
        };
        const rep_node = {
            group: 'nodes',
            data: {
                id: id_rep,
                label: "",
                parent: selected[0].id(),
            },
            renderedPosition: {
                x: x_coord,
                y: y_coord,
            },
        };
        const added_rep = cy.add(rep_node);
        added_rep.addClass('inCompound');

        const rep_edge = {
            data: {
                source: id_rep,
                target: new_id,
            },
        };
        const added_rep_edge = cy.add(rep_edge);
        added_rep_edge.addClass('compoundOut');
    }

    tree.addNode(string, mousePosition.x, mousePosition.y, true);
    tree.render(cy);


}






export { handleKeyPress };
