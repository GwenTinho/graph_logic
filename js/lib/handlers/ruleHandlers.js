
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
    ruleHistory.push("ai");
    const pathAtom1 = document.getElementById("pathAtom1");
    const pathAtom2 = document.getElementById("pathAtom2");
    const pathAtom3 = document.getElementById("pathPar");
    pathAtom1.style.display = "inline-block";
    pathAtom2.style.display = "inline-block";
    pathAtom3.style.display = "inline-block";
}

function handleSPar(tree) {
    if (!isValid(tree)) return;
    ruleHistory.push("spar");
    const ul = document.getElementById("history-body");
    const li = document.createElement("tr");
    li.appendChild(document.createTextNode("spar"));
    ul.appendChild(li);
}

function handlePrime(tree) {
    if (!isValid(tree)) return;
    ruleHistory.push("prime");
    const ul = document.getElementById("history-body");
    const li = document.createElement("tr");
    li.appendChild(document.createTextNode("prime"));
    ul.appendChild(li);
}

function handleApply(tree) {



}

export { handleAi, handleSPar, handlePrime, handleApply };
