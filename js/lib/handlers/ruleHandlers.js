const history = [];

// check if tree is valid before a proof TODO
function isValid(tree) {
    if (!tree.isConnected()) {
        const a = document.createElement("a");
        a.href = "#dontsee";
        a.id = "dontsee";
        a.setAttribute("role", "button");
        a.classList.add("secondary");
        a.onclick = function () { showNonConnected = false; closeModal() };
        a.innerText = "Don't show this again";
        openModal(
            "Could not get graph",
            `The drawn decomposition tree is not connected.
            Please ensure that all nodes are connected to the root (select a root by double clicking a node).`,
            a
        )
        return false;
    }
    return true;
};

function handleAi(tree) {
    if (!isValid(tree)) return;
    // TODO
}

function handleSPar(tree) {
    if (!isValid(tree)) return;
    history.push("spar");
    const ul = document.getElementById("history");
    const li = document.createElement("li");
    li.appendChild(document.createTextNode("spar"));
    ul.appendChild(li);
}

function handlePrime(tree) {
    if (!isValid(tree)) return;
    history.push("prime");
    const ul = document.getElementById("history");
    const li = document.createElement("li");
    li.appendChild(document.createTextNode("prime"));
    ul.appendChild(li);
}

function handleApply(tree) {



}

export { handleAi, handleSPar, handlePrime, handleApply };