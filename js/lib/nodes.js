function connectedTo(root, cy) {
    let suc;
    if (root.isParent()) {
        const children = suc = root.children()
        suc = children.successors()['u'](children);
    }
    else { suc = root.successors() };
    const parents = suc.nodes("$node > node");
    const parent_suc = parents.reduce(
        (acc, parent) => acc.union(connectedTo(parent, cy)),
        cy.collection()
    );
    return suc.union(parent_suc);
}

function checkConnected(cy) {
    const root = cy.nodes('.root');
    const reachable = connectedTo(root, cy)['+'](root);
    const unreachable = reachable.complement();
    return unreachable.empty();
}

function checkPrime(cy) {
    const parents = cy.nodes('.prime');
    return parents.reduce(
        (acc, parent) => {
            if (acc) {
                const children = parent.children();
                const graph = children.union(children.connectedEdges('.compoundIn'));
                return isPrime(graph);
            }
            return false;
        },
        true
    );
};

function pathToRoot(node) {
    if (node.isChild()) return pathToRoot(node.parent()).concat(node);
    return [node];
}

function getBeforeRoot(node) {
    const pred = node.predecessors().nodes()[0];
    if (pred) return getBeforeRoot(pred)
    return node;
};

function getRoot(node) {
    if (node.isChild()) return getRoot(node.parent());
    const pred = node.predecessors().nodes()[0];
    if (pred) return getRoot(pred);
    return node;
};

function negate(node) {
    if (node.data('label') == "⅋") { node.data('label', "⊗"); return };
    if (node.data('label') == "⊗") { node.data('label', "⅋"); return };
    const polarisation = node.data('polarisation');
    if (typeof polarisation == undefined) { node.data('polarisation', false) }
    else {
        node.data('polarisation', !polarisation);
    };
};


function addEdges(cy, target, selected, directed) {
    const target_id = target.data('id');
    let to_add = [];
    for (const source of selected) {
        if (directed && target.isChild() && selected[0].isChild()) {
            if (source.edgesTo(target).length > 0) continue;
        }

        if (source.edgesWith(target).length > 0) continue;
        to_add.push({
            group: 'edges',
            data: {
                source: source.data('id'),
                target: target_id,
            }
        })
    }
    const added = cy.add(to_add);
    cy.changes.push(["add", added]);
    return added;
};


export { connectedTo, checkConnected, negate, getRoot, getBeforeRoot, pathToRoot, checkPrime, addEdges }
