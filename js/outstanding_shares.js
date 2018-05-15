(function outstanding_shares() {

    // Find elements
    var lookup = document.querySelectorAll('#outstanding_shares_button')[0];
    var block_shares = document.querySelectorAll('#outstanding_shares')[0];

    // On button click, lookup shares
    lookup.onclick = lookup_fun;

    function lookup_fun() {
      variable_public_get(["account", 2], function(total) {
        block_shares.innerHTML = total;
      });
    }

})();
