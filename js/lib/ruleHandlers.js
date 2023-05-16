import { connectedTo, checkConnected, negate, getRoot, getBeforeRoot, pathToRoot, checkPrime } from "./nodes.js";

const history = [];

// check if tree is valid before a proof TODO
function isValid(cy) {
    if (!checkConnected(cy)) {
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

function handleAi(cy) {
    if (!isValid(cy)) return;
    // TODO
}

function handleSPar(cy) {
    if (!isValid(cy)) return;
    history.push("spar");
    const ul = document.getElementById("history");
    const li = document.createElement("li");
    li.appendChild(document.createTextNode("spar"));
    ul.appendChild(li);
}

function handlePrime(cy) {
    if (!isValid(cy)) return;
    history.push("prime");
    const ul = document.getElementById("history");
    const li = document.createElement("li");
    li.appendChild(document.createTextNode("prime"));
    ul.appendChild(li);
}

function handleApply(cy) {



}

export { handleAi, handleSPar, handlePrime, handleApply };
