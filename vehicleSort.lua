------------------------------------------------------------------
-- VehicleSort
-- Authors: Dschonny, Slivicon
-- Change log in modDesc.xml
------------------------------------------------------------------
vsClass ={};
vsClass.tColor = {}; -- Text colours
vsClass.tColor.standard = {1.0, 1.0, 1.0, 1.0}; -- white
vsClass.tColor.selected = {0.0, 1.0, 0.0, 1.0}; -- green
vsClass.tColor.locked = {1.0, 0.0, 0.0, 1.0};   -- red
vsClass.tColor.parked = {0.5, 0.5, 0.5, 0.7};   -- grey
vsClass.config = {
  {"showTrain", true},
  {"showCrane", false},
  {"showBrand", false},
  {"showType", false},
  {"showNames", true},
  {"showFillLevels", true},
  {"showPercentages", true},
  {"showEmpty", false}
};
vsClass.showSteerables = false;
vsClass.selectedIndex = 1;
vsClass.selectedConfigIndex = 1;
vsClass.selectedLock = false;
vsClass.showConfig = false;
vsClass.vInitOrder = {};
vsClass.vUserOrder = {};
vsClass.userPath = "";
vsClass.vsBasePath = "";
vsClass.vsSavePath = "";
vsClass.vsXML = "";
vsClass.saveFile = 0;
vsClass.debugOnScreen = {{"DebugOnScreenActive", 100}};
vsClass.showDebugOnScreen = false;
vsClass.DEBUG = false;
vsClass.vsInitialized = false;

addModEventListener(vsClass);

local vsClass_mt = Class(vsClass, Mission00);
local modItem = ModsUtil.findModItemByModName(g_currentModName);
vsClass.version = (modItem and modItem.version) and modItem.version or "?.?.?";

function vsClass:new(baseDirectory, customMt)
  local mt = customMt;
  if mt == nil then
    mt = vsClass_mt;
  end;
  local self = vsClass:superClass():new(baseDirectory, mt);
  return self;
end;

function vsClass:getNameBrand(xmlFile)
  local sName = getXMLString(xmlFile, "vehicle.storeData.brand");
  if sName == nil then
    sName = "Lizard";
  end;
  return sName;
end

function vsClass:getName(xmlFile, sFallback)
  local sName = getXMLString(xmlFile, "vehicle.storeData.name");
  if sName == nil then
    sName = getXMLString(xmlFile, "vehicle.storeData.name." .. g_languageShort);
  end;
  if sName == nil then
    sName = getXMLString(xmlFile, "vehicle.storeData.name");
  end;
  if sName == nil then
    sName = getXMLString(xmlFile, "vehicle.name." .. g_languageShort);
  end;
  if sName == nil then
    sName = getXMLString(xmlFile, "vehicle.name");
  end;
  if sName ~= nil then
    if sName:sub(1, 6) == "$l10n_" then
      if g_i18n:hasText(sName:sub(7)) then
        sName = g_i18n:getText(sName:sub(7));
      else
        sName = Utils.getXMLI18N(xmlFile, "vehicle.name", "", "", self.customEnvironment);    
      end;
    end;
  end;
  if sName == nil or sName == "" then
    sName = getXMLString(xmlFile, "vehicle#type");
    if sName ~= nil then
      if sName:sub(1, 6) == "$l10n_" then
        if g_i18n:hasText(sName:sub(7)) then
          sName = g_i18n:getText(sName:sub(7));
        else
          sName = Utils.getXMLI18N(xmlFile, "vehicle#type", "", "", self.customEnvironment);    
        end;
      end;
    end;
  end;
  if sName == nil or sName == "" then
    sName = sFallback;
  end;
  return sName;
end

function vsClass:loadSteerable(xmlFile)
  self.vs_brandName = vsClass:getNameBrand(self.xmlFile);
  self.vs_name = vsClass:getName(self.xmlFile, "Steerable");
end

function vsClass:loadAttachable(xmlFile)
  self.vs_brandName = vsClass:getNameBrand(self.xmlFile);
  self.vs_name = vsClass:getName(self.xmlFile, "Attachable");
end

function vsClass:keyEvent(unicode, sym, modifier, isDown)
  if isDown and sym == 27 then -- Esc key
    vsClass.showSteerables = false;
    vsClass:saveVehicleOrder();
    vsClass.selectedLock = false;
  end;
