var gHighLightedElements;
var curHighlightId;
function highlight (rootnode, pattern) {
	//init
	removeHighlight();
	curHighlightId = -1;
	gHighLightedElements = new Array;
	
	//highlight
	var nodelist = new Array();
	var upattern = pattern.toUpperCase();
	nodelist.push(rootnode);
	while(nodelist.length>0)
	{
		var pos;
		var node = nodelist.shift();
		if (node.nodeType == 3) {
			pos = node.data.toUpperCase().indexOf(upattern);
			if (pos >= 0) {
				var spannode = document.createElement('span');
				spannode.className = 'highlight';
				m = node.splitText(pos);
				e = m.splitText(upattern.length);
				mclone = m.cloneNode(true);
				spannode.appendChild(mclone);
				m.parentNode.replaceChild(spannode, m);
				gHighLightedElements.push(spannode);
				nodelist.unshift(e);
			};
		} else if (node.nodeType == 1 && node.childNodes && !/(script|style)/i.test(node.tagName)) {
			for (var i = node.childNodes.length - 1; i >= 0; i--){
				nodelist.unshift(node.childNodes[i]);
			};
		}
	}
	return gHighLightedElements.length;
}
function removeHighlight() {
	var nodelist = document.getElementsByTagName('span');
	for (var i = nodelist.length - 1; i >= 0; i--){
		var node = nodelist[i];
		if (node.className == 'highlight' || node.className == 'cur-highlight') {
			with (node.parentNode) {
				replaceChild(node.firstChild, node);
				normalize();
			}
		};
	};
};
function scrollToHighlight(step) {
	if(gHighLightedElements.length == 0)
		return;
	
	index = curHighlightId + step;
	
	if (index>=gHighLightedElements.length)
		index = 0;
	else if (index < 0)
		index = gHighLightedElements.length + index;
	
	var e = gHighLightedElements[index];
	e.scrollIntoView(false);
	setCurHighlight(e);
	if(curHighlightId!=-1)
		gHighLightedElements[curHighlightId].className = "highlight";
	curHighlightId = index;
};
function setCurHighlight(e) {
	e.className = "cur-highlight";
}
