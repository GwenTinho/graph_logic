let directed = false;

let cy1 = cytoscape({
    container: document.getElementById('cy1'),
    wheelSensitivity: 0.2,
    layout: {name: 'cose-bilkent', animate: false, idealEdgeLength: 120},
    elements: [ { data: { id: '1', label: '1', polarisation: true, } }, { data: { id: '2', label: '2', polarisation: true, } }, { data: { id: '3', label: '3', polarisation: true, } }, { data: { id: '4', label: '4', polarisation: true, } }, { data: { id: '5', label: '5', polarisation: true, } }, { data: { id: '6', label: '6', polarisation: true, } }, { data: { id: '7', label: '7', polarisation: true, } }, { data: { id: '8', label: '8', polarisation: true, } }, { data: { source: '1', target: '2', } }, { data: { source: '1', target: '8', } }, { data: { source: '1', target: '3', } }, { data: { source: '2', target: '8', } }, { data: { source: '2', target: '3', } }, { data: { source: '3', target: '4', } }, { data: { source: '3', target: '5', } }, { data: { source: '4', target: '7', } }, { data: { source: '4', target: '8', } }, { data: { source: '5', target: '7', } }, { data: { source: '5', target: '8', } }, { data: { source: '6', target: '3', } }, { data: { source: '6', target: '7', } }, { data: { source: '6', target: '8', } }, { data: { source: '7', target: '8', } }, { data: { source: '3', target: '8',} }],
    style: [
    {
        selector: 'node',
        style: {
            'background-color': function(ele) {
                if (ele.selected()) {
                    return 'deepskyblue';
                }
                else {
                    return 'white';
                };
            },
            'border-color': 'black',
            'border-width': '1px',
            'label': function(ele){
                var not;
                if(!ele.data('polarisation')) {
                    not = '¬';
                } 
                else {not = ''};
                return not + ele.data('label');
            },
            "text-valign": "center",
            "text-halign": "center",
        }
    },
        {
        selector: 'edge',
        style: {
            'width': '2px',
        }
    }]    
});
cy1.changes = [];

const undirected_stylesheet = {
    'curve-style': 'haystack',
    'control-point-step-size': 0,
    'target-arrow-shape': 'none',
};

const directed_stylesheet = {
    'curve-style': 'bezier',
    'control-point-step-size': 20,
    'target-arrow-shape': 'triangle',
};

function toggleDirected() {
    const stylesheet = directed ? undirected_stylesheet : directed_stylesheet;
    cy1.style().selector('edge').style(stylesheet).update();
    cy2.style().selector('.compoundIn').style(stylesheet).update();
    directed = !directed;

    const btn = document.getElementById('ditoggle');
    const disp = directed ? "undirected" : "directed";
    btn.innerText = "Make graph " + disp;
};

let mousePosition1 = {x:0, y:0};
cy1.on('mousemove', function(mouseMoveEvent){
    mousePosition1.x = mouseMoveEvent.renderedPosition.x;
    mousePosition1.y = mouseMoveEvent.renderedPosition.y;
}, false);

function getMaxId(cy) {
    let max_id = 0;
    cy.nodes().forEach(n => {
        const id = parseInt(n.id(), 10);
        if (id) {max_id = Math.max(max_id, id)};
    });
    return max_id;
};

let max_id = getMaxId(cy1);
function freshID() {
    max_id += 1;
    return max_id.toString();
}

function isAlphaNumeric(string) {
    return string.length == 1 && (/^[a-zA-Z0-9]/).test(string)
};

let isMouseOver = false;
const cy_div = document.getElementById('cy1');
cy_div.addEventListener("mouseleave", function(evt){
    isMouseOver = false;
});
cy_div.addEventListener("mouseover", function(evt){
    isMouseOver = true;
});

let isMouseOver2 = false;
const cy_div2 = document.getElementById('cy2');
cy_div2.addEventListener("mouseleave", function(evt){
    isMouseOver2 = false;
});
cy_div2.addEventListener("mouseover", function(evt){
    isMouseOver2 = true;
});