end

function vsClass:moveUp()
  local oldIndex = vsClass.selectedIndex;
  vsClass.selectedIndex = vsClass.selectedIndex - 1;
  if vsClass.selectedIndex < 1 then
    vsClass.selectedIndex = table.getn(g_currentMission.steerables);
  end;
  local sConfig = g_currentMission.steerables[vsClass.selectedIndex].configFileName;
  if (string.find(sConfig, "train/locomotive") and not vsClass.config[1][2]) or (string.find(sConfig, "train/stationCrane") and not vsClass.config[2][2]) then
    vsClass:moveUp();
  end;
  if vsClass.selectedLock then
    vsClass:reSort(oldIndex, vsClass.selectedIndex);
  end;
end

function vsClass:moveDown()
  local oldIndex = vsClass.selectedIndex;
  vsClass.selectedIndex = vsClass.selectedIndex + 1;
  if vsClass.selectedIndex > table.getn(g_currentMission.steerables) then
    vsClass.selectedIndex = 1;
  end;
  local sConfig = g_currentMission.steerables[vsClass.selectedIndex].configFileName;
  if (string.find(sConfig, "train/locomotive") and not vsClass.config[1][2]) or (string.find(sConfig, "train/stationCrane") and not vsClass.config[2][2]) then
    vsClass:moveDown();
  end;
  if vsClass.selectedLock then
    vsClass:reSort(oldIndex, vsClass.selectedIndex);
  end;
end

function vsClass:reSort(oldPos, newPos)
  local tempElement = g_currentMission.steerables[oldPos];
  local tempIndex = vsClass.vUserOrder[oldPos];
  table.remove(g_currentMission.steerables, oldPos);
  table.remove(vsClass.vUserOrder, oldPos);
  table.insert(g_currentMission.steerables, newPos, tempElement);
  table.insert(vsClass.vUserOrder, newPos, tempIndex);
  tempElement = nil;
end

function vsClass:toggleParkState(index)
  g_currentMission.steerables[index].nonTabbable = not g_currentMission.steerables[index].nonTabbable;
end

function vsClass:update(dt)
  if g_dedicatedServerInfo ~= nil then
    return;
  end;
  if not vsClass.vsInitialized  then
    vsClass:vsInit();
    vsClass.vsInitialized = true;
  end;
  if InputBinding.hasEvent(InputBinding.vs_showConfig) then
    if vsClass.showSteerables and not vsClass.showConfig then
      vsClass.showSteerables = false;
    end;
    vsClass.showConfig = not vsClass.showConfig;
  end;
  if vsClass.showConfig then
    if InputBinding.hasEvent(InputBinding.vs_moveCursorUp) then
      vsClass.selectedConfigIndex = vsClass.selectedConfigIndex - 1;
      if vsClass.selectedConfigIndex <= 0 then
        vsClass.selectedConfigIndex = table.getn(vsClass.config);
      end;
    elseif InputBinding.hasEvent(InputBinding.vs_moveCursorDown) then
      vsClass.selectedConfigIndex = vsClass.selectedConfigIndex + 1;
      if vsClass.selectedConfigIndex > table.getn(vsClass.config) then
        vsClass.selectedConfigIndex = 1;
      end;
    elseif InputBinding.hasEvent(InputBinding.vs_lockListItem) then
      vsClass.config[vsClass.selectedConfigIndex][2] = not vsClass.config[vsClass.selectedConfigIndex][2];
      vsClass:saveVehicleOrder();
    end;
  end;
  if InputBinding.hasEvent(InputBinding.vs_toggleList) then
    if vsClass.showSteerables then
      vsClass.showSteerables = false;
      vsClass.selectedLock = false;
      vsClass:saveVehicleOrder();
    else
      vsClass.showSteerables = true;
      vsClass.showConfig = false;
    end;
  end;
  if vsClass.showSteerables then
    if InputBinding.hasEvent(InputBinding.vs_moveCursorUp) then
      vsClass:moveUp();
    elseif InputBinding.hasEvent(InputBinding.vs_moveCursorDown) then
      vsClass:moveDown();
    elseif InputBinding.hasEvent(InputBinding.vs_lockListItem) then
      if not vsClass.selectedLock and vsClass.selectedIndex > 0 then
        vsClass.selectedLock = true;
      elseif vsClass.selectedLock then
        vsClass.selectedLock = false;
      end;
    elseif InputBinding.hasEvent(InputBinding.vs_changeVehicle) then
      if g_currentMission.steerables[vsClass.selectedIndex].isControlled == false then
        g_currentMission:requestToEnterVehicle(g_currentMission.steerables[vsClass.selectedIndex]);
      end;
    elseif InputBinding.hasEvent(InputBinding.vs_togglePark) then
      vsClass:toggleParkState(vsClass.selectedIndex);
    end;
  end;
