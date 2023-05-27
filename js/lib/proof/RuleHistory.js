class RuleHistory {
    constructor() {
        this.history = [];
    }

    add(rule, id) {
        this.history.push({
            rule,
            id
        });
    }

    getHistory() {
        return this.history;
    }

    render() {
        const table = document.getElementById("history-body");
        table.innerHTML = "";
        for (const { rule, id } of this.history) {
            const tr = document.createElement("tr");
            tr.appendChild(document.createTextNode(rule));
            // add an id into the table for now
            // but put it into the id column
            const td = document.createElement("td");
            // on show a small part of the id for now
            td.appendChild(document.createTextNode(id.slice(0, 5)));
            tr.appendChild(td);




            table.appendChild(tr);
        }
    }

    clear() {
        this.history = [];
    }
}

export default RuleHistory;
