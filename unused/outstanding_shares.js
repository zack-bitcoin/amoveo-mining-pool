(function outstanding_shares() {
    document.body.appendChild(document.createElement("br"));
    var div = document.createElement("div");
    document.body.appendChild(div);

    var lookup = document.createElement("BUTTON");
    var lookup_text_node = document.createTextNode("lookup outstanding shares");
    lookup.appendChild(lookup_text_node);
    lookup.onclick = lookup_fun;
    var text2 = document.createElement("h8");
    div.appendChild(lookup);
    div.appendChild(text2);
    
    function lookup_fun() {
	variable_public_get(["account", 2], function(total) {
	    text2.innerHTML = "total shares: ".concat(total);
	});
    }
    
})();
