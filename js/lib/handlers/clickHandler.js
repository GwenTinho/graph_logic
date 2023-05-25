import { isAlphaNumeric, weightedBarycenter } from "../util/helper.js";

function handleClick(cy, tree, evt) {
    const target = evt.target;

    let selected = cy.nodes(':selected');
    // If there isn't exactly once selected node, do nothing
    if (selected.length != 1 || target.selected() || event.shiftKey) return;

    const source = selected[0];

    // If source is an atom do nothing
    if (isAlphaNumeric(source.data('label'))) return;

    if (source.isChild()) {
        if (target.isChild()) {
            // if they share the same parent, make the edge an inner edge, otherwise do nothing
            if (target.data('parent') != source.data('parent')) return;

            const pid = target.data('parent');
            const node = tree.getNode(pid);
            if (node.nodeData.label === "prime") {
                // we parse the id to get the actual id of the node
                // since the id has the "represenative" part added to it
                node.nodeData.graph.addEdge(parseInt(source.id()), parseInt(target.id()));
                tree.render(cy);
                //if (added) { added.addClass(classes) };
                source.unselect();
                target.unselect();
                return;
            }



            if (source.parent().hasClass("before")) {
                throw "Not implemented yet";
            };
        }
        // If the target is not a child, make the edge an outward edge and make the source a representative of the target

        // If the edge points from a child to its parent, do nothing
        if (target.id() == source.data('parent')) return;
    }
    else {
        // If the target is a child and the source is not a child, do nothing
        if (target.isChild()) return;

        // If the target already has an incoming edge, do nothing
        if (target.incomers().nonempty()) return;

        if (target.successors()['+'](target).intersection(source.successors()['+'](source)).nonempty()) return;

        if (source.hasClass("before")) {
            // not implemented yet TODO
            return;
        };

        if (source.hasClass("prime")) {
            // TODO rework this
        };
    };

    if (!source.isChild() && !target.isChild()) {
        cy.elements().removeClass("root");
    };

    cy.batch(() => {
        tree.connectRootToNode(source.id(), target.id());
        tree.render(cy);
        //if (added) { added.addClass(classes) };
        source.unselect();
        target.unselect();
    });
}

export { handleClick };
