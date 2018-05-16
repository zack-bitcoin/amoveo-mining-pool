lookup_account1();
function lookup_account1() {
  // Find elements
  var lookup_account_address = document.getElementById('miner_address');
  var lookup_account_button = document.getElementById('miner_address_button');

  var miner_shares = document.getElementById('miner_shares');
  var miner_balance = document.getElementById('miner_balance');

  // On button click, lookup account
  lookup_account_button.onclick = lookup_account_helper;

  // Lookup miner address
  function lookup_account_helper() {
    var x = lookup_account_address.value;
    console.log("lookup account");
    variable_public_get(["account", x], lookup_account_helper2);
  }

  // Load miner stats
  function lookup_account_helper2(x) {
    console.log(x);
    var veo = x[2];
    var shares = x[3];

    // Replace values in dynamic elements
    miner_shares.innerHTML = shares;
    miner_balance.innerHTML = (veo / 100000000) + " VEO";
  }

}
