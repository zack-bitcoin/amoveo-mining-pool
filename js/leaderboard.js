(function(){
    //todo. use {accounts} to download the accounts from the mining pool, display them neatly. 
    //document.body.appendChild(document.createElement("br"));
    //document.body.appendChild(document.createElement("br"));

    var leaders = document.createElement("div");
    document.body.appendChild(leaders);

    variable_public_get(["accounts"], make_leaderboard);
    function make_leaderboard(accs){
        var a2 = understand_leaders(accs.slice(1));
        console.log(JSON.stringify(a2));
        return(display_leaders(a2));
    };
    function display_leaders(l) {
        if(l.length === 0) {
            return(0);
        } else {
            var pub = l[0][0];
            var share_rate = l[0][1];
            var l2 = l.slice(1);
            var p = document.createElement("p");
            p.innerHTML = "pub: " + pub + " shares/hour: " + share_rate.toString();
            leaders.appendChild(p);
            return(display_leaders(l.slice(1)));
        };
    };
    function understand_leaders(l) {
        if(l.length === 0) {
            return([]);
        } else {
            var r = understand_leaders(l.slice(1));
            var s = [l[0].slice(1)].concat(r);
            return(s);
        };
    };
})();
