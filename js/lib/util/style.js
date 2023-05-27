const style = [
    {
        selector: 'node',
        style: {
            'background-color': function (ele) {
                if (ele.selected()) {
                    return 'deepskyblue';
                }
                else {
                    return 'white';
                };
            },
            'border-color': 'black',
            'border-width': '1px',
            'label': ele => {
                let not;
                if (!ele.data('polarisation') && ele.data('polarisation') !== undefined) {
                    not = '¬';
                }
                else { not = '' };
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
        selector: '.given',
        style: {
            'background-color': 'lightgreen',
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


export { style };