end

function vsClass:drawConfig()
  local cCount = table.getn(vsClass.config);
  if vsClass.showConfig then
    local xPos = vsClass.tPos.x;
    local yPos = vsClass.tPos.y;
    setTextColor(unpack(vsClass.tColor.standard));
    setTextAlignment(vsClass.tPos.alignment);
    renderText(xPos, yPos + vsClass.tPos.size + vsClass.tPos.spacing + 0.007, vsClass.tPos.size + 0.005, g_i18n:getText("configHeadline"));
    for i = 1, cCount do
      if i == vsClass.selectedConfigIndex then
        setTextColor(unpack(vsClass.tColor.selected));
      else
        setTextColor(unpack(vsClass.tColor.standard));
      end;
      local rText = g_i18n:getText(vsClass.config[i][1]) .. ":";
      local state = tostring(vsClass.config[i][2]);
      if state == "true" then
        state = g_i18n:getText("vs_on");
      else
        state = g_i18n:getText("vs_off");
      end;
      renderText(xPos, yPos, vsClass.tPos.size, rText);
      renderText(xPos + vsClass.tPos.columnWidth, yPos, vsClass.tPos.size, state);
      yPos = yPos - vsClass.tPos.size - vsClass.tPos.spacing;
    end;
  end;
end

function vsClass:draw()
  if g_dedicatedServerInfo ~= nil then
    return;
  end;
  vsClass.drawConfig();
  if vsClass.showDebugOnScreen then
    vsClass:drawDebugText();
  end;
  if vsClass.showSteerables then
    local sCount = table.getn(g_currentMission.steerables);
    if sCount > 0 then
      local xPos = vsClass.tPos.x;
      local yPos = vsClass.tPos.y;
      setTextColor(unpack(vsClass.tColor.standard));
      setTextAlignment(vsClass.tPos.alignment);
      renderText(xPos, yPos + vsClass.tPos.size + vsClass.tPos.spacing + 0.007, vsClass.tPos.size + 0.005, g_i18n:getText("headline"));
      for i = 1, sCount do
        if i == vsClass.selectedIndex then
          if vsClass.selectedLock then
            setTextColor(unpack(vsClass.tColor.locked));
          else
            setTextColor(unpack(vsClass.tColor.selected));
          end;
        elseif g_currentMission.steerables[i].vs_isParked then
          setTextColor(unpack(vsClass.tColor.parked));
        else
          setTextColor(unpack(vsClass.tColor.standard));
        end;
        if g_currentMission.steerables[i].isControlled then
          if not g_currentMission.missionDynamicInfo.isMultiplayer then
            setTextBold(true);
          elseif g_currentMission.steerables[i].controllerName == g_gameSettings.nickname then
            setTextBold(true);
          end;
        else
          setTextBold(false);
        end;
        local showText = true;
        if not vsClass.config[1][2] and string.find(g_currentMission.steerables[i].configFileName, "train/locomotive") then
          showText = false;
        end;
        if not vsClass.config[2][2] and string.find(g_currentMission.steerables[i].configFileName, "train/stationCrane") then
          showText = false;
        end;
        if showText then
          renderText(xPos, yPos, vsClass.tPos.size, vsClass:getFullVehicleName(i));
          yPos = yPos - vsClass.tPos.size - vsClass.tPos.spacing;
        end;
        if yPos < vsClass.borderToTop then
          yPos = vsClass.tPos.y;
          xPos = xPos + vsClass.tPos.columnWidth;
        end;
      end;
    end;
  end;
end

