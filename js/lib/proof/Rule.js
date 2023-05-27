class Rule {
    constructor(name, neededPaths) {
        this.name = name;
        this.neededPaths = neededPaths;
        this.givenPaths = [];
        this.currentType = "";
    }

    nextRule() {
        if (this.neededPaths.length === 0) {
            return false;
        }
        this.currentType = this.neededPaths.shift();
        document.getElementById("selected-node-header").innerHTML = this.currentType;
        return true;
    }

    enocodeId() {
        const encoder = new TextEncoder();
        const data = encoder.encode(this.name + JSON.stringify(this.givenPaths));
        return btoa(String.fromCharCode(...data));
    }

    decodeId(id) {
        const data = atob(id);
        const decoder = new TextDecoder();
        const decoded = decoder.decode(new Uint8Array([...data].map(c => c.charCodeAt(0))));
        const name = decoded.split("[")[0];
        const paths = decoded.split("[")[1].split("]")[0].split(",");
        return { name, paths };
    }

    getGivenPath(target, tree) {

        const id = target.id();
        const node = tree.getNode(id);
        // comparing strings like that is not ideal
        if (node.nodeData.class === this.currentType || this.currentType === "any") {
            const path = tree.getPath(id);

            this.givenPaths.push(path);
            target.addClass("given");
            target.unselect();
            return true;
        }
        return false;
    }

    applyRule() {
        throw new Error('applyRule not implemented in abstract class');
    }
}

export default Rule;
