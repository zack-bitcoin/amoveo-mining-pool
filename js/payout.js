(function payout() {
    document.body.appendChild(document.createElement("br"));
    var div = document.createElement("div");
    document.body.appendChild(div);

    var button = document.createElement("input");
    button.type = "button";
    button.value = "generate unsigned request";
    button.onclick = generate_unsigned_request;
    var unsigned_div = document.createElement("div");
    var button2 = document.createElement("input");
    button2.type = "button";
    button2.value = "publish signed request";
    button2.onclick = publish_signed_request;
    var signed = document.createElement("input");
    signed.type = "text";

    div.appendChild(button);
    div.appendChild(unsigned_div);
    div.appendChild(button2);
    div.appendChild(signed);

    function generate_unsigned_request(){
	//request height from the full node
	variable_public_get(["height"], function(x) {
	    var request = [-7, 27, pubkey.value, x];
	    unsigned_div.innerHTML = JSON.stringify(request);
	});
    };
    function publish_signed_request(){
	var sr = JSON.parse(signed.value);
	variable_public_get(["spend", sr], function(x) {
	    console.log("publish signed request");
	});
    };
})();