function keyPressCy1(string) {
    if (isAlphaNumeric(string)) {
        const node = {
            group: 'nodes',
            data: {
                id: freshID(),
                label: string,
                polarisation: true,
            },
            renderedPosition: {
                x : mousePosition1.x,
                y : mousePosition1.y,
            }
        };
        const added = cy1.add(node);
        cy1.changes.push(["add", added]);
        return;
    }

    if (string == "Backspace") {
        const removed = cy1.elements(':selected').remove();
        cy1.changes.push(["remove", removed]);
    }
};

document.addEventListener('keyup', function(evt) {
    evt = evt || window.event;
    const string = evt.key;
    if (isMouseOver) {keyPressCy1(string)};
    if (isMouseOver2) {keyPressCy2(string)};
});

function negate(node) {
    if (node.data('label') == "⅋") {node.data('label', "⊗"); return};
    if (node.data('label') == "⊗") {node.data('label', "⅋"); return};
    const polarisation = node.data('polarisation');
    if (typeof polarisation == undefined) {node.data('polarisation', false)}
    else {
        node.data('polarisation', !polarisation);
    };
};

cy1.on('cxttap', "node", function(evt) {
    const node = evt.target;
    if (node.selected()){
        const selected = cy1.nodes(':selected');
        for (n of selected){
            negate(n);
        }
    }
    else {
        negate(node);
    }
});