function vsClass:drawDebugText()
  local debText = "";
  local itemsToRemove = {};
  if vsClass.debugOnScreen ~= nil and #vsClass.debugOnScreen > 0 then
    for i,j in ipairs(vsClass.debugOnScreen) do
      if j[2] > 0 then
        debText = debText .. j[1] .. " | ";
        j[2] = j[2]-1;
      else
        table.insert(itemsToRemove, i);
      end;
    end;
    if #itemsToRemove > 0 then
      for i= #itemsToRemove, 1, -1 do
        table.remove(vsClass.debugOnScreen, i);
      end;
    end;
  end;
  setTextColor(unpack(vsClass.tColor.standard));
  setTextAlignment(vsClass.tPos.alignment);
  renderText(0.05, 0.25, vsClass.tPos.size, debText);
end

function vsClass:debPrint(text, fadeTime)
  local fTime = fadeTime or 400;
  local elem = {text, fTime};
  table.insert(vsClass.debugOnScreen, elem);
end

function vsClass:loadMap(name)
  vsClass.vsInitialized = false;
end

function vsClass:deleteMap()
  vsClass.vInitOrder = {};
  vsClass.vUserOrder = {};
  vsClass.vsInitialized = false;
end

function vsClass:mouseEvent(posX, posY, isDown, isUp, button)
end

function vsClass:vsInit()
  if g_dedicatedServerInfo ~= nil then
    return;
  end;
  vsClass.tPos = {};
  vsClass.tPos.x = g_currentMission.inGameMessage.posX;  -- x Position of Textfield, originally hardcoded 0.3
  vsClass.tPos.y = g_currentMission.tutorialStatusBar.y;  -- y Position of Textfield, originally hardcoded 0.9
  vsClass.tPos.size = g_currentMission.ingameNotificationTextSize;  -- TextSize, originally hardcoded 0.018
  vsClass.tPos.spacing = g_currentMission.cruiseControlTextOffsetY;  -- Spacing between lines, originally hardcoded 0.005
  vsClass.tPos.columnWidth = 0.4 * g_aspectScaleX;  -- Space till second column (only if needed), originally hardcoded 0.35
  vsClass.tPos.alignment = RenderText.ALIGN_LEFT;  -- Text Alignment
  vsClass.borderToTop = 1 - vsClass.tPos.y;
  vsClass.userPath = getUserProfileAppPath();
  vsClass.vsBasePath = vsClass.userPath .. "vehicleSort/";
  if g_currentMission.missionDynamicInfo.serverAddress ~= nil then --multiplayer game and player is not the host (dedi already handled above)
    vsClass.vsSavePath = vsClass.vsBasePath .. g_currentMission.missionDynamicInfo.serverAddress .. "/";
  else
    vsClass.vsSavePath = vsClass.vsBasePath .. "savegame" .. g_careerScreen.selectedIndex .. "/";
  end;
  createFolder(vsClass.vsBasePath);
  createFolder(vsClass.vsSavePath);
  vsClass.vsXML = vsClass.vsSavePath .. "v_order.xml";
  vsClass:loadVehicleOrder();
  vsClass.dprint("Vehicle Sort: Initialized.");
end

function vsClass.addVehic(a, b)
  if b.isSteerable then
    local listItem = {};
    listItem.ranking = #vsClass.vInitOrder + 1;
    listItem.id = b.id;
    table.insert(vsClass.vInitOrder, listItem);
    if vsClass.vsInitialized then
      local listItem = {};
      listItem.ranking = #vsClass.vUserOrder + 1;
      listItem.id = b.id;
      table.insert(vsClass.vUserOrder, listItem);
    end;
    b.vs_isParked = false;
  end;
end

function vsClass.removeVehic(a, b)
  if b.isSteerable then
    b.vs_isParked = nil;
    local remIndex = 0;
    local modRank = #vsClass.vUserOrder;
    for i,j in ipairs(vsClass.vUserOrder) do
      if j.id == b.id then
        remIndex = i;
        modRank = j.ranking;
      end;
    end;
    if remIndex > 0 then
      table.remove(vsClass.vUserOrder, remIndex);
    else
      print("Vehicle Sort: Error removing sold vehicle from user list.");
    end;
    for i,j in ipairs(vsClass.vUserOrder) do
      if j.ranking > modRank then
        j.ranking = j.ranking - 1;
      end;
    end;
  end;
