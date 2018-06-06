var pubkey = document.createElement("INPUT");
lookup_account1();
function lookup_account1() {
    document.body.appendChild(document.createElement("br"));
    document.body.appendChild(document.createElement("br"));
    var lookup_account = document.createElement("div");
    document.body.appendChild(lookup_account);
    pubkey.setAttribute("type", "text");
    var input_info = document.createElement("h8");
    input_info.innerHTML = "pubkey: ";
    document.body.appendChild(input_info);
    document.body.appendChild(pubkey);

    var lookup_account_button = document.createElement("BUTTON");
    var lookup_account_text_node = document.createTextNode("lookup account");
    lookup_account_button.appendChild(lookup_account_text_node);
    lookup_account_button.onclick = lookup_account_helper;
    document.body.appendChild(lookup_account_button);
    function lookup_account_helper() {
        var x = pubkey.value;
	console.log("lookup account");
        variable_public_get(["account", x], lookup_account_helper2);
    }
    function lookup_account_helper2(x) {
	console.log(x);
	var veo = x[2];
	var shares = x[3];
        lookup_account.innerHTML = "veo: ".concat(veo / 100000000).concat(" shares: ").concat(shares);
    }

}