function addEdges(cy, target, selected) {
    const target_id = target.data('id');
    let to_add = [];
    for (const source of selected) {
        if (directed && (cy == cy1 ||
            (cy == cy2 && target.isChild() && selected[0].isChild()))) {
                if (source.edgesTo(target).length > 0) {continue}
        }
        else if (source.edgesWith(target).length > 0) {continue};
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

cy1.on('click', "node", function(evt){
    const node = evt.target;
    const selected = cy1.nodes(':selected');
    if (selected.length  == 0 || node.selected() || event.shiftKey) {
        return;
    }
    else {
        addEdges(cy1, node, selected);
        selected.unselect();
    };
});

function cleanLayout(cy) {
    if (cy == cy1) {
        cy.layout({
            name: 'cose-bilkent',
            animate: false,
            idealEdgeLength: 120,
        }).run();
    };
    cy.center();
    cy.fit(10);
};

function undo(cy) {
    if (cy.changes.length == 0) {return};
    const [change, eles, ...rest] = cy.changes.pop();
    if (change == "add") {
        eles.remove();
        return;
    }
    if (change == "remove") {
        eles.restore();
        return;
    }
    if (change == "replace") {
        eles.remove();
        undo(cy);
        cleanLayout(cy);
        return;
    }
};

function serialize() {
    const nodes = cy1.nodes(':inside').jsons();
    const nodeData = nodes.map(node => { return {
        id: parseInt(node['data']['id'], 10),
        label: node['data']['label'],
        polarisation: node['data']['polarisation']
    }});
    const edges = cy1.edges(':inside').jsons();
    const edgeData = edges.map(edge => {return {
        source: parseInt(edge['data']['source'], 10),
        target: parseInt(edge['data']['target'])
    }});
    return {
        nodes: nodeData,
        edges: edgeData
    }
}

function exportGraph() {
    const a = document.createElement("a");
    const data = serialize();
    const file = new Blob([JSON.stringify(data, null, 2)], {type: "text/plain"});
    a.href = URL.createObjectURL(file);
    a.download = "graph.json";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

function exportTree() {
    const a = document.createElement("a");
    const string = getTreeJson();
    if (!string) {return}; 
    const file = new Blob([string], {type: "text/plain"});
    a.href = URL.createObjectURL(file);
    a.download = "tree.json";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

function clearGraph(cy) {
    const removed = cy.elements().remove();
    cy.changes.push(["remove", removed]);
}

function onChange(event) {
    let reader = new FileReader();
    reader.onload = onReaderLoad;
    reader.readAsText(event.target.files[0]);

}

function onReaderLoad(event) {
    const obj = JSON.parse(event.target.result);
    const nodes = obj['nodes'];
    const nodes_obj = nodes.map(node => {
        return {group: 'nodes', data: node}
    });
    const edges = obj['edges'];
    const edges_obj = edges.map(edge => {
        return {group: 'edges', data: edge}
    });
    clearGraph(cy1);
    const added_nodes = cy1.add(nodes_obj);
    const added_edges = cy1.add(edges_obj);
    const eles = added_nodes.union(added_edges);
    cy1.changes.push(["replace", eles]);
    cleanLayout(cy1);
}

document.addEventListener("DOMContentLoaded", function(event) {
    document.getElementById('upload').addEventListener('change', onChange);
});

function changeEleId(cy, ogid, newid) {
    const ele = cy.$id(ogid);
    if (ele.group() == "edges") {
        const new_ele = {
            id: newid,
            source: ele.source(),
            target: ele.target
        };
        cy.batch(function(){
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
        if (typeof polarisation !== undefined) {new_ele.data.polarisation = polarisation};
        if (ele.isChild()) {new_ele.data.parent = ele.data('parent')};
        cy.batch(function(){
            const removed = cy.remove(ele);
            const added = cy.add(new_ele);
            added.classes(ele.classes());
            added.renderedPosition(ele.renderedPosition());
            const edges = removed.edges();
            edges.map(e => {
                let src;
                let tgt;
                if (e.data('source') == ogid) {src = newid} else {src = e.data('source')};
                if (e.data('target') == ogid) {tgt = newid} else {tgt = e.data('target')};
                const new_edge = {
                    group: 'edges',
                    data: {id: e.id(), source: src, target: tgt},
                };
                const added = cy.add(new_edge);
                added.classes(e.classes());
            });
        });
    }
}

let cy2 = cytoscape({
    container: document.getElementById('cy2'),
    wheelSensitivity: 0.2,
    style: [
    {
        selector: 'node',
        style: {
            'background-color': function(ele) {
                if (ele.selected()) {
                    return 'deepskyblue';
                }
                else {
                    return 'white';
                };
            },
            'border-color': 'black',
            'border-width': '1px',
            'label': function(ele){
                var not;
                if(!ele.data('polarisation') && ele.data('polarisation') !== undefined) {
                    not = '¬';
                } 
                else {not = ''};
                return not + ele.data('label');
            },
            "text-valign": "center",
            "text-halign": "center",
        }
    },
    {
        selector: 'edge',
        style: {
            'width': '2px',
            'curve-style': 'straight',
            'target-arrow-shape': 'triangle',
        }
    },
    {
        selector: '.compoundOut',
        style: {
            'line-style': 'dashed',
        }
    },
    {
        selector: '.compoundIn',
        style: {
            'curve-style': 'haystack',
            'line-color': '#888888'
        }
    },
    {
        selector: '.inCompound',
        style: {
            'background-color': '#888888',
            'border-color': '#888888',
        }
    },
    {
        selector: ':parent',
        style: {
            'shape': 'roundrectangle',
            'background-color': '#BBBBBB',
            'border-color': '#666666',
            'border-width': '1px',
        }
    },
    {
        selector: '.root',
        style: {
            'border-color': 'cornflowerblue',
            'border-width': '2px',
        }
    },
    {
        selector: ':selected',
        style: {
            'background-color': 'deepskyblue',
            'line-color': '#2B65EC',
        }
    },
    {
        selector: '.before',
        style: {
            'line-color': 'green',
            'curve-style': 'straight',
            'target-arrow-shape': 'triangle',
            'target-arrow-color': 'green',
        }
    }]    
});
cy2.changes = [];

let mousePosition2 = {x:0, y:0};
cy2.on('mousemove', function(mouseMoveEvent){
    mousePosition2.x = mouseMoveEvent.renderedPosition.x;
    mousePosition2.y = mouseMoveEvent.renderedPosition.y;
}, false);

function weightedBarycenter(parent, x, y) {
    const children = parent.children();
    const distances = children.map(c => {
        const cx = c.renderedPosition().x;
        const dx = cx - x;
        const cy = c.renderedPosition().y;
        const dy = cy - y;
        return Math.sqrt(dx*dx + dy*dy);
    });
    const max = Math.max(...distances);
    const temp_weights = distances.map(d => {return max/d});
    const total = temp_weights.reduce((acc, w) => acc + w, 0);
    const weights = temp_weights.map(d => {return d/total});
    const barycenter = children.reduce((acc, c, i) => {
        const w = weights[i];
        const pos = c.renderedPosition();
        const x = pos.x*w;
        const y = pos.y*w;
        return {x : acc.x + x, y : acc.y + y}
    }, {x: 0, y: 0});
    return barycenter;
}

function keyPressCy2(string) {
    if (isAlphaNumeric(string) || string == "&" || string == "*" || string == "^" || string == ">") {
        let label, class_;
        if (string == "&") {label = "⅋"; class_ = "par";} else
        if (string == "*") {label = "⊗"; class_ = "tensor"} else
        if (string == "^") {label = "prime"; class_ = "prime"} else
        if (string == ">") {label = "before"; class_ = "before"} else
        {label = string; class_ = "atom"};
        const new_id = freshID2();
        const node = {
            group: 'nodes',
            data: {
                id: new_id,
                label: label,
                polarisation: true,
            },
            renderedPosition: {
                x : mousePosition2.x,
                y : mousePosition2.y,
            },
        };
        const firstNode = cy2.nodes().empty();
        const added = cy2.add(node);
        added.addClass(class_);
        cy2.changes.push(["add", added]);

        if (firstNode) {added.addClass("root")};
        
        const selected = cy2.nodes(':selected');
        if (selected.length == 1 && (selected[0].hasClass("prime") || selected[0].hasClass("before"))) {
            selected.data('label', "");
            const id_rep = new_id + "-rep";
            const barycenter = weightedBarycenter(selected[0], mousePosition2.x, mousePosition2.y);
            let x_coord = 0.6 * barycenter.x + 0.4 * mousePosition2.x;
            let y_coord = 0.6 * barycenter.y + 0.4 * mousePosition2.y;
            if (!selected.isParent()) {
                x_coord = selected.renderedPosition().x;
                y_coord = selected.renderedPosition().y;
                console.log(x_coord);
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
            const added_rep = cy2.add(rep_node);
            added_rep.addClass('inCompound');

            const rep_edge = {
                data: {
                    source: id_rep,
                    target: new_id,
                },
            };
            const added_rep_edge = cy2.add(rep_edge);
            added_rep_edge.addClass('compoundOut');
        }
        return;
    }

    if (string == "Backspace") {
        const removed = cy2.elements(':selected').remove();
        cy2.changes.push(["remove", removed]);
    }
}

let max_id2 = getMaxId(cy2);
function freshID2() {
    max_id2 += 1;
    return max_id2.toString();
}

function getBeforeRoot(node) {
    const pred = node.predecessors().nodes()[0];
    if (pred) {return getBeforeRoot(pred)} 
    else {return node};
};

function getRoot(node) {
    if (node.isChild()) {return getRoot(node.parent())};
    const pred = node.predecessors().nodes()[0];
    if (pred) {return getRoot(pred)}
    else {return node};
};

cy2.on('click', "node", function(evt){
    const target = evt.target;

    let selected = cy2.nodes(':selected');
    // If there isn't exactly once selected node, do nothing
    if (selected.length != 1 || target.selected() || event.shiftKey) {return};

    const source = selected[0];
    // If source is an atom do nothing
    if (isAlphaNumeric(source.data('label'))) {return};

    let classes = [];

    if (source.isChild()) {
        if (target.isChild()) {
            // if they share the same parent, make the edge an inner edge, otherwise do nothing
            if (target.data('parent') != source.data('parent')) {return};
            classes.push('compoundIn');

            if (source.parent().hasClass("before")) {
                if (target.successors()['+'](target).intersection(source.successors()['+'](source)).nonempty()) {return};
                classes.push("before"); 
                const root = getBeforeRoot(source);
                source.parent().children().removeClass("before-root");
                root.addClass("before-root");
            };
        } 
        // If the target is not a child, make the edge an outward edge and make the source a representative of the target
        else {
            if (source.outgoers().nonempty()) {return};
            classes.push('compoundOut');
            const new_source_id = target.id() + "-rep";
            changeEleId(cy2, source.id(), new_source_id);
            selected = [cy2.$id(new_source_id)];
        };

        // If the edge points from a child to its parent, do nothing
        if (target.id() == source.data('parent')) {return};
    }
    else {
        // If the target is a child and the source is not a child, do nothing
        if (target.isChild()) {return};

        // If the target already has an incoming edge, do nothing
        if (target.incomers().nonempty()) {return};

        if (target.successors()['+'](target).intersection(source.successors()['+'](source)).nonempty()) {return};

        if (source.hasClass("prime") || source.hasClass("before")) {
            if (target.hasClass("root")) {target.removeClass("root"); getRoot(source).addClass("root")};
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
            const added_rep = cy2.add(rep_node);
            added_rep.addClass('inCompound');
            source.data("label", "");

            const rep_edge = {
                data: {
                    source: id_rep,
                    target: target.id(),
                },
            };
            const added_rep_edge = cy2.add(rep_edge);
            added_rep_edge.addClass('compoundOut');

            if (source.hasClass("before")) {
                added_rep.addClass("before");
                if (target.successors()['+'](target).intersection(source.successors()['+'](source)).nonempty()) {return};
                const root = getBeforeRoot(source);
                source.parent().children().removeClass("before-root");
                root.addClass("before-root");
            }
            return;
        };
    };

    if (!source.isChild() && !target.isChild()) {
        const root = getRoot(source);
        cy2.elements().removeClass("root");
        root.addClass("root");
    };

    cy2.batch(function() {
    const added = addEdges(cy2, target, selected)[0];
    if (added) {added.addClass(classes)};
    cy2.nodes(":selected").unselect();
    });
});

cy2.on('dblclick', "node", function(evt){
    cy2.nodes().removeClass('root');
    evt.target.addClass('root');
    evt.target.unselect();
    return;
});

cy2.on('cxttap', "node", function(evt) {
    const node = evt.target;
    if (node.selected()){
        const selected = cy2.nodes(':selected');
        for (n of selected){
            negate(n);
        }
    }
    else {
        negate(node);
    }
});

function connectedTo(root) {
    let suc;
    if (root.isParent()) {
        const children = suc = root.children()
        suc = children.successors()['u'](children);
    }
    else {suc = root.successors()};
    const parents = suc.nodes("$node > node");
    const parent_suc = parents.reduce(
        (acc, parent) => acc.union(connectedTo(parent)),
        cy2.collection()
    );
    return suc.union(parent_suc);
}

function checkConnected() {
    const root = cy2.nodes('.root');
    const reachable = connectedTo(root)['+'](root);
    const unreachable = reachable.complement();
    return unreachable.empty();
}

function checkPrime() {
    const parents = cy2.nodes('.prime');
    return parents.reduce(
        (acc, parent) => {
            if (acc) {
                const children = parent.children();
                const graph = children.union(children.connectedEdges('.compoundIn'));
                return isPrime(graph);
            }
            else {return false};
        },
        true
    );
};

function getGraph() {
    if (checkConnected()) {
        recompose();
    }
    else if (showNonConnected) {
        const a = document.createElement("a");
        a.href = "#dontsee";
        a.id = "dontsee";
        a.setAttribute("role", "button");
        a.classList.add("secondary");
        a.onclick = function(){showNonConnected = false; closeModal()};
        a.innerText = "Don't show this again";
        openModal(
            "Could not get graph",
            `The drawn decomposition tree is not connected.
            Please ensure that all nodes are connected to the root (select a root by double clicking a node).`,
            a
        )
    }
};