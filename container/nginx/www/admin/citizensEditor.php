<?php
include '../includes/db_sets.php';
include '../includes/db_gets.php';

echo "Citizens Editor:";
echo "<br>";

if (isset($_GET['world']))
{
	$world = $_GET['world'];
        # make the html look prettier replace spaces with new lines... this is just for ease of reading, we don't store carriage returns in the database, see below
	$currentCitizens = getCitizens($pdo,$world);
        $currentCitizens = str_replace(' ', PHP_EOL, $currentCitizens);
	print "World: $world<br>";
}


if (isset($_GET['citizens'],$_GET['world']))
{
	$citizens = $_GET['citizens'];
	$world = $_GET['world'];

	# trim and clean up new input, we don't store carriage returns in the database
	$citizens = str_replace("\r\n", " ", $citizens);
	$citizens = preg_replace('!\s+!', ' ', $citizens);

	setCitizens($pdo,$world,$citizens);
	$currentCitizens = getCitizens($pdo,$world);
	
	# make the html look prettier replace spaces with new lines... this is just for ease of reading, we don't store carriage returns in the database, see above
	$currentCitizens = str_replace(' ', PHP_EOL, $currentCitizens);

}

?>



<form action='citizensEditor.php'>
	<textarea cols='18' rows='30' name='citizens'><?php print $currentCitizens;?></textarea>
	<input type='hidden' name='world' value='<?php echo $world;?>'></input>
	<input type="submit" value="Save" class="submitButton">
</form>
