import { isAlphaNumeric, weightedBarycenter } from "../util/helper.js";


function changeEleId(cy, ogid, newid) {
    const ele = cy.$id(ogid);
    if (ele.group() == "edges") {
        const new_ele = {
            id: newid,
            source: ele.source(),
            target: ele.target
        };
        cy.batch(() => {
            cy.remove(ele);
            const added = cy.add(new_ele);
            added.classes(ele.classes());
        });
    };
    if (ele.group() == "nodes") {
        const new_ele = {
            group: 'nodes',
            data: {
                id: newid,
                label: ele.data('label'),
            }
        };
        const polarisation = ele.data('polarisation');
        if (typeof polarisation !== undefined) { new_ele.data.polarisation = polarisation };
        if (ele.isChild()) { new_ele.data.parent = ele.data('parent') };
        cy.batch(() => {
            const removed = cy.remove(ele);
            const added = cy.add(new_ele);
            added.classes(ele.classes());
            added.renderedPosition(ele.renderedPosition());
            const edges = removed.edges();
            edges.map(e => {
                let src;
                let tgt;
                if (e.data('source') == ogid) { src = newid } else { src = e.data('source') };
                if (e.data('target') == ogid) { tgt = newid } else { tgt = e.data('target') };
                const new_edge = {
                    group: 'edges',
                    data: { id: e.id(), source: src, target: tgt },
                };
                const added = cy.add(new_edge);
                added.classes(e.classes());
            });
        });
    }
}

function handleClick(cy, tree, evt) {
    console.log("click");

    const target = evt.target;

    let selected = cy.nodes(':selected');
    // If there isn't exactly once selected node, do nothing
    if (selected.length != 1 || target.selected() || event.shiftKey) return;

    const source = selected[0];

    // If source is an atom do nothing
    if (isAlphaNumeric(source.data('label'))) return;

    let classes = [];

    if (source.isChild()) {
        if (target.isChild()) {
            // if they share the same parent, make the edge an inner edge, otherwise do nothing
            if (target.data('parent') != source.data('parent')) return;
            classes.push('compoundIn');

            // ID Graph Code goes here TODO

            if (source.parent().hasClass("before")) {
                throw "Not implemented yet";
            };
        }
        // If the target is not a child, make the edge an outward edge and make the source a representative of the target
        else {
            if (source.outgoers().nonempty()) return;
            classes.push('compoundOut');
            const new_source_id = target.id() + "-rep";
            changeEleId(cy, source.id(), new_source_id);
            selected = [cy.$id(new_source_id)];
        };

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

        if (source.hasClass("prime")) { // TODO rework this
            const id_rep = target.id() + "-rep";
            const barycenter = weightedBarycenter(source, target.renderedPosition().x, target.renderedPosition().y);
            let x_coord = 0.6 * barycenter.x + 0.4 * target.renderedPosition().x;
            let y_coord = 0.6 * barycenter.y + 0.4 * target.renderedPosition().y;
            if (!source.isParent()) {
                x_coord = source.renderedPosition().x;
                y_coord = source.renderedPosition().y;
            }
            const rep_node = {
                group: 'nodes',
                data: {
                    id: id_rep,
                    label: "",
                    parent: source.id(),
                },
                renderedPosition: {
                    x: x_coord,
                    y: y_coord,
                },
            };
            const added_rep = cy.add(rep_node);
            added_rep.addClass('inCompound');
            source.data("label", "");

            const rep_edge = {
                data: {
                    source: id_rep,
                    target: target.id(),
                },
            };
            const added_rep_edge = cy.add(rep_edge);
            added_rep_edge.addClass('compoundOut');
        };
    };

    if (!source.isChild() && !target.isChild()) {
        cy.elements().removeClass("root");
    };

    cy.batch(() => {
        tree.connectRoots(source.id(), target.id());
        tree.render(cy);
        //if (added) { added.addClass(classes) };
        source.unselect();
        target.unselect();
    });
}

export { handleClick };
