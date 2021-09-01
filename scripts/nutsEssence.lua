dofile("common.inc");

----------------------------------------
--          Global Variables          --
----------------------------------------
window_w = 377;
window_h = 246;
tol = 8000;
per_click_delay = 20;
readDelay = 110;
tick_time = 500;
num_rounds = 1;
----------------------------------------

function shImage(imageName, window_pos)
  local win = srGetWindowBorders(window_pos[0]+(window_w/2), window_pos[1]+(window_h/2));
  return srFindImageInRange (imageName, win[0], win[1], win[2]-win[0], win[3]-win[1], tol);
end

function toxinTick(window_pos, state)
  state.status = "";
  local pos;
  local image;
  local stat_con;

  --Gather current toxin state of the window
  srReadScreen();
  --Search for awaiting nut's essence
  image = shImage("toxinkitchen/ToxinBatchNut.png", window_pos);
  if image then
    if stop_cooking == true or num_rounds == 0 then
      return "Finished";
    end
    --Search for black con timer
    stat_con = srFindImage("stats/constitution.png");
    if stat_con then
      state.status = "Con not Ready";
      return state.status;
    end
    --start a new batch
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
    state.status = "Starting new batch";
    state.initCactus = nil;
    state.initCC = nil;
    return state.status;
  end

  --otherwise, search for which stage we're in
  image = shImage("toxinKitchen/ToxinStage.png", window_pos);
  if not image then
    return "could not find Stage";
  end
  state.stage = ocrNumber(image[0] + 34, image[1], BLUE_SMALL_SET);
  state.status = "Stage: " .. state.stage;

  --check volume
  image = shImage("toxinkitchen/ToxinVolume.png", window_pos);
  if not image then
    return "could not find Volume";
  end
  state.volume = ocrNumber(image[0] + 48, image[1], BLUE_SMALL_SET);
  state.status = state.status .. " V = " .. state.volume;

  --check temp
  image = shImage("toxinkitchen/ToxinTemperature.png", window_pos);
  if not image then
    return "could not find Temp";
  end
  state.temp = ocrNumber(image[0] + 66, image[1], BLUE_SMALL_SET);
  if state.stage == 1 or state.stage == 3 then
    state.status = state.status .. " T =  " .. state.temp;
  end


  --acidity
  image = shImage("toxinkitchen/ToxinAcidity.png", window_pos);
  if not image then
    return "could not find Acidity";
  end
  state.acidity = ocrNumber(image[0] + 41, image[1], BLUE_SMALL_SET);
  if state.stage == 2 then
    state.status = state.status .. " A= " .. state.acidity;
  end

  --precipitate
  image = shImage("toxinkitchen/ToxinPrecipitate.png", window_pos);
  if not image then
    return "could not find Precipitate";
  end
  state.precip = ocrNumber(image[0] + 59, image[1], BLUE_SMALL_SET);
  if state.stage == 4 then
    state.status = state.status .. " P= " .. state.precip;
  end


  --initialize some stuff at the start of the batch
  if state.init == nil then
    state.init = 1;
    state.cjTimer = 0;
    state.lastAcid = state.acidity;
  end

  state.cjTimer = state.cjTimer - tick_time;


  if state.volume < 3 then
    image = shImage("toxinkitchen/DiluteWater.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
  end

  if state.stage == 1 and state.initCC == nil then
    image = shImage("toxinkitchen/HeatCharcoal.png", window_pos);
      for i = 1, 6, 1 do
        srClickMouseNoMove(image[0] + 2, image[1] + 2);
        lsSleep(per_click_delay);
      end
    state.initCC = 1;
    lsSleep(1000);
    state.lastTemp = state.temp;
  end
  if state.stage == 1 and state.temp < 600 and state.temp > 0 and state.temp ~= state.lastTemp then
    image = shImage("toxinkitchen/HeatCharcoal.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    state.lastTemp = state.temp;
    lsSleep(per_click_delay);
  end

  if state.stage == 1 and state.temp >= 600 and state.temp <= 800 then
    image = shImage("toxinkitchen/ToxinIngredient.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
    state.status = state.status .. " Add Ingred.";
    return state.status;
  end

  --Check our cactus sap situation.  Add 3 cactus saps initially, then check
  if state.stage == 2 and state.initCactus == nil and state.acidity == 0 then
    image = shImage("toxinkitchen/CatalyzeSap.png", window_pos);
      for i = 1, 3, 1 do
        srClickMouseNoMove(image[0] + 2, image[1] + 2);
        lsSleep(per_click_delay);
      end
    state.lastTemp = state.temp;
    state.needCabbage = true;
    state.status = state.status .. " Add Sap.";
    state.initCactus = 1;
  end

  --if we're in state 2 and temp changes, check with cabbage juice

  if state.stage == 2 and state.temp ~= state.lastTemp then
    state.needCabbage = true;
    state.lastTemp = state.temp;
  end

  --means we're below the threshold for acid
  if state.acidity ~= state.lastAcid and state.acidity < 3.40 then
    image = shImage("toxinkitchen/CatalyzeSap.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
    state.needCabbage = true;
    state.status = state.status .. " Add Sap&CabJu.";
    state.lastAcid = state.acidity;
  end

  if state.stage == 2 and state.needCabbage and state.cjTimer <= 0 then
    image = shImage("toxinkitchen/CheckAcidity.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
    state.needCabbage = false;
    state.status = state.status .. " Add CabJu.";
    state.cjTimer = 4000;
    return state.status;
  end

  if state.stage == 2 and state.acidity >= 3.40 and state.acidity <= 3.80 then
    image = shImage("toxinkitchen/ToxinIngredient.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
    state.status = state.status .. " Add Ingred.";
    return state.status;
  end

  --now state 3
  if state.stage == 3 and state.temp >= 200 and state.temp <= 400 then
    image = shImage("toxinkitchen/ToxinIngredient.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
    state.status = state.status .. " Add Ingred.";
    return state.status;
  end

  if state.stage == 3 and state.temp < 200 then
    image = shImage("toxinkitchen/HeatCharcoal.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
  end

  --Now wait until the precipitate gets to 1
  if state.stage == 4 and state.precip == 1 then
    image = shImage("ThisIs.png", window_pos);
    srClickMouseNoMove(image[0] + 2, image[1] + 2);
    lsSleep(per_click_delay);
  end

  --Lastly, look for the take option
  if state.stage == 4 then
    image = shImage("toxinkitchen/Take.png", window_pos);
    if image then
      srClickMouseNoMove(image[0] + 2, image[1] + 2);
      lsSleep(per_click_delay);
      num_rounds = num_rounds - 1;
    end
  end

  return state.status;
end

function doit()
  num_rounds = promptNumber("How many Nut's Essence?", 1);
  askForWindow("Start a batch in each toxin kitchen, and pin the menus away from the middle of your screen.  Put the cursor over the ATITD window, press Shift.");
  srReadScreen();
  stop_cooking = false;
  local toxinWindows = findAllImages("ThisIs.png");
    if #toxinWindows == 0 then
    error 'Did not find any open windows';
    end
  local toxin_state = {};
    for window_index=1, #toxinWindows do
    toxin_state[window_index] = {};
    toxinWindows[window_index][0] = toxinWindows[window_index][0]-6;
    end
  local last_ret = {};
    while 1 do
    -- Tick
    srReadScreen();
    --Clear all ok messages
    local image = srFindImage("Ok.png", tol);
      if image then
        srClickMouseNoMove(image[0] + 2, image[1] + 2);
        lsSleep(per_click_delay + readDelay);
        srReadScreen();
        image = srFindImage("Ok.png", tol);
      end
    local toxinWindows2 = findAllImages("ThisIs.png");
    local should_continue=nil;
      if #toxinWindows == #toxinWindows2 then
        for window_index=1, #toxinWindows do
        local r = toxinTick(toxinWindows[window_index], toxin_state[window_index]);
        last_ret[window_index] = r;
          if r then
            if r == "Finished" then
            error("Finished");
            end
          should_continue = 1;
          end
        lsSleep(readDelay);
        end
      end
    -- Display status and sleep
    local start_time = lsGetTimer();
    while tick_time - (lsGetTimer() - start_time) > 0 do
    time_left = tick_time - (lsGetTimer() - start_time);

    lsPrint(10, 6, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Ctrl+Shift to end this script.");
    lsPrint(10, 18, 0, 0.7, 0.7, 0xB0B0B0ff, "Hold Alt+Shift to pause this script.");
    lsPrint(10, 30, 0, 0.7, 0.7, 0xFFFFFFff, "Waiting " .. time_left .. "ms...");
      if not (#toxinWindows == #toxinWindows2) then
        lsPrintWrapped(10, 45, 5, lsScreenX-15, 1, 1, 0xFF7070ff, "Expected " .. #toxinWindows .. " windows," ..
        " found " .. #toxinWindows2 .. ", not ticking.");
      end
      for window_index=1, #toxinWindows do
        lsPrint(10, 80 + 15*window_index, 0, 0.7, 0.7, 0xFFFFFFff, "#" .. window_index ..
        " - " .. last_ret[window_index]);
      end
      if lsButtonText(lsScreenX - 110, lsScreenY - 60, 0, 100, 0xFFFFFFff, "Finish up") then
        stop_cooking = true;
      end
      if lsButtonText(lsScreenX - 110, lsScreenY - 30, 0, 100, 0xFFFFFFff, "End script") then
        error "Clicked End Script button";
      end
    lsDoFrame();
    lsSleep(25);
    checkBreak();
    end
  -- error 'done';
  end
end
