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
    function exponent(a, b) {//a is type bigint. b is an int.
        if (b == 0) { return bigInt(1); }
        else if (b == 1) { return a; }
        else if ((b % 2) == 0) {return exponent(a.times(a), Math.floor(b / 2)); }
        else {return a.times(exponent(a, b-1)); }
    }
    function sci2int(x) {
        function pair2int(l) {
            var b = l.pop();
            var a = l.pop();
            var c = exponent(bigInt(2), a);//c is a bigint
	    return c.times((256 + b)).divide(256);
        }
        function sci2pair(i) {
            var a = Math.floor(i / 256);
            var b = i % 256;
            return [a, b];
        }
        return pair2int(sci2pair(x));
    }
    function lookup_account_helper2(x) {
	console.log(x);
	var veo = x[2];
	var shares = x[3];
        var shares_per_hour = x[4];
        variable_public_get_port(["height"], 8080, function(height) {
            variable_public_get_port(["header", height], 8080, function(header){
                var difficulty = header[6];
	        //var DT = header[5] - prev_header[5];
                var hashes_per_block = sci2int(difficulty);
                console.log(hashes_per_block.toJSNumber());
                console.log(sci2int(10));
//                var hashes_per_block = bigInt.max(
//                    bigInt(1),
//                    bigInt(1024).times(sci2int(difficulty)));
//                console.log(sci2int(difficulty).toJSNumber());

                //blocks_per_hour = shares_per_hour/1024;
                //hashes_per_hour = blocks_per_hour * hashes_per_block;

                var hashes_per_share = hashes_per_block.toJSNumber() / 1024;
                var hashes_per_hour = shares_per_hour * hashes_per_share;


                lookup_account.innerHTML = "veo: ".concat(veo / 100000000).concat(" shares: ").concat(shares).concat(" shares per hour: ").concat(shares_per_hour).concat(" hashes per hour: ").concat(Math.round(hashes_per_hour));
            });
        });
    }

}
