<?php
$servername = "mariadb101.websupport.sk";
$username = "vdj8hyl0";
$password = "dM3dyV6942";
$dbname = "vdj8hyl0";
$serverport = "3312";

# Create connection
$conn = mysqli_connect($servername, $username, $password, $dbname, $serverport);

# Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$last_pvl = explode(" ", exec('rrdtool lastupdate /var/local/pvl.rrd | tail -n 1'));
$last_gbl = explode(" ", exec('rrdtool lastupdate /var/local/gbo.rrd | tail -n 1'));

$power =  $last_gbl[4] * $last_gbl[5] / 10;
$pi = $last_gbl[6] * 100;

$sql = "UPDATE last_update SET pv = $last_pvl[12], gbo = $power, pi = $pi";
$result = $conn->query($sql);

$conn->close();
?>
