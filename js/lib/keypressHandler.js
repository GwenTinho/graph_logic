
function getMaxId(cy) {
    let max_id = 0;
    cy.nodes().forEach(n => {
        const id = parseInt(n.id(), 10);
        if (id) { max_id = Math.max(max_id, id) };
    });
    return max_id;
};

function isAlphaNumeric(string) {
    return string.length == 1 && (/^[a-zA-Z0-9]/).test(string)
};


function handleKeyPress(cy, mousePosition) {
    let max_id = getMaxId(cy);
    function freshID() {
        max_id += 1;
        return max_id.toString();
    }

    return evt => {
        const string = evt.key;
        if (isAlphaNumeric(string) || string == "&" || string == "*" || string == "^" || string == ">") {
            let label, class_;
            if (string == "&") { label = "⅋"; class_ = "par"; } else
                if (string == "*") { label = "⊗"; class_ = "tensor" } else
                    if (string == "^") { label = "prime"; class_ = "prime" } else
                        if (string == ">") { label = "before"; class_ = "before" } else { label = string; class_ = "atom" };
            const new_id = freshID();
            const node = {
                group: 'nodes',
                data: {
                    id: new_id,
                    label: label,
                    polarisation: true,
                },
                renderedPosition: {
                    x: mousePosition.x,
                    y: mousePosition.y,
                },
            };
            const firstNode = cy.nodes().empty();
            const added = cy.add(node);
            added.addClass(class_);
            cy.changes.push(["add", added]);

            if (firstNode) { added.addClass("root") };

            const selected = cy.nodes(':selected');
            if (selected.length == 1 && (selected[0].hasClass("prime") || selected[0].hasClass("before"))) {
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
            return;
        }

        if (string == "Backspace") {
            const removed = cy.elements(':selected').remove();
            cy.changes.push(["remove", removed]);
        }
    }
}

export { handleKeyPress, isAlphaNumeric };
