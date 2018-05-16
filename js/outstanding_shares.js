(function outstanding_shares() {

    // Find elements
    var lookup = document.getElementById('outstanding_shares_button');
    var block_shares = document.getElementById('outstanding_shares');

    // On button click, lookup shares
    lookup.onclick = lookup_fun;

    function lookup_fun() {
      variable_public_get(["account", 2], function(total) {
        block_shares.innerHTML = total;
      });
    }

})();