end

function vsClass:getAttachment(oAttachment, iNum)
  local sName = "'";
  if vsClass.config[3][2] then
    sName  = sName .. Utils.getNoNil(oAttachment.vs_brandName, "Lizard") .. " ";
  end;
  sName = sName .. Utils.getNoNil(oAttachment.vs_name, "(" .. g_i18n:getText("vs_implement") .. " " .. iNum .. ")");
  if vsClass.config[4][2] then
    if oAttachment.typeDesc ~= nil then
      sName = sName .. " (" .. oAttachment.typeDesc .. ")";
    end;
  end;
  sName = sName .. "'";
  return sName;
end

function vsClass:getFullVehicleName(index)
  if index <= table.getn(g_currentMission.steerables) then
    local oVeh = g_currentMission.steerables[index];
    local sName = "";
    local sConName = oVeh.controllerName;
    if oVeh.vs_isParked or oVeh.nonTabbable then
      sName = "[P] "; -- Prefix for parked or controlled vehicles
    elseif oVeh.isHired then --credit for determining AI control names: vehicle groups switcher mod
      sName = "(" .. g_i18n:getText("hired") .. ") ";
    elseif (oVeh.getIsCourseplayDriving ~= nil and oVeh:getIsCourseplayDriving()) then --courseplay mod
      sName = "(" .. g_i18n:getText("courseplay") .. ") ";
    elseif (oVeh.modFM ~= nil and oVeh.modFM.FollowVehicleObj ~= nil) then
      sName = "(" .. g_i18n:getText("followme") .. ") ";
    elseif oVeh.isControlled then
      if vsClass.config[5][2] and sConName ~= "Unknown" and sConName ~= "" and sConName ~= nil then
        sName = "(" .. sConName .. ") ";
      end;
    end;
    if string.find(oVeh.configFileName, "train/locomotive") then
      sName = sName .. g_i18n:getText("vs_train");
      if vsClass.config[6][2] then  -- Fill-Level-Display active?
        local f, c = vsClass.calculateFillLevel(oVeh);
        if vsClass.config[8][2] or f > 0 then -- Empty vehicles shall be shown or vehicle is not empty
          if vsClass.config[7][2] and c > 0 then -- Fill-Level->Total Values
            local p = vsClass.calcPercentage(f, c);
            sName = sName .. " (" .. tostring(p) .. "%)";
          elseif c > 0 then -- Fill-Level-->Percentages
            sName = sName .." (" .. tostring(math.floor(f)) .. "/" .. tostring(c) .. ")";
          end;
        end;
      end;
      return sName;
    elseif string.find(oVeh.configFileName, "train/stationCrane") then
      sName = sName .. g_i18n:getText("vs_crane");
      return sName;
    end;
    if vsClass.config[3][2] then -- steerable
      sName = sName .. oVeh.vs_brandName .. " ";
    end;
    sName = sName .. oVeh.vs_name;
    if vsClass.config[4][2] then
      if oVeh.typeDesc ~= nil then
        sName = sName .. " (" .. oVeh.typeDesc .. ")";
      end;
    end;
    if (oVeh.attachedImplements[1] ~= nil and oVeh.attachedImplements[1].object ~= nil) then -- first attachment
      sName = sName .. " - " .. g_i18n:getText("with") .. " " .. vsClass:getAttachment(oVeh.attachedImplements[1].object, 1);
      if (oVeh.attachedImplements[2] ~= nil and oVeh.attachedImplements[2].object ~= nil) then -- second attachment
        sName = sName .. " & " .. vsClass:getAttachment(oVeh.attachedImplements[2].object, 2);
      end;
    end;
    if vsClass.config[6][2] then  -- Fill-Level-Display active?
      local f, c = vsClass.calculateFillLevel(oVeh);
      if vsClass.config[8][2] or f > 0 then -- Empty vehicles shall be shown or vehicle is not empty
        if vsClass.config[7][2] and c > 0 then -- Fill-Level->Total Values
          local p = vsClass.calcPercentage(f, c); -- Fill-Level-Display
          sName = sName .. " (" .. tostring(p) .. "%)";
        elseif c > 0 then -- Fill-Level-->Percentages
          sName = sName .. " (" .. tostring(math.floor(f)) .. "/" .. tostring(c) .. ")";
        end;
      end;
    end;
    return sName;
  else
    return nil;
  end;
