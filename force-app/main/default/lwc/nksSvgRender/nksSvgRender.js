import { LightningElement, api, track } from 'lwc';
import emoji1 from './templates/emoji1.html';
import emoji2 from './templates/emoji2.html';
import emoji3 from './templates/emoji3.html';
import emoji4 from './templates/emoji4.html';
import emoji5 from './templates/emoji5.html';

export default class NksSvgRender extends LightningElement {
    @api name;
    @api width;
    @api height;
    @api selected = false;

    render() {
        if (this.name === 'emoji1') return emoji1;
        if (this.name === 'emoji2') return emoji2;
        if (this.name === 'emoji3') return emoji3;
        if (this.name === 'emoji4') return emoji4;
        if (this.name === 'emoji5') return emoji5;
        return null;
    }

    onMouseOver(event) {
        let selected = this.selected;
        let paths = this.template.querySelectorAll('path');
        paths.forEach(function (path) {
            path.addEventListener('mouseover', function () {
                if (selected) {
                    paths[0].style.fill = '#EEB11E';
                    paths[1].style.fill = '#F9CD18';
                } else {
                    paths[0].style.fill = '#F6C912';
                    paths[1].style.fill = '#F9D952';
                }
            });
        });
    }

    onMouseOut(event) {
        let selected = this.selected;
        let paths = this.template.querySelectorAll('path');

        paths.forEach(function (path) {
            path.addEventListener('mouseout', function () {
                if (selected) {
                    paths[0].style.fill = '#EEB11E';
                    paths[1].style.fill = '#F9CD18';
                } else {
                    paths[0].style.fill = '#F9DA57';
                    paths[1].style.fill = '#FBE981';
                }
            });
        });
    }

    onClick(event) {
        let selected = this.selected;
        let paths = this.template.querySelectorAll('path');
        paths.forEach(function (path) {
            path.addEventListener('click', function () {
                if (selected) {
                    paths[0].style.fill = '#EEB11E';
                    paths[1].style.fill = '#F9CD18';
                }
            });
        });
    }
}
