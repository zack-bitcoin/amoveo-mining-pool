//make ip and port as input things.

local_ip = [127,0,0,1];
local_port = 8081;

// Define server, fee and min. payout
var server_ip = "159.89.106.253";
var server_port = "8080";
var pool_fee_amount = "0";
var pool_min_payout_amount = "0.5";

// Find elements
var miner_location = document.querySelectorAll('#miner_location')[0];
var pool_fee = document.querySelectorAll('#pool_fee')[0];
var pool_min_payout = document.querySelectorAll('#pool_min_payout')[0];

// Replace values in dynamic elements
miner_location.innerHTML = "http://" + server_ip + ":" + server_port;
pool_fee.innerHTML = pool_fee_amount + "%";
pool_min_payout.innerHTML = pool_min_payout_amount + " VEO";

function get_port() {
    return parseInt(server_port, 10);
}
function get_ip() {
    //return JSON.parse(server_ip.value);
    return server_ip;
}