end

function vsClass:saveVehicleOrder()
  vsClass.saveFile = createXMLFile("vsClass.saveFile", vsClass.vsXML, "vOrder");
  vsClass.dprint("Saving config");
  for i = 1, #vsClass.config do
    setXMLBool(vsClass.saveFile, "vOrder.vsConfig#" .. vsClass.config[i][1],vsClass.config[i][2])
  end;
  vsClass.dprint(#vsClass.vUserOrder .. " needs to be saved.");
  for i = 1, #vsClass.vUserOrder do
    vsClass.dprint("Saving vehicle " .. i);
    setXMLInt(vsClass.saveFile, "vOrder.vehicle" .. i .. "#id", vsClass.vUserOrder[i].ranking);
    setXMLBool(vsClass.saveFile, "vOrder.vehicle" .. i .. "#parked", g_currentMission.steerables[i].nonTabbable);
  end;
  saveXMLFile(vsClass.saveFile);
end

function vsClass:loadVehicleOrder()
  if g_dedicatedServerInfo ~= nil then
    return;
  end;
  if fileExists(vsClass.vsXML) then
    vsClass.saveFile = loadXMLFile("vsClass.loadFile", vsClass.vsXML);
  else
    vsClass.saveFile = createXMLFile("vsClass.loadFile", vsClass.vsXML, "vOrder");
  end;
  if not hasXMLProperty(vsClass.saveFile, "vOrder") then
    for i = 1, table.getn(g_currentMission.steerables) do
      local listItem = {};
      listItem.ranking = i;
      listItem.id = g_currentMission.steerables[i].id;
      vsClass.vUserOrder[i]= listItem;
    end;
  else
    local vIndex = 1;
    local savedIDs = {};
    local savedParkStates = {};
    while hasXMLProperty(vsClass.saveFile, "vOrder.vehicle" .. vIndex .. "#id") do
      table.insert(savedIDs, getXMLInt(vsClass.saveFile, "vOrder.vehicle" .. vIndex .. "#id"));
      table.insert(savedParkStates, getXMLBool(vsClass.saveFile, "vOrder.vehicle" .. vIndex .. "#parked"));
      vsClass.dprint("Recognized Order Index: " .. savedIDs[vIndex]);
      vIndex = vIndex + 1;
    end;
    local vTSize = table.getn(g_currentMission.steerables);
    if #savedIDs == vTSize then
      vsClass.dprint("Size Match savedIDs (" .. #savedIDs .. ") <-> globalVehicleTableSize (" .. vTSize .. ").");
      for i = 1, vTSize do
        vsClass.dprint("Moving away from Table Position " .. i);
        local listItem = {};
        listItem.ranking = tonumber(savedIDs[i]);
        vsClass.vUserOrder[i] = listItem;
        local eBreaker = 0;
        while vsClass.vInitOrder[i].ranking ~= vsClass.vUserOrder[i].ranking and eBreaker <= (vTSize + 10) do
          vsClass.dprint("Moving ID " .. vsClass.vInitOrder[i].ranking .. " - eBreaker: " .. eBreaker);
          eBreaker = eBreaker + 1;
          local tempIndex = vsClass.vInitOrder[i];
          local tempVehicle = g_currentMission.steerables[i];
          table.remove(vsClass.vInitOrder, i);
          table.remove(g_currentMission.steerables, i);
          table.insert(vsClass.vInitOrder, vTSize, tempIndex);
          table.insert(g_currentMission.steerables, vTSize, tempVehicle);
        end;
      end;
      for i = 1, vTSize do
        vsClass.vUserOrder[i].id = g_currentMission.steerables[i].id;
      end;
      for index, isParked in ipairs(savedParkStates) do
        g_currentMission.steerables[index].nonTabbable = isParked;
      end;
    else
      print("Vehicle Sort: Vehicle order config file not present or invalid, using default vehicle order.");
      for i = 1, table.getn(g_currentMission.steerables) do
        local listItem = {};
        listItem.ranking = i;
        listItem.id = g_currentMission.steerables[i].id;
        vsClass.vUserOrder[i] = listItem;
      end;
    end;
  end;
  if not hasXMLProperty(vsClass.saveFile, "vOrder.vsConfig") then
    vsClass.dprint("No config file found.");
  else
    vsClass.dprint("Config file found.");
    for i = 1, #vsClass.config do
      local aBool = getXMLBool(vsClass.saveFile, "vOrder.vsConfig#" .. vsClass.config[i][1] );
      if aBool ~= nil then
        vsClass.config[i][2] = aBool;
      end;
    end;
  end;
end

function vsClass.calculateFillLevel(vehic, d)
  local fillLev = 0;
  local cap = 0;
  local depth = 0;
  if d ~= nil then
    depth = d;
  end;
  --vsClass.dprint("calcFL-Depth: " .. tostring(depth));
  depth = depth + 1;
  if vehic ~= nil then
    if vehic.getFillLevel ~= nil then
      fillLev = fillLev + vehic:getFillLevel();
    end;
    if vehic.getCapacity ~= nil then
      cap = cap + vehic:getCapacity();
    end;
    for _,imp in pairs(vehic.attachedImplements) do
      if imp.object ~= nil then
        --vsClass.dprint("Checking attachment: " .. tostring(imp.object.typeDesc));
        local f, c = vsClass.calculateFillLevel(imp.object, depth);
        if f ~= nil and c ~= nil then
          fillLev = fillLev + f;
          cap = cap + c;
        end;
      end;
    end;
  end;
  return fillLev, cap;
end

function vsClass.calcPercentage(actualVal, maxVal)
  local perc = actualVal / maxVal * 100;
  return (math.floor(perc * 10)/10);
end

function vsClass.dprint(aString)
  if g_dedicatedServerInfo == nil and vsClass.DEBUG then
    if type(aString) == "table" then
      vsClass.printTableData(aString);
    else
      print("******* Vehicle Sort Debug Output: *******:  " .. tostring(aString));
    end;
  end;
end

function vsClass.printTableData(aTable)
  if type(aTable) ~= "table" then
    print("Vehicle Sort: ===Element " .. tostring(aTable) .. " is not a table.");
  else
    print("Vehicle Sort: *********************************************************");
    print("Vehicle Sort: Printing table data: (" .. tostring(aTable) .. ")" );
    print("Vehicle Sort: #:   Key  |  Value");
    local output = "";
    local id = 1;
    for i,j in pairs(aTable) do
      print("Vehicle Sort: tData: " .. tostring(id) .. "  |  " .. tostring(i) .. "  |  " .. tostring(j));
      id = id + 1;
    end;
    print("Vehicle Sort: *********************************************************");
  end;
end

function vsClass.setToolById(self, superFunc, toolId, noEventSend) --credit: Xentro, GameExtension
  if not vsClass.showSteerables and not vsClass.showConfig then
    superFunc(self, toolId, noEventSend);
  else
    superFunc(self, 0, true); --do not switch to chainsaws while vehiclesort is displayed
  end;
end;

function vsClass.zoomSmoothly(self, superFunc, offset)
  if vsClass.showConfig or vsClass.showSteerables then
    superFunc(self, 0); --TODO find a better way to prevent camera zoom while vs is displayed
  else
    superFunc(self, offset);
  end;
end

if g_dedicatedServerInfo == nil then
  Steerable.postLoad  = Utils.appendedFunction(Steerable.postLoad, vsClass.loadSteerable);
  Attachable.postLoad = Utils.appendedFunction(Attachable.postLoad, vsClass.loadAttachable);
  vsClass:superClass():superClass().addVehicle = Utils.appendedFunction(vsClass:superClass():superClass().addVehicle, vsClass.addVehic);
  vsClass:superClass():superClass().removeVehicle = Utils.appendedFunction(vsClass:superClass():superClass().removeVehicle, vsClass.removeVehic);
  Player.setToolById = Utils.overwrittenFunction(Player.setToolById, vsClass.setToolById);
  VehicleCamera.zoomSmoothly = Utils.overwrittenFunction(VehicleCamera.zoomSmoothly, vsClass.zoomSmoothly);
end;

print(string.format("Script loaded: VehicleSort.lua (v%s)", vsClass.version));
