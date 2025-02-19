dofile("common.inc");
dofile("settings.inc");


dropdown_values_canopy = {"Night - Canopy Ignored (0)", "Day - Canopy Closed (33)", "Day - Canopy Open (99)"};
per_click_delay = 0;
grid_mode = false; -- Expects windows to be pinned in a Grid
screenshot_test_mode = false; -- Take a screenshot of game at Ticks 9,19,29,39. Useful when Testing Voids. Saves .png's to c:\games\Automato folder
window_locs = {};
button_names = {"ThistleNit.png", "ThistlePot.png", "ThistleH2O.png", "ThistleOxy.png", "ThistleSun.png"};

function setWaitSpot(x0, y0)
	setWaitSpot_x = x0;
	setWaitSpot_y = y0;
	setWaitSpot_px = srReadPixel(x0, y0);
end

function waitForChange()
	local c=0;
	while srReadPixel(setWaitSpot_x, setWaitSpot_y) == setWaitSpot_px do
		lsSleep(1);
		c = c+1;
		if (lsShiftHeld() and lsControlHeld()) then
			error 'broke out of loop from Shift+Ctrl';
		end
	end
	lsPrintln('Waited ' .. c .. 'ms for pixel to change.');
end

function clickAll(image_name, message, up)
	if not message then
		message = "";
	end
	-- Find buttons and click them!
	srReadScreen();
	local buttons = findAllImages(image_name);

	if #buttons == 0 then
		statusScreen("Could not find specified buttons...", nil, nil, 0.7);
		lsSleep(1500);
	else
		statusScreen(message .. " Clicking " .. #buttons .. " button(s)...", nil, nil, 0.7);
		if up then
			for i=#buttons, 1, -1  do
				srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
				lsSleep(per_click_delay);
			end
		else
			for i=1, #buttons  do
				srClickMouseNoMove(buttons[i][0]+5, buttons[i][1]+3);
				lsSleep(per_click_delay);
			end
		end
		lsSleep(100);
	end
end

function clickAllComplex(image_names, message)
	if not message then
		message = "";
	end
	-- Find buttons and click them!
	srReadScreen();
	window_locs = findAllImages(thisImage);
	if #window_locs == 0 then
	  sleepWithStatus(1000, "No windows found");
	  thistleConfig();
	end
	local dpos = {};
	for i=1, #image_names do
		local pos = srFindImageInRange(image_names[i],
			window_locs[#window_locs][0]-125, window_locs[#window_locs][1],
			410, 312);
		if not pos then
			error ('Failed to find ' .. image_names[i]);
		end
		dpos[i] = {};
		dpos[i][0] = pos[0] - window_locs[#window_locs][0];
		dpos[i][1] = pos[1] - window_locs[#window_locs][1];
	end
	statusScreen(message .. " Clicking " .. #window_locs .. " button(s)...", nil, nil, 0.7);
	local first = 1;
	for i=#window_locs, 1, -1 do
		if not first then
			-- focus
			setWaitSpot(window_locs[i+1][0], window_locs[i+1][1]);
			srClickMouseNoMove(window_locs[i][0], window_locs[i][1]);
			waitForChange();
		end
		-- click all buttons
		for j=1, #image_names do
			srClickMouseNoMove(window_locs[i][0] + dpos[j][0] + 5, window_locs[i][1] + dpos[j][1] + 5);
		end
		first = nil;
	end
	lsSleep(100);
	statusScreen(message .. " Refocusing...", nil, nil, 0.7);
	-- refocus
	for i=2, #window_locs do
		setWaitSpot(window_locs[i][0], window_locs[i][1]);
		srClickMouseNoMove(window_locs[i][0], window_locs[i][1] + 275);
		waitForChange();
	end
	lsSleep(100);
end

local z = 2;

-- Initialize last_mon
local mon_w = 10;
local mon_h = 152;
local last_mon = {};
for x=1, mon_w do
	last_mon[x] = {};
	for y=1, mon_h do
		last_mon[x][y] = 0;
	end
end

function waitForMonChange(message)
	if not first_nit then
		first_nit = srFindImage("thistle/ThistleNit.png");
	end
	if not first_nit then
		error "Could not find first Nit";
	end
	mon_x = first_nit[0] - 25;
	mon_y = first_nit[1] + 13;

	local different = nil;
	local skip_next = nil;
	local first_loop = 1;
	while not different do
		srReadScreen();
		for x=1, mon_w do
			for y=1, mon_h do
				newvalue = srReadPixelFromBuffer(mon_x + x, mon_y + y);
				if not (newvalue == last_mon[x][y]) then
					different = 1;
				end
				last_mon[x][y] = newvalue;
			end
		end
		if not different then
			first_loop = nil;
		end

		if different then
			-- Make sure the screen was done refreshing and update again
			lsSleep(60);
			srReadScreen();
			for x=1, mon_w do
				for y=1, mon_h do
					last_mon[x][y] = srReadPixelFromBuffer(mon_x + x, mon_y + y);
				end
			end
		end

		if (different and skip_next) then
			skip_next = nil;
			different = nil;
		end

		lsPrintWrapped(10, 5, 0, lsScreenX - 20, 0.8, 0.8, 0xFFFFFFff, message);
		lsPrintWrapped(10, 35, 0, lsScreenX - 20, 0.7, 0.7, 0xFFFFFFff, "Elapsed Time: " .. getElapsedTime(startTime));
		lsPrintWrapped(10, 60, 0, lsScreenX - 20, 0.8, 0.8, 0xFFFFFFff, "Waiting for change...");
		if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff, "End script") then
			error "Clicked End Script button";
		end

		if lsButtonText(40, lsScreenY - 60, z, 200, 0xFFFFFFff, "Force tick") then
			different = 1;
		end

		if lsButtonText(40, lsScreenY - 90, z, 200, 0xFFFFFFff, "Skip tick") then
			skip_next = 1;
		end

		if abort then
			if lsButtonText(40, lsScreenY - 150, z, 200, 0xff4040ff, "Cancel Abort") then
				abort = nil;
			end

		else

			if lsButtonText(40, lsScreenY - 150, z, 200, 0xFFFFFFff, "Abort Crops") then
				abort = 1;
			end

		end

		if finish_up then
			if lsButtonText(40, lsScreenY - 120, z, 200, 0x40ff40ff, "Cancel Finish Up") then
				finish_up = nil;
			end

		else

			if lsButtonText(40, lsScreenY - 120, z, 200, 0xFFFFFFff, "Finish up") then
				finish_up = 1;
			end

		end

		-- display mon pixels
		for x=1, mon_w do
			for y=1, mon_h do
				local size = 2;
				lsDisplaySystemSprite(1, 10+x*size, 90+y*size, 0, size, size, last_mon[x][y]);
			end
		end
		lsDoFrame();
		lsSleep(100);
	end
	statusScreen("Changed, waiting a moment for other beds to catch up...", nil, nil, 0.7);
	if not first_loop then -- Don't wait, we might be behind already!
		lsSleep(1500); -- Wait a moment after image changes before doing the next tick
	end
end

function doit()
	askForWindow("Pin any number of thistle gardens. Must be CASCADED (can be GRID if you use Grid Mode checkbox).\n\nUse Window Manager button and choose \'Form Cascade\' (or \'Form Grid\' if using Grid Mode) to arrange the windows correctly. Check \'Water Gap\' so that water icon isn\'t covered. Optionally, you can pin a rain barrel (water gap not required) to refill your jugs. Water is refilled after each tick, so you won\'t need many jugs (#gardens x 2 should be enough).\n\nCan handle up to about 32 gardens by using the cascade method (shuffles windows back and forth).");

  while 1 do
	thistleConfig();
	if dropdown_cur_value_canopy == 1 then
	  last_sun = 0;
	elseif dropdown_cur_value_canopy == 2 then
	  last_sun = 33;
	elseif dropdown_cur_value_canopy == 3 then
	  last_sun = 99;
	end

	if not ( #instructions == 41*5) then
		error("Invalid instruction length: " .. loadedFile .. "\nDid you add a valid recipe to the file?");
	end

	-- We want to make sure a Rain Barrel or Aquaduct isn't pinned. Previously we used ThisIs.png. Rain Barrel has ThisIs.png so tries to process this window like a regular thistle window
	-- Only check for windows showing 'This is Your Thistle Garden' or 'This is A Thistle Garden'
	srReadScreen();
	local your = findAllImages("Thistle/ThisIsYourThistleGarden.png");
	local a = findAllImages("Thistle/ThisIsAThistleGarden.png");

	if #your > 0 then
	  thisImage = "Thistle/ThisIsYourThistleGarden.png"
	elseif #a > 0 then
	  thisImage = "Thistle/ThisIsAThistleGarden.png"
	else
	  thisImage = "ThisIs.png"
	end

	if grid_mode then
	  mainCustomMode()
	else
    main();
	end
  end
end

function main()
	finish_up = nil;
	abort = nil;
	srReadScreen();
	window_locs = findAllImages(thisImage);
	plant_buttons_found = findAllImages("thistle/ThistlePlantACrop.png");
      startTime = lsGetTimer();

	if not (#window_locs == expected_gardens) then
		error ("Did not find expected number of thistle gardens (found " .. #window_locs .. " expected " ..  expected_gardens .. ")");
	end

	-- Check to see if we pinned windows with Form Grid, because we are in Cascade Mode.
	if #plant_buttons_found > 1 then
		error ("Are your windows in a Grid? Because you are in Cascade Mode! Check the 'Windows Arranged in Grid' checkbox or Pin your windows in a Cascade.");
	end

	for loops=1, num_loops do

		if finish_up then
		  break;
		end

		for i=0, 39 do
			drawWater(1);

			local to_click = {};
			if (i == 0) then
				to_click[1] = "Thistle/ThistlePlantACrop.png";
			end
			for j=0, 3 do
				for k=1, instructions[i*5 + j + 1] do
					to_click[#to_click+1] = "thistle/" .. button_names[j+1];
				end
			end
			if not (instructions[i*5 + 5] == last_sun) then
				last_sun = instructions[i*5 + 5];
				to_click[#to_click+1] = "thistle/" .. button_names[5];
			end
			if #to_click > 0 then
				clickAllComplex(to_click, ("(" .. loops .. "/" .. num_loops .. ") " .. i .. ":"));
			end
			waitForMonChange("(" .. loops .. "/" .. num_loops .. ") Tick " .. i .. "/40 done");
			if (i == 0) then -- first one immediately finds a change
				waitForMonChange("(" .. loops .. "/" .. num_loops .. ") Tick " .. i .. "/40 done");
			end
			if abort then
				to_click[1] = "Thistle/ThistleAbort.png";
				clickAllComplex(to_click, ("Aborting Crops ..."));
				closeAbortWindows();
				break;
			end
		end

		if abort then
		  clickAllComplex({thisImage});  -- Refresh windows after abort, so that 'Plant a Crop' appears
		else
		lsSleep(3000);
		  clickAllComplex({"Thistle/Harvest.png"});
		end
		lsSleep(500);

		drawWater(1);
		lsSleep(200);

		if abort then
			break;
		end
	end
	lsPlaySound("Complete.wav");
	lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1)
end


function mainCustomMode()
	finish_up = nil;
	abort = nil;
	srReadScreen();
	window_locs = findAllImages(thisImage);
	plant_buttons_found = findAllImages("thistle/ThistlePlantACrop.png");
      startTime = lsGetTimer();

	if not (#window_locs == expected_gardens) then
		error ("Did not find expected number of thistle gardens (found " .. #window_locs .. " expected " ..  expected_gardens .. ")");
	end

	-- Check to see if we pinned windows with Form Cascade, because we are in Grid Mode.
	if not (#window_locs == #plant_buttons_found) then
		error ("Are your windows Cascaded? Because you are in Grid Mode! Uncheck the 'Windows Arranged in Grid' checkbox or Pin your windows in a Grid.");
	end

	for loops=1, num_loops do

		if finish_up then
		  break;
		end

		for i=0, 39 do
		drawWater(1);

			if (i == 0) then
				clickAll(thisImage, 1); -- Refresh all windows
				clickAll("thistle/ThistlePlantACrop.png", 1);
			end

			for j=0, 3 do
				for k=1, instructions[i*5 + j + 1] do
					clickAll("thistle/" .. button_names[j+1], 1);
				end
			end

			if not (instructions[i*5 + 5] == last_sun) then
				last_sun = instructions[i*5 + 5];
				clickAll("thistle/" .. button_names[5], 1);
			end

			if (screenshot_test_mode and grid_mode) and (i == 9 or i == 19 or i == 29 or i == 39) then
			  screenshot(i)
			end

			waitForMonChange("(" .. loops .. "/" .. num_loops .. ") Tick " .. i .. "/40 done");
			if (i == 0) then -- first one immediately finds a change
				waitForMonChange("(" .. loops .. "/" .. num_loops .. ") Tick " .. i .. "/40 done");
			end

			if abort then
				clickAll("Thistle/ThistleAbort.png", ("Aborting Crops ..."));
				closeAbortWindows();
				break;
			end
		end

		if abort then
		  clickAll(thisImage);  -- Refresh windows after abort, so that 'Plant a Crop' appears
		else
		lsSleep(3000);
		  clickAll("Thistle/Harvest.png");
		end
		lsSleep(500);

		drawWater(1);
		lsSleep(200);

		if abort then
			break;
		end

	end
	lsPlaySound("Complete.wav");
	lsMessageBox("Elapsed Time:", getElapsedTime(startTime), 1)
end


function config()
  local is_done = false;
  local count = 1;
  while not is_done do
    checkBreak();
    local y = 10;
    lsPrint(12, y, 0, 0.7, 0.7, 0xffffffff,
            "Last Sun (Current Canopy Postion):");
    y = y + 35;
    lsSetCamera(0,0,lsScreenX*1.3,lsScreenY*1.3);
    dropdown_cur_value_canopy = readSetting("dropdown_cur_value_canopy",dropdown_cur_value_canopy);
    dropdown_cur_value_canopy = lsDropdown("thisCanopy", 15, y, 0, 320, dropdown_cur_value_canopy, dropdown_values_canopy);
    writeSetting("dropdown_cur_value_canopy",dropdown_cur_value_canopy);
    lsSetCamera(0,0,lsScreenX*1.0,lsScreenY*1.0);
    y = y + 20;

    if grid_mode then
      grid_color = 0xff8080ff
    else
      grid_color = 0xFFFFFFff
    end

    if screenshot_test_mode then
      screenshot_test_mode_color = 0xb1dd8cff
    else
      screenshot_test_mode_color = 0xFFFFFFff
    end

    grid_mode = readSetting("grid_mode",grid_mode);
    grid_mode = CheckBox(15, y, z+10, grid_color, " Windows Arranged in Grid  (thistle_custom)", grid_mode, 0.65, 0.65);
    writeSetting("grid_mode",grid_mode);

    y = y + 20;

    if grid_mode then
      screenshot_test_mode = readSetting("screenshot_test_mode",screenshot_test_mode);
      screenshot_test_mode = CheckBox(15, y, z+10, screenshot_test_mode_color, " Test Voids - Screenshot @ Ticks 9,19,29,39", screenshot_test_mode, 0.65, 0.65);
      writeSetting("screenshot_test_mode",screenshot_test_mode);
    end

    y = y + 20;

    lsPrint(15, y+5, 0, 0.8, 0.8, 0xffffffff, "How many passes?");
    is_done, num_loops = lsEditBox("num_loops", 175, y+5, 0, 50, 0, 0.9, 0.9,
                                     0x000000ff, 1);
     num_loops = tonumber(num_loops);
       if not num_loops then
         is_done = false;
         lsPrint(15, y+22, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
         num_loops = 1;
       end
    y = y + 25;
    lsPrint(15, y+5, 0, 0.8, 0.8, 0xffffffff, "How many gardens?");
    expected_gardens = readSetting("expected_gardens",expected_gardens);
    is_done, expected_gardens = lsEditBox("expected_gardens", 175, y+5, 0, 50, 0, 0.9, 0.9,
                                     0x000000ff, expected_gardens);
     expected_gardens = tonumber(expected_gardens);
       if not expected_gardens then
         is_done = false;
         lsPrint(15, y+22, 10, 0.7, 0.7, 0xFF2020ff, "MUST BE A NUMBER");
         expected_gardens = 1;
       end
    writeSetting("expected_gardens",expected_gardens);

    lsPrintWrapped(10, 160, z, lsScreenX - 20, 0.65, 0.65, 0xffff80FF, "Real Time Required:      " .. convertTime(436000*num_loops) .. "\nEgypt Time Required:    " .. convertTime(436000 / 1.068 * 3 * num_loops) .. "\nThistle Yield Expected:  " .. (5*num_loops*expected_gardens));
    lsPrintWrapped(10, 210, z, lsScreenX - 20, 0.65, 0.65, 0x40ffffff, "Current Farm: " .. loadedFarm .. "\nRecipe File: " .. convertFarmName2FileName(loadedFarm) ..
    "\n\nWe are ready to start making thistles, with this farm\'s recipe! Click Start button to proceed ...");

    if lsButtonText(lsScreenX - 110, lsScreenY - 60, 0, 100, 0xffff40ff, "Back") then
        break;
    end

    if lsButtonText(10, lsScreenY - 30, 0, 100, 0x40ff40ff, "Start") then
        is_done = 1;
        start = 1;
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,
                    "End script") then
      error(quitMessage);
    end
  lsDoFrame();
  lsSleep(10);
  end
end

function thistleConfig()
  local add;
  local y = 0;
  local z = 0;
  message = "";
  local foundRecipe;
  local is_done = false;


  while not is_done do
  checkBreak();

  if start then
    start = nil;
    break;
  end

	lsPrintWrapped(10, y+5, 0, lsScreenX, 0.6, 0.6, 0xFF0000ff,
	"");

	lsPrintWrapped(10, y+95, 0, lsScreenX - 20, 0.7, 0.7, 0xffff40ff,
	"---------------------------------------------------------------");

  if not add then
	if lsButtonText(15, y+180, 0, 125, 0xffbb80ff, "Add Farm") then
	  add = 1;
	end

	if lsButtonText(10, lsScreenY - 60, 0, 120, 0x6666FFff, "Misc Stuff") then
	  miscButtons();
	end

  else

	if lsButtonText(10, y+65, 0, 100, 0xffffffff, "Cancel") then
	  add = nil;
	end

	if string.len(farmName) > 0 then
	  if lsButtonText(140, y+65, 0, 120, 0xffffffff, "Create/Save") then
	    addSilkFarm(farmName);
	    add = nil;
	  end
	end

  end

  if add then
	lsPrint(10, y+10, 0, 0.8, 0.8, 0xffffffff, "Silk Farm Name:");
	is_done, farmName = lsEditBox("farmName", 10, y+30, 0, 230, 0, 0.9, 0.9, 0x000000ff);
  end

  --lsPrintWrapped(10, y+200, z, lsScreenX - 20, 0.65, 0.65, 0xffff40ff, message);

  parseSilkFarm();

  if #farms > 0 then
    lsSetCamera(0,0,lsScreenX/0.9, lsScreenY/0.9);
    dropdown_cur_value_farm = readSetting("dropdown_cur_value_farm",dropdown_cur_value_farm);
    dropdown_cur_value_farm = lsDropdown("thisFarm", 15, y+165, 0, lsScreenX - 20, dropdown_cur_value_farm, farms);
    writeSetting("dropdown_cur_value_farm",dropdown_cur_value_farm);
    lsSetCamera(0,0,lsScreenX,lsScreenY);

    lsPrintWrapped(15, 115, z, lsScreenX - 20, 0.65, 0.65, 0x40ffffff, "Silk Farm " .. dropdown_cur_value_farm .. "/" .. #farms .. " selected");

    if checkRecipeValid(farms[dropdown_cur_value_farm]) then
		foundRecipe = false;
    lsPrintWrapped(15, 130, z, lsScreenX - 20, 0.65, 0.65, 0xff4040ff, "Invalid Recipe - You need to Edit");
    else
      foundRecipe = true;
			lsPrintWrapped(15, 130, z, lsScreenX - 20, 0.65, 0.65, 0x40ff40ff, "Recipe Found");
    end

    if lsButtonText(15, y+215, 0, 125, 0xFF0000ff, "Delete Farm") then
      message = "";
		if promptOkay("Are you sure want to Delete?\n\nSilk Farm: " .. farms[dropdown_cur_value_farm], 0xff8080ff, 0.7, true) then
		  deleteSilkFarms(dropdown_cur_value_farm);
		end
    end

	  if lsButtonText(lsScreenX - 145, y+180, 0, 110, 0x6666FFff, "Edit Recipe") then
	    promptRecipe(farms[dropdown_cur_value_farm]);
	  end

    if foundRecipe then
	  if lsButtonText(10, lsScreenY - 30, 0, 120, 0x40ff40ff, "Load Farm") then
			if promptOkay("WARNING: Due to an issue with game windows being partially transparent, even with the setting at 0%.\n\n"
			.. "You MUST open a blank chat tab and move it behind the thistle windows in order to stop the macro "
			.. "producing a false positive and ruining your thistle recipe.\n\nSee the FAQ channel in automato "
			.. "discord for an example", 0xFF0000ff, 0.7, true, false) == nil then
	      thistleConfig();
	    else
				loadSilkFarms(farms[dropdown_cur_value_farm]);
		    config();
	    end
	  end
    end
  end

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff, "End script") then
    error "Clicked End Script button";
  end

  if lsButtonText(lsScreenX - 110, lsScreenY - 60, z, 100, 0xffff40ff, "Calendar") then
    if socketHttpFirstRun then -- If we already fetched Voids once, then the "Allow Network Access' prompt won't appear again, so skip message
      lsButtonText(lsScreenX - 110, lsScreenY - 60, 10, 100, 0xffffc0ff, "Querying!");
      lsDoFrame();
      fetchVoids();
    else
      fetchVoidsWarning();
    end
  end

  lsDoFrame();
  lsSleep(10);
  end -- end while
end

function closeAbortWindows()
  while 1 do
      sleepWithStatus(50,"Closing Popup windows ...")
	checkBreak();
	srReadScreen();
	local pos = srFindImage("yes.png");
		if (pos) then
		  safeClick(pos[0] + 1, pos[1] + 1);
               lsSleep(10);
		end
	local pos2 = srFindImage("OK.png");
		if (pos2) then
		  safeClick(pos2[0] + 1, pos2[1] + 1);
               lsSleep(10);
		end
	if not pos and not pos2 then
        break;
	end
  end
end


function miscButtons()
  while 1 do
  checkBreak();

  if lsButtonText(lsScreenX/2 - 60, 10, 0, 140, 0xffffffff, "Window Manager") then
	--function windowManager(title, message, allowCascade, allowWaterGap, varWidth, varHeight, sizeRight, offsetWidth,
--    windowManager("Thistle Garden Setup", nil, true, true, nil, nil, nil, nil, nil, nil, true);
--    windowManager("Thistle Garden Setup", nil, true, true, nil, nil, nil, nil, nil);


--  windowManager("Thistle Garden Setup", nil, true, true, nil, nil, nil, nil, nil);

    windowManager("Thistle Garden Setup", nil, true, true, nil, nil, nil, nil, nil, nil, false);


  end

  lsPrint(10, 80, z, 0.7, 0.7, 0xFFFFFFff, "Use these buttons if pinned in CASCADE:");

  if lsButtonText(lsScreenX/2 - 60, 100, z, 140, 0xFFFFFFff, "Abort Crops") then
    if promptOkay("This is only used if you currently have crops planted and wish to abort them (if something went wrong).\n\nYou don\'t get thistles back when you abort!\n\nAre you sure want to Abort Crops?", 0xff8080ff, 0.7, true) then
      closeAbortWindows();
	clickAllComplex({"Thistle/ThistleAbort.png"}, "Aborting");
	closeAbortWindows();
	clickAllComplex({thisImage}, "Refreshing");  -- Refresh windows after abort, so that 'Plant a Crop' appears
    end
  end

  if lsButtonText(lsScreenX/2 - 60, 130, z, 140, 0xFFFFFFff, "Harvest Crops") then
    if promptOkay("This is only used if you currently have crops planted and are ready for harvest. Likely something went wrong in macro.\n\nAre you sure you want to Harvest Crops?", 0xff8080ff, 0.7, true) then
      closeAbortWindows();
      clickAllComplex({"Thistle/Harvest.png"}, "Harvesting");
      clickAllComplex({thisImage}, "Refreshing");  -- Refresh windows after abort, so that 'Plant a Crop' appears
    end
  end

  lsPrint(10, 180, z, 0.7, 0.7, 0xFFFFFFff, "Use these buttons if pinned in GRID:");


  if lsButtonText(lsScreenX/2 - 60, 200, z, 140, 0xFFFFFFff, "Abort Crops") then
    if promptOkay("This is only used if you currently have crops planted and wish to abort them (if something went wrong).\n\nYou don\'t get thistles back when you abort!\n\nAre you sure want to Abort Crops?", 0xff8080ff, 0.7, true) then
      closeAbortWindows();
	clickAll("Thistle/ThistleAbort.png", "Aborting");
	closeAbortWindows();
	clickAll(thisImage, "Refreshing");  -- Refresh windows after abort, so that 'Plant a Crop' appears
    end
  end

  if lsButtonText(lsScreenX/2 - 60, 230, z, 140, 0xFFFFFFff, "Harvest Crops") then
    if promptOkay("This is only used if you currently have crops planted and are ready for harvest. Likely something went wrong in macro.\n\nAre you sure you want to Harvest Crops?", 0xff8080ff, 0.7, true) then
      closeAbortWindows();
      clickAll("Thistle/Harvest.png", "Harvesting");
      clickAll(thisImage, "Refreshing");  -- Refresh windows after abort, so that 'Plant a Crop' appears
    end
  end

  if lsButtonText(10, lsScreenY - 30, 0, 100, 0xffff40ff, "Back") then
        break;
  end

  if lsButtonText(lsScreenX - 110, lsScreenY - 30, z, 100, 0xFF0000ff, "End script") then
    error "Clicked End Script button";
  end

  lsDoFrame();
  lsSleep(10);
  end
end

-----------------------------------------------------------------
-- file/parsing/socket functions
-----------------------------------------------------------------

function convertFarmName2FileName(farm)
  local fileName = string.gsub(farm, "%W", ""); -- strip all punctuation, spaces, special characters, leaving only letters/numbers
  fileName = "SilkFarm_" .. fileName .. ".txt";
  return fileName;
end

function parseSilkFarm()
  farms = {};
  local file = io.open("SilkFarms.txt", "a+");
  io.close(file);
  for line in io.lines("SilkFarms.txt") do
    farms[#farms + 1] = line
  end
  return farms;
end

function loadSilkFarms(farm)
  local fileName = convertFarmName2FileName(farm);
  loadedFarm = farm;
  loadedFile = fileName;
  dofile(fileName);
end

function addSilkFarm(farm)
  local fileName = convertFarmName2FileName(farm);
  local file = io.open("SilkFarms.txt", "a+");
  file:write(farmName .. "\n")
  io.close(file);
  file = io.open(fileName, "w+");
  file:write("instructions = {\n\n};")
  io.close(file);
  parseSilkFarm(); -- Refresh #farms and force pulldown menu to last entry.
  writeSetting("dropdown_cur_value_farm",#farms);
  message = "Folder: Automato/Games/ATITD/\nAdded Farm: \"" .. string.upper(farm) .. "\" to SilkFarms.txt\n\nCreated: " .. fileName .. "\nYou can manually edit this file to add recipe or use the 'Edit Recipe' button.";
end

function editSilkFarm(farm)
  local fileName = convertFarmName2FileName(farm);
  file = io.open(fileName, "w+");
  file:write("instructions = {\n" .. recipe .. "\n};")
  io.close(file);
  message = "Folder: Automato/Games/ATITD/\nFarm: " .. string.upper(farm) .. "\nFile: " .. fileName .. "\n\nYour recipe has been successfully saved to this file!";
end

function deleteSilkFarms(num)
  local farms = {};
  local lineNumber = 0;
  local output = "";
  local file = io.open("SilkFarms.txt", "r");
  io.close(file);
  for line in io.lines("SilkFarms.txt") do
    lineNumber = lineNumber + 1;
	if num ~= lineNumber then
	  table.insert(farms, line);
	else
	  farmName = line;
	  fileName = convertFarmName2FileName(farmName);
	end
  end
  for i = 1, #farms,1 do
    output = output .. farms[i] .. "\n";
  end
  file = io.open("SilkFarms.txt", "w+");
  file:write(output)
  io.close(file);
  file = io.open(fileName, "w+"); -- zero out the file so we noticed it needs deleted from Automato folder
  io.close(file);
  num = num - 1;  -- Force pull down menu to the previous farm, after delete
  if num < 1 then num = 1; end
  writeSetting("dropdown_cur_value_farm", num);
  message = "Folder: Automato/Games/ATITD/\nDeleted Farm: \"" .. string.upper(farmName) .. "\" from SilkFarms.txt\n\nLeftover File: " .. fileName .. "\nYou can delete this file if you wish.";
end

function parseRecipeLeft(recipe)
  local recipes = explode(",",singleLine(recipe));
  local lineNumber = 0;
  local output = " ";
  for i = 1, #recipes,1 do
    if i >= 1 and i <= 21*5 then
      lineNumber = lineNumber + 1
      output = output .. recipes[i] .. ",";
        if lineNumber == 5 then
          output = output .. "\n";
          lineNumber = 0;
        end
    end
  end
	if string.len(output) <= 2 then
	  output = ""; -- There's some weird stand-alone comma that appears when no recipe loaded or pasted yet. This simply gets rid of it off gui.
	end
  return output;
end

function parseRecipeRight(recipe)
  local recipes = explode(",",singleLine(recipe));
  local lineNumber = 0;
  local output = "";
  for i = 1, #recipes,1 do
    if i >= 106 then
    lineNumber = lineNumber + 1
      output = output .. recipes[i];
        if i <= 205 then
         output = output .. ",";
        end
          if lineNumber == 5 then
            output = output .. "\n";
            lineNumber = 0;
          end
    end
  end
  return output;
end

function checkRecipeValid(farm)
  local fetchRecipe = {};
  local fileName = convertFarmName2FileName(farm);
  local badList = false;
  local lineNumber = 0;
  local recipe = "";
  local foundRecipe = false;

  for line in io.lines(fileName) do
    lineNumber = lineNumber + 1;
	if lineNumber > 1 and lineNumber < 43 then
	  table.insert(fetchRecipe, line);
	end
  end

  if lineNumber > 40 then
    foundRecipe = true;
    for i = 1, #fetchRecipe,1 do
      recipe = recipe .. fetchRecipe[i] .. "\n";
    end
  else
   recipe = "";
  end
    --local list = csplit(singleLine(recipe), ",");
    local list = explode(",",singleLine(recipe));
    if list[#list] == "" then
      table.remove(list);
    end
    for i=1,#list do
      list[i] = tonumber(list[i]);
      if not list[i] then
	badList = true;
      end
    end
    if #list ~= 41*5 then
      badList = true;
    end
    return badList;
end

function fetchVoids()
  -- Fetch voids from Cegaiel's site
--  http = require "socket.http" -- Use this to connect to http:// address
  http = require "ssl.https"  -- Use this to connect to https:// address
  result, statuscode, content = http.request("https://automato.sharpnetwork.net/listvoids.asp")
  if statuscode ~= 200 then
    result = "Status Code: " .. statuscode .. "\n\nThere was a problem contacting 'Cegaiel\'s ATITD Tools' server.\n\nTry again later!";
  else
    result = string.gsub(result, "|", "\n");
    result = string.gsub(result, "&nbsp;", " ");
  end
  while 1 do
    statusScreen(result, nil, 0.65,0.65);
    if lsButtonText(10, lsScreenY - 30, 0, 100, 0xffff40ff, "Back") then
	socketHttpFirstRun = 1;
	break;
    end
    lsSleep(10);
  end
end

function fetchVoidsWarning()
  while not socketHttpFirstRun do
    checkBreak();
    lsPrintWrapped(10, 10, 0, lsScreenX - 20, 0.7, 0.7, 0xFFFFFFff,
      "You are about to fetch a web page from Cegaiel\'s ATITD Tools page.\n\n" ..
      "Note: You will be prompted to 'Allow Network Access'.\n\nThis is a standard prompt, by Automato, whenever you attempt to use the http.socket. " ..
      "Nothing to be alarmed about.\n\nJust click Yes to continue, when prompted. You won\'t receive this notice anymore unless you Restart macro.\n\nClick 'Continue' button to query server.");


    if lsButtonText(lsScreenX - 110, lsScreenY - 60, 0, 100, 0xffff40ff, "Back") then
        break;
    end
    if lsButtonText(10, lsScreenY - 30, 0, 120, 0xFFFFFFFF, "Continue") then
      fetchVoids();
    end
    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,
                    "End script") then
      error(quitMessage);
    end
  lsDoFrame();
  lsSleep(10);
  end
end

function screenshot(tick)
local dateTime;
local filename;
  srReadScreen();
  if getTime() then
    dateTime = getTime("datetime2")
  else
    dateTime = lsGetTimer()
  end
  filename = "thistle_new_tick" .. tick .. "_" .. dateTime .. ".png"
  srReadScreen(); -- Do one more screenRead to remove white/stripped background on Clock (created by getTime())
  srSaveLastReadScreen(filename)
  sleepWithStatus(1000, "Screenshot Saved:\n\n" .. filename, nil, 0.7)
end

-------------------------------------------------------------------------------
-- promptRecipe()
--
-- Most of this function "borrowed" from thistle.lua - Thanks Tallow!
-------------------------------------------------------------------------------

function promptRecipe(farm)
  local fileName = convertFarmName2FileName(farm);
  local is_done = false;
  local lineNumber = 0;
  local foundRecipe = false;
  local pasted = false;
  local fetchRecipe = {};
  recipe = "";

  for line in io.lines(fileName) do
    lineNumber = lineNumber + 1;
	if lineNumber > 1 and lineNumber < 43 then
	  table.insert(fetchRecipe, line);
	end
  end

  if lineNumber > 40 then
    foundRecipe = true;
    for i = 1, #fetchRecipe,1 do
      recipe = recipe .. fetchRecipe[i] .. "\n";
    end
  else
   recipe = "";
  end

  while not is_done do

    checkBreak();
    lsPrint(10, 10, 0, 0.9, 0.9, 0xffffffff,
            "Paste Recipe");
    local y = 60;
    lsPrint(10, y, 0, 0.6, 0.6, 0x40ffffff,
            "Editing: " .. farm .. " (" .. fileName .. ")");

    y = y + 20;

    if lsButtonText(100, lsScreenY - 30, 0, 80, 0xffffffff, "Paste") then
	pasted = true;
      recipe = lsClipboardGet();
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFF0000ff,
                    "End script") then
      error(quit_message);
    end

    if lsButtonText(lsScreenX - 110, lsScreenY - 60, 0, 100, 0xffff40ff, "Back") then
        break;
    end

    local badList = false;
    --local list = csplit(singleLine(recipe), ",");
    local list = explode(",",singleLine(recipe));
    if list[#list] == "" then
      table.remove(list);
    end
    for i=1,#list do
      list[i] = tonumber(list[i]);
      if not list[i] then
	badList = true;
      end
    end
    if #list ~= 41*5 then
      badList = true;
    end

    if pasted and not badList then
      lsPrint(140, 13, 10, 0.7, 0.7, 0x80ff80ff, "PASTED RECIPE");
      lsPrintWrapped(10, 30, z, lsScreenX - 20, 0.6, 0.6, 0xffff40ff, "Click 'Save' button to write this to file.");
    end


    if foundRecipe and not pasted and not badList then
      lsPrint(140, 13, 10, 0.7, 0.7, 0x40ff40ff, "LOADED RECIPE");
      lsPrintWrapped(10, 30, z, lsScreenX - 20, 0.6, 0.6, 0xffff40ff, "Copy your recipe, from thistle_history.txt to Clipboard (Ctrl+C), then click 'Paste' and 'Save' button.");
    end

    if badList then
      is_done = false;
      lsPrint(140, 13, 10, 0.7, 0.7, 0xFF2020ff, "INVALID RECIPE");
	lsPrintWrapped(10, 30, z, lsScreenX - 20, 0.6, 0.6, 0xffff40ff, "Copy your recipe, from history.txt to Clipboard (Ctrl+C), then click 'Paste' and 'Save' button.");
    elseif lsButtonText(10, lsScreenY - 30, 0, 80, 0xFFFFFFff, "Save") then
      editSilkFarm(farm)
      is_done = true;
    end
    instructions = list;
--    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xFFFFFFff,
--		   string.sub(recipe, 0, math.floor(string.len(recipe)/2)));
--    lsPrintWrapped(100, y, 0, lsScreenX - 20, 0.5, 0.5, 0xFFFFFFff,
--		   string.sub(recipe, math.floor(string.len(recipe)/2)));

-- Fix: Last line on column 1 is split and 2nd half occurs on top of column 2:
-- This fix can likely be solved more efficiently, but this is what I came up with for now, Ceg.
    lsPrintWrapped(10, y, 0, lsScreenX - 20, 0.5, 0.5, 0xFFFFFFff,
		   parseRecipeLeft(recipe));
    lsPrintWrapped(100, y, 0, lsScreenX - 20, 0.5, 0.5, 0xFFFFFFff,
		   parseRecipeRight(recipe));

    lsSleep(10);
    lsDoFrame();
  end
end

--------------
-- Added in an explode function (delimiter, string) to deal with broken csplit.
function explode(d,p)
   local t, ll
   t={}
   ll=0
   if(#p == 1) then
      return {p}
   end
   while true do
      l = string.find(p, d, ll, true) -- find the next d in the string
      if l ~= nil then -- if "not not" found then..
         table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
         ll = l + 1 -- save just after where we found it for searching next time.
      else
         table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
         break -- Break at end, as it should be, according to the lua manual.
      end
   end
   return t
end

function convertTime(ms)
	local duration = math.floor(ms / 1000);
	local hours = math.floor(duration / 60 / 60);
	local minutes = math.floor((duration - hours * 60 * 60) / 60);
	local seconds = duration - hours * 60 * 60 - minutes * 60;
      if hours > 0 then
	  return string.format("%02dh %02dm %02ds",hours,minutes,seconds);
      else
	  return string.format("%02dm %02ds",minutes,seconds);
      end
end
