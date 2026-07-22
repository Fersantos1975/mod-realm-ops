local ADDON = ...

-- RealmOps v0.3.0-dev1
-- Target: WoW 3.3.5a / AzerothCore. All server commands live here so that
-- branch-specific command names can be changed without touching the UI.
local CMD = {
  revive = ".revive", repair = ".gear repair", summon = ".summon",
  appear = ".appear", combatStop = ".combatstop", save = ".save",
  npcInfo = ".npc info", npcKill = ".die", npcRespawn = ".respawn",
  npcMove = ".npc move", npcNear = ".npc near", npcAdd = ".npc add %d",
  npcDelete = ".npc delete",
  questLookup = ".lookup quest %s", questStatus = ".quest status %d",
  questAdd = ".quest add %d", questComplete = ".quest complete %d",
  questReward = ".quest reward %d", questRemove = ".quest remove %d",
  gps = ".gps", tele = ".tele %s", itemLookup = ".lookup item %s",
  itemAdd = ".additem %d %d", itemRemove = ".additem %d -%d",
  instanceList = ".instance listbinds",
  instanceUnbind = ".instance unbind %s %d",
  instanceUnbindAll = ".instance unbind all",
  auditSearch = ".realmops instance search %s",
  auditGroup = ".realmops instance audit %d %d",
  questSearch = ".realmops quest search %s",
  questInfo = ".realmops quest info %d",
  questAudit = ".realmops quest audit %d",
  version = ".realmops version",
}

local C = {
  bg={0.055,0.06,0.07,0.97}, panel={0.105,0.11,0.13,0.98},
  border={0.36,0.39,0.44,1}, button={0.16,0.17,0.20,1},
  hover={0.25,0.27,0.31,1}, selected={0.12,0.36,0.50,1},
  gold={1,0.82,0,1}, white={0.92,0.92,0.92,1}, red={1,0.30,0.25,1},
}

local main, mini, minimapButton, content, statusText, optionsPanel
local tabs, pages, activeTab = {}, {}, "Character"
local lookup = { kind=nil, expires=0, results={} }
local questIdBox, itemIdBox
local activeInput
local questUI={results={},rows={},info=nil,chain={},detailText=nil,chainText=nil,chainScroll=nil,chainChild=nil,summary=nil,
  auditMembers={},auditActive=false,auditQuest=nil,detailScroll=nil,detailChild=nil}
local compatUI={data=nil,text=nil}
local instanceUI={my={},target={},captureUntil=0,myRows={},targetRows={},myOffset=0,targetOffset=0,mapBox=nil,diffBox=nil,targetLabel=nil}
local auditUI={search={},members={},searchRows={},memberRows={},filterButtons={},filtered={},mapBox=nil,diffBox=nil,summary=nil,scroll=nil,scrollChild=nil,horizontal=nil,filter="ALL",lastMap=nil,lastDifficulty=nil,reportEdit=nil}
local eligibilityUI={searchRows={},memberRows={},selected=nil,title=nil,subtitle=nil,ready=nil,blocked=nil,warnings=nil,requirementTexts={},chainText=nil,detailText=nil,recommendation=nil,mapBox=nil,diffBox=nil,searchBox=nil,summary=nil}
local exportFrame, exportEdit
local ShowSelectableReport
local defaults={
  startMinimized=true,showMinimap=true,showMini=true,mbfCompatibility=true,scale=1,
  confirmCommands=true,hideAuditChat=true,defaultDifficulty=0,
  auditTooltips=true,wrapAuditReasons=true,mouseWheelAudit=true,problemsFirst=false,
  rememberAuditFilter=true,autoReaudit=false,confirmResetSelected=true,confirmResetAll=true,
  warnNoTarget=true,compactAuditRows=false,auditFontSize=10,shiftClickInsert=true,
}
local ADDON_VERSION="0.3.0-dev1"
local PROTOCOL_VERSION="1"
local TESTED_CORE="bf25eae704f5"
local TESTED_PLAYERBOTS="3fa1c1e49f8f"

local function Settings()
  RealmOpsDB.settings=RealmOpsDB.settings or {}
  for key,value in pairs(defaults) do if RealmOpsDB.settings[key]==nil then RealmOpsDB.settings[key]=value end end
  return RealmOpsDB.settings
end

local function Print(msg, errorColor)
  DEFAULT_CHAT_FRAME:AddMessage((errorColor and "|cffff5555RealmOps|r: " or "|cff33ff99RealmOps|r: ") .. tostring(msg))
end

local function SetStatus(msg, bad)
  if statusText then
    statusText:SetText(msg or "Ready")
    statusText:SetTextColor(unpack(bad and C.red or C.white))
  end
end

local function SendCommand(cmd)
  if not cmd or cmd == "" then return end
  SendChatMessage(cmd, "SAY")
  RealmOpsDB.history = RealmOpsDB.history or {}
  table.insert(RealmOpsDB.history, 1, cmd)
  while #RealmOpsDB.history > 20 do table.remove(RealmOpsDB.history) end
  SetStatus("Sent: " .. cmd)
end

local function Backdrop(f, color)
  f:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  f:SetBackdropColor(unpack(color or C.bg)); f:SetBackdropBorderColor(unpack(C.border))
end

local function Label(parent, text, template)
  local x=parent:CreateFontString(nil,"OVERLAY",template or "GameFontNormal")
  x:SetText(text); x:SetTextColor(unpack(C.gold)); return x
end

local function Button(parent, text, w, h, click, tip)
  local b=CreateFrame("Button",nil,parent); b:SetWidth(w); b:SetHeight(h); b:SetText(text)
  b:SetNormalFontObject(GameFontNormalSmall); b:SetHighlightFontObject(GameFontHighlightSmall)
  b:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
  b:SetBackdropColor(unpack(C.button)); b:SetBackdropBorderColor(unpack(C.border)); b:SetScript("OnClick",click)
  b:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover)); if tip then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(text,1,.82,0); GameTooltip:AddLine(tip,1,1,1,true); GameTooltip:Show() end end)
  b:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(C.button)); GameTooltip:Hide() end)
  return b
end

local function Edit(parent, w, numeric)
  -- InputBoxTemplate only draws separate left/right caps on some 3.3.5a
  -- clients. A custom backdrop gives the field a clear, complete border.
  local e=CreateFrame("EditBox",nil,parent); e:SetWidth(w); e:SetHeight(24); e:SetAutoFocus(false)
  e:SetFontObject(ChatFontNormal); e:SetTextInsets(7,7,0,0)
  e:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
  e:SetBackdropColor(0.035,0.04,0.05,1); e:SetBackdropBorderColor(unpack(C.border))
  e:SetTextColor(unpack(C.white))
  if numeric then e:SetNumeric(true) end
  e.realmOpsNumeric=numeric and true or false
  e:SetScript("OnEditFocusGained",function(self) activeInput=self; self:SetBackdropBorderColor(unpack(C.gold)); self:HighlightText() end)
  e:SetScript("OnEditFocusLost",function(self) if activeInput==self then activeInput=nil end; self:SetBackdropBorderColor(unpack(C.border)); self:HighlightText(0,0) end)
  e:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  e:SetScript("OnEnterPressed",function(self) self:ClearFocus() end); return e
end

local originalInsertLink=ChatEdit_InsertLink
local function InsertRealmOpsLink(link)
  if not activeInput or not activeInput:HasFocus() or not Settings().shiftClickInsert then return false end
  local linkType,id=link:match("|H([^:|]+):([^:|]+)")
  local player=link:match("|Hplayer:([^:|]+)")
  if activeInput.realmOpsExpected and linkType~=activeInput.realmOpsExpected then
    SetStatus("This field accepts "..activeInput.realmOpsExpected.." links, not "..tostring(linkType or "unknown").." links.",true)
    return true
  end
  if activeInput.realmOpsNumeric then
    local numericId=tonumber(id)
    if not numericId then SetStatus("This link does not contain a numeric ID.",true); return true end
    activeInput:SetText(tostring(numericId)); activeInput:HighlightText(); SetStatus("Inserted "..tostring(linkType).." ID "..numericId); return true
  end
  if player then activeInput:SetText(player); activeInput:HighlightText(); SetStatus("Inserted player "..player); return true end
  if activeInput.realmOpsPlain then
    local label=link:match("|h%[([^%]]+)%]|h") or link
    activeInput:SetText(label); activeInput:HighlightText(); SetStatus("Inserted "..tostring(linkType or "game").." name"); return true
  end
  activeInput:Insert(link); SetStatus("Inserted "..tostring(linkType or "game").." link"); return true
end

if originalInsertLink then
  ChatEdit_InsertLink=function(link)
    if InsertRealmOpsLink(link) then return true end
    return originalInsertLink(link)
  end
end

local function PositiveId(box, label)
  local n=tonumber(box:GetText() or "")
  if not n or n < 1 or n ~= math.floor(n) then SetStatus("Enter a valid "..label.." ID.",true); return end
  return n
end

local function NonEmpty(box, label)
  local s=(box:GetText() or ""):match("^%s*(.-)%s*$")
  if s=="" then SetStatus("Enter "..label..".",true); return end
  return s
end

local pendingCommand, pendingAfter
StaticPopupDialogs["REALMOPS_CONFIRM"]={text="Execute this command?\n%s",button1=YES,button2=NO,timeout=0,whileDead=1,hideOnEscape=1,
  OnAccept=function() if pendingCommand then SendCommand(pendingCommand); pendingCommand=nil; local after=pendingAfter; pendingAfter=nil; if after then after() end end end,
  OnCancel=function() pendingCommand=nil; pendingAfter=nil end}
local function Confirm(cmd, enabled, after)
  if enabled==nil then enabled=Settings().confirmCommands end
  if not enabled then SendCommand(cmd); if after then after() end; return end
  pendingCommand=cmd; pendingAfter=after; StaticPopup_Show("REALMOPS_CONFIRM",cmd)
end

local function After(seconds,callback)
  local elapsed=0; local timer=CreateFrame("Frame")
  timer:SetScript("OnUpdate",function(self,delta) elapsed=elapsed+delta; if elapsed>=seconds then self:SetScript("OnUpdate",nil); callback() end end)
end

local function SavePoint(f,prefix)
  local point,_,rel,x,y=f:GetPoint(); RealmOpsDB[prefix.."Point"]=point; RealmOpsDB[prefix.."Rel"]=rel; RealmOpsDB[prefix.."X"]=x; RealmOpsDB[prefix.."Y"]=y
end
local function Movable(f,prefix)
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",function(self) self._dragged=true; self:StartMoving() end)
  f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); SavePoint(self,prefix) end)
end
local function RestorePoint(f,prefix,point,x,y)
  f:SetPoint(RealmOpsDB[prefix.."Point"] or point,UIParent,RealmOpsDB[prefix.."Rel"] or point,RealmOpsDB[prefix.."X"] or x,RealmOpsDB[prefix.."Y"] or y)
end

local function TargetCreatureEntry()
  local guid=UnitGUID("target")
  if not guid then return nil,"Select a creature first." end
  if UnitIsPlayer("target") then return nil,"The selected target is a player." end
  -- 3.3.5 creature GUID: 0xF130 + 6 hex entry digits + 6 hex counter digits.
  if not guid:find("^0xF130") and not guid:find("^0xF140") then return nil,"Target is not a creature or pet." end
  local id=tonumber(guid:sub(7,12),16)
  if not id or id<1 then return nil,"Could not read the creature entry." end
  return id
end

local function AddField(parent,label,x,y,w,numeric)
  local l=Label(parent,label,"GameFontNormalSmall"); l:SetPoint("TOPLEFT",x,y)
  local e=Edit(parent,w,numeric); e:SetPoint("TOPLEFT",x,y-18); return e
end

local function AddCommandGrid(parent, defs, startY)
  for i,d in ipairs(defs) do
    local col=(i-1)%3; local row=math.floor((i-1)/3)
    local b=Button(parent,d[1],150,28,d[2],d[3]); b:SetPoint("TOPLEFT",18+col*164,startY-row*40)
  end
end

local function NewPage(name)
  local p=CreateFrame("Frame",nil,content); p:SetAllPoints(content); p:Hide(); pages[name]=p; return p
end

local function SelectTab(name)
  activeTab=name; RealmOpsDB.activeTab=name
  for n,p in pairs(pages) do if n==name then p:Show() else p:Hide() end end
  for n,b in pairs(tabs) do b:SetBackdropColor(unpack(n==name and C.selected or C.button)) end
  SetStatus(name.." tools")
end

local function BuildCharacter()
  local p=NewPage("Character"); local h=Label(p,"Character commands"); h:SetPoint("TOPLEFT",18,-18)
  AddCommandGrid(p,{
    {"Revive",function() SendCommand(CMD.revive) end,"Revive selected player or yourself"},
    {"Repair",function() SendCommand(CMD.repair) end,"Repair selected player's equipment"},
    {"Summon",function() SendCommand(CMD.summon) end,"Summon selected player"},
    {"Appear",function() SendCommand(CMD.appear) end,"Teleport to selected player"},
    {"Combat Stop",function() SendCommand(CMD.combatStop) end,"Stop combat for target or yourself"},
    {"Save",function() SendCommand(CMD.save) end,"Save your character"},
  },-48)
  local note=Label(p,"Commands use your current target when AzerothCore supports target selection.","GameFontHighlightSmall"); note:SetTextColor(unpack(C.white)); note:SetPoint("TOPLEFT",18,-145)
end

local function BuildNPC()
  local p=NewPage("NPC"); local h=Label(p,"Creature commands"); h:SetPoint("TOPLEFT",18,-18)
  local entry=AddField(p,"Creature entry ID",18,-56,145,true)
  Button(p,"Use Target",120,24,function() local id,err=TargetCreatureEntry(); if not id then SetStatus(err,true); return end; entry:SetText(id); SetStatus("Creature entry: "..id) end,"Read entry ID from selected creature"):SetPoint("TOPLEFT",180,-73)
  Button(p,"Add NPC",120,24,function() local id=PositiveId(entry,"creature"); if id then SendCommand(string.format(CMD.npcAdd,id)) end end,"Spawn creature at your position"):SetPoint("TOPLEFT",315,-73)
  AddCommandGrid(p,{
    {"NPC Info",function() SendCommand(CMD.npcInfo) end,"Show selected creature information"},
    {"Kill",function() SendCommand(CMD.npcKill) end,"Kill selected unit"},
    {"Respawn",function() SendCommand(CMD.npcRespawn) end,"Respawn selected creature"},
    {"Move Here",function() Confirm(CMD.npcMove) end,"Move selected spawn to your position"},
    {"NPC Near",function() SendCommand(CMD.npcNear) end,"List nearby creature spawns"},
    {"Delete NPC",function() Confirm(CMD.npcDelete) end,"Permanently delete selected creature spawn"},
  },-130)
end

local resultRows={quest={},item={}}
local function RenderResults()
  local rows=resultRows[lookup.kind] or {}
  for i,row in ipairs(rows) do
    local r=lookup.results[i]
    if r then
      row.id=r.id; row.kind=lookup.kind
      row.label:SetText(r.link or r.title or (lookup.kind.." "..r.id))
      row:Show()
    else
      row.id=nil; row.label:SetText(""); row:Hide()
    end
  end
end
local function StoreLookupResult(id,title,link,suffix)
  id=tonumber(id)
  if not id or id<1 then return end
  for _,r in ipairs(lookup.results) do if r.id==id then return end end
  if #lookup.results>=5 then return end
  title=(title or ""):gsub("^%[",""):gsub("%]$","")
  suffix=(suffix or ""):match("^%s*(.-)%s*$")
  local display=link
  if not display or display=="" then
    display=tostring(id).." - ["..title.."]"
    if suffix~="" then display=display.." "..suffix end
  end
  table.insert(lookup.results,{id=id,title=title,link=display})
  RenderResults()
  SetStatus(#lookup.results.." "..lookup.kind.." result(s) captured")
end
local function BeginLookup(kind,cmd)
  lookup.kind=kind; lookup.results={}; lookup.expires=GetTime()+5; RenderResults(); SendCommand(cmd); SetStatus("Collecting "..kind.." results for 5 seconds...")
end
local function AddResultsPanel(parent,kind)
  local box=CreateFrame("Frame",nil,parent); box:SetPoint("TOPLEFT",18,-148); box:SetWidth(478); box:SetHeight(142); Backdrop(box,C.panel)
  local title=Label(box,"Lookup results — click one to select it","GameFontNormalSmall"); title:SetPoint("TOPLEFT",9,-8)
  for i=1,5 do
    local row=Button(box,"",458,20,function(self)
      if self.kind=="quest" then questIdBox:SetText(self.id) else itemIdBox:SetText(self.id) end
      SetStatus("Selected "..self.kind.." ID "..self.id)
    end)
    -- Use our own FontString: Button:SetText is unreliable for dynamically
    -- updated text on some unmodified 3.3.5a clients.
    row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    row.label:SetPoint("LEFT",7,0); row.label:SetPoint("RIGHT",-7,0)
    row.label:SetJustifyH("LEFT"); row.label:SetTextColor(unpack(C.gold))
    row:SetPoint("TOPLEFT",9,-27-(i-1)*21); row:Hide(); resultRows[kind][i]=row
  end
end

local function FactionText(faction)
  if faction=="ALLIANCE" then return "|cff5599ffAlliance|r" end
  if faction=="HORDE" then return "|cffff5555Horde|r" end
  if faction=="BOTH" then return "|cffffff55Both|r" end
  return "|cffaaaaaaUnknown|r"
end

local function EligibilityText(value)
  if value=="AVAILABLE" then return "|cff55ff55AVAILABLE|r" end
  if value=="BLOCKED" then return "|cffff5555BLOCKED|r" end
  if value=="REWARDED" then return "|cffaaaaaaREWARDED|r" end
  if value=="COMPLETE" then return "|cff55ff55COMPLETE|r" end
  if value=="ACTIVE" then return "|cffffff55ACTIVE|r" end
  return "|cffffff55"..tostring(value or "UNKNOWN").."|r"
end

local function RenderQuest()
  for i,row in ipairs(questUI.rows) do
    local r=questUI.results[i]
    if r then
      row.id=tonumber(r.id)
      row.text:SetText(string.format("%s  [%s] %s\n%s  •  level %s",r.id or "?",FactionText(r.faction),r.title or "Unknown",EligibilityText(r.eligibility),r.min or "?"))
      row:Show()
    else row.id=nil; row:Hide() end
  end

  if questUI.info and questUI.detailText then
    local q=questUI.info
    questUI.detailText:SetText(string.format(
      "%s\n|cffffffff%s|r\nChecked player: |cffffffff%s|r\n\nFaction: %s\nEligibility: %s\nReason: |cffffffff%s|r\n\nMinimum level: |cffffffff%s|r   Quest level: |cffffffff%s|r\nType: |cffffffff%s|r   Repeatable: |cffffffff%s|r\nCharacter status: |cffffffff%s|r\nRequired reputation: |cffffffff%s|r\nRequired items: |cffffffff%s|r\nStarts at: |cffffffff%s|r\nEnds at: |cffffffff%s|r",
      q.id or "?",q.title or "Unknown",q.player or UnitName("player") or "Unknown",FactionText(q.faction),EligibilityText(q.eligibility),q.reason or "Unknown",
      q.min or "?",q.level or "?",q.type or "Normal",q.repeatable or "no",q.status or "NONE",q.reputation or "None",q.items or "None",q.starters or "Not listed",q.enders or "Not listed"))
  elseif questUI.detailText then
    questUI.detailText:SetText("Select a search result or enter a quest ID and click Details.")
  end

  if questUI.chainText then
    local lines={}
    if questUI.auditActive then
      table.insert(lines,"|cffffd100Quest group audit|r")
      if #questUI.auditMembers==0 then table.insert(lines,"Waiting for group results...") end
      for _,r in ipairs(questUI.auditMembers) do
        local color=r.result=="PASS" and "|cff55ff55" or (r.result=="OFFLINE" and "|cffaaaaaa" or "|cffff7777")
        table.insert(lines,string.format("%s%s|r  %s  •  %s",color,r.result or "?",r.name or "Unknown",r.status or "?"))
        table.insert(lines,"   |cffdddddd"..(r.reason or "No reason").."|r")
      end
    else
      table.insert(lines,"|cffffd100Quest chain inspector|r")
      if #questUI.chain==0 then table.insert(lines,"No linked prerequisite/next quests reported.") end
      for _,r in ipairs(questUI.chain) do
      local arrow=r.direction=="NEXT" and "->" or "<-"
      local state=r.status=="REWARDED" and "|cff55ff55[REWARDED]|r"
        or (r.status=="COMPLETE" and "|cff55ff55[COMPLETE]|r"
        or (r.status=="ACTIVE" and "|cffffff55[ACTIVE]|r"
        or (r.eligibility=="AVAILABLE" and "|cff55ff55[AVAILABLE]|r" or "|cffff7777[BLOCKED]|r")))
      local depth=math.max(0,tonumber(r.depth) or 1)-1
      local indent=string.rep("  ",math.min(depth,6))
      table.insert(lines,string.format("%s%s %s %s [%s] • %s • %s",indent,state,arrow,r.title or "Unknown",r.id or "?",FactionText(r.faction),r.required or "linked"))
      if r.reason and r.reason~="" and r.eligibility~="AVAILABLE" and r.status~="REWARDED" then table.insert(lines,indent.."   |cffaaaaaa"..r.reason.."|r") end
      end
    end
    questUI.chainText:SetText(table.concat(lines,"\n"))
    if questUI.chainChild then local h=math.max(120,#lines*15+12); questUI.chainChild:SetHeight(h); questUI.chainText:SetHeight(h) end
  end
  if questUI.summary then questUI.summary:SetText(#questUI.results.." result(s)") end
end

local function RequestQuestInfo(id)
  questUI.info=nil; questUI.chain={}; questUI.auditActive=false; questUI.auditMembers={}; RenderQuest()
  SendCommand(string.format(CMD.questInfo,id)); SetStatus("Loading quest "..id.." details...")
end

local function RunQuestAudit()
  local id=PositiveId(questIdBox,"quest")
  if not id then return end
  questUI.auditMembers={}; questUI.auditActive=true; questUI.auditQuest=id; RenderQuest()
  SendCommand(string.format(CMD.questAudit,id)); SetStatus("Auditing quest "..id.." for the group...")
end

local function ShowQuestExport()
  if not questUI.info and #questUI.auditMembers==0 then SetStatus("Load quest details or run a group audit before exporting.",true); return end
  local lines={"RealmOps quest report"}
  if questUI.info then
    local q=questUI.info
    table.insert(lines,string.format("Quest: %s [%s]",q.title or "Unknown",q.id or "?"))
    table.insert(lines,string.format("Checked player: %s | Status: %s | Eligibility: %s",q.player or "Unknown",q.status or "?",q.eligibility or "?"))
    table.insert(lines,"Reason: "..(q.reason or "None")); table.insert(lines,"")
  end
  if #questUI.auditMembers>0 then
    table.insert(lines,"Group audit")
    for _,r in ipairs(questUI.auditMembers) do table.insert(lines,string.format("%s | %s | %s | %s",r.result or "?",r.name or "Unknown",r.status or "?",r.reason or "No reason")) end
  else
    table.insert(lines,"Quest chain")
    for _,r in ipairs(questUI.chain) do table.insert(lines,string.format("%s | %s [%s] | %s",r.direction or "?",r.title or "Unknown",r.id or "?",r.reason or r.eligibility or "")) end
  end
  ShowSelectableReport("RealmOps quest report",table.concat(lines,"\n"))
end

local function BuildQuest()
  local p=NewPage("Quest"); local titleBox=AddField(p,"Quest title",12,-12,285,false); titleBox.realmOpsExpected="quest"; titleBox.realmOpsPlain=true
  Button(p,"Search",95,24,function()
    local s=NonEmpty(titleBox,"a quest title")
    if s then questUI.results={}; questUI.info=nil; questUI.chain={}; RenderQuest(); SendCommand(string.format(CMD.questSearch,s)); SetStatus("Searching quests with faction data...") end
  end,"Search through the RealmOps server module"):SetPoint("TOPLEFT",310,-29)
  questIdBox=AddField(p,"Quest ID",420,-12,85,true); questIdBox.realmOpsExpected="quest"
  Button(p,"Details",95,24,function() local id=PositiveId(questIdBox,"quest"); if id then RequestQuestInfo(id) end end,"Show faction, eligibility, requirements, and chain"):SetPoint("TOPLEFT",515,-29)
  Button(p,"Audit Group",95,20,RunQuestAudit,"Check this quest for every online group or raid member"):SetPoint("TOPLEFT",420,-58)
  Button(p,"Export",95,20,ShowQuestExport,"Open a selectable quest report for copying"):SetPoint("TOPLEFT",515,-58)

  local actions={{"Status",CMD.questStatus,false},{"Add",CMD.questAdd,false},{"Complete",CMD.questComplete,false},{"Reward",CMD.questReward,true},{"Remove",CMD.questRemove,true}}
  for i,a in ipairs(actions) do
    Button(p,a[1],105,24,function() local id=PositiveId(questIdBox,"quest"); if id then local cmd=string.format(a[2],id); if a[3] then Confirm(cmd) else SendCommand(cmd) end end end):SetPoint("TOPLEFT",12+(i-1)*121,-72)
  end

  local results=CreateFrame("Frame",nil,p); results:SetPoint("TOPLEFT",12,-108); results:SetWidth(285); results:SetHeight(267); Backdrop(results,C.panel)
  local rh=Label(results,"Quest matches","GameFontNormalSmall"); rh:SetPoint("TOPLEFT",8,-7)
  questUI.summary=results:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); questUI.summary:SetPoint("TOPRIGHT",-8,-7); questUI.summary:SetTextColor(unpack(C.white))
  for i=1,6 do
    local row=Button(results,"",269,36,function(self) if self.id then questIdBox:SetText(self.id); RequestQuestInfo(self.id) end end)
    row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",6,-3); row.text:SetPoint("BOTTOMRIGHT",-6,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP")
    row:SetPoint("TOPLEFT",8,-27-(i-1)*38); row:Hide(); questUI.rows[i]=row
  end

  local details=CreateFrame("Frame",nil,p); details:SetPoint("TOPLEFT",305,-108); details:SetPoint("BOTTOMRIGHT",-12,12); Backdrop(details,C.panel)
  local dh=Label(details,"Quest information","GameFontNormalSmall"); dh:SetPoint("TOPLEFT",8,-7)
  local detailScroll=CreateFrame("ScrollFrame","REALMOPS_QuestDetailScroll",details,"UIPanelScrollFrameTemplate"); detailScroll:SetPoint("TOPLEFT",8,-28); detailScroll:SetPoint("TOPRIGHT",-28,-28); detailScroll:SetHeight(172); detailScroll:EnableMouseWheel(true); questUI.detailScroll=detailScroll
  questUI.detailText=CreateFrame("EditBox",nil,detailScroll); questUI.detailText:SetMultiLine(true); questUI.detailText:SetAutoFocus(false); questUI.detailText:SetFontObject(GameFontHighlightSmall); questUI.detailText:SetWidth(278); questUI.detailText:SetHeight(172); questUI.detailText:SetTextColor(unpack(C.white)); detailScroll:SetScrollChild(questUI.detailText)
  questUI.detailText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end); detailScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*45)) end)
  local chainScroll=CreateFrame("ScrollFrame","REALMOPS_QuestChainScroll",details,"UIPanelScrollFrameTemplate"); chainScroll:SetPoint("TOPLEFT",8,-205); chainScroll:SetPoint("BOTTOMRIGHT",-28,8); chainScroll:EnableMouseWheel(true); questUI.chainScroll=chainScroll
  local chainChild=CreateFrame("Frame",nil,chainScroll); chainChild:SetWidth(280); chainChild:SetHeight(120); chainScroll:SetScrollChild(chainChild); questUI.chainChild=chainChild
  questUI.chainText=CreateFrame("EditBox",nil,chainChild); questUI.chainText:SetPoint("TOPLEFT",0,0); questUI.chainText:SetWidth(280); questUI.chainText:SetHeight(120); questUI.chainText:SetMultiLine(true); questUI.chainText:SetAutoFocus(false); questUI.chainText:SetFontObject(GameFontHighlightSmall); questUI.chainText:SetTextColor(unpack(C.white)); questUI.chainText:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  chainScroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*60)) end)
  RenderQuest()
end

local function BuildTeleport()
  local p=NewPage("Teleport"); local h=Label(p,"Teleport tools"); h:SetPoint("TOPLEFT",18,-18)
  local loc=AddField(p,"Teleport location",18,-56,260,false)
  Button(p,"Teleport",120,24,function() local s=NonEmpty(loc,"a teleport location"); if s then SendCommand(string.format(CMD.tele,s)) end end,"Use an AzerothCore teleport name"):SetPoint("TOPLEFT",295,-73)
  local playerName=AddField(p,"Player name",18,-125,210,false); playerName.realmOpsExpected="player"; playerName.realmOpsPlain=true
  Button(p,"Use Target",100,24,function()
    if UnitExists("target") and UnitIsPlayer("target") then playerName:SetText(UnitName("target") or ""); SetStatus("Selected player "..(UnitName("target") or ""))
    else SetStatus("Select a player first.",true) end
  end,"Copy the selected player's name"):SetPoint("TOPLEFT",245,-142)
  Button(p,"Appear",100,24,function()
    local name=NonEmpty(playerName,"a player name"); if name then Confirm(CMD.appear.." "..name) end
  end,"Teleport to the named player"):SetPoint("TOPLEFT",355,-142)
  Button(p,"Summon",100,24,function()
    local name=NonEmpty(playerName,"a player name"); if name then Confirm(CMD.summon.." "..name) end
  end,"Summon the named player to you"):SetPoint("TOPLEFT",465,-142)
  AddCommandGrid(p,{
    {"GPS",function() SendCommand(CMD.gps) end,"Show map and coordinates"},
    {"Appear Target",function() if UnitExists("target") and UnitIsPlayer("target") then Confirm(CMD.appear) else SetStatus("Select a player first.",true) end end,"Teleport to selected player"},
    {"Summon Target",function() if UnitExists("target") and UnitIsPlayer("target") then Confirm(CMD.summon) else SetStatus("Select a player first.",true) end end,"Summon selected player"},
  },-205)
  local note=Label(p,"Named-player commands are validated by AzerothCore. Confirm cross-map and instance movement before continuing.","GameFontHighlightSmall")
  note:SetTextColor(unpack(C.white)); note:SetPoint("TOPLEFT",18,-300); note:SetWidth(550); note:SetJustifyH("LEFT")
end

local function BuildItem()
  local p=NewPage("Item"); local titleBox=AddField(p,"Item name",18,-18,300,false); titleBox.realmOpsExpected="item"; titleBox.realmOpsPlain=true
  Button(p,"Lookup",110,24,function() local s=NonEmpty(titleBox,"an item name"); if s then BeginLookup("item",string.format(CMD.itemLookup,s)) end end,"Search the server item database"):SetPoint("TOPLEFT",334,-35)
  itemIdBox=AddField(p,"Item ID",18,-78,110,true); itemIdBox.realmOpsExpected="item"; local count=AddField(p,"Quantity",145,-78,80,true); count:SetText("1")
  Button(p,"Add Item",105,24,function() local id=PositiveId(itemIdBox,"item"); local n=PositiveId(count,"quantity"); if id and n then SendCommand(string.format(CMD.itemAdd,id,n)) end end):SetPoint("TOPLEFT",245,-95)
  Button(p,"Remove",105,24,function() local id=PositiveId(itemIdBox,"item"); local n=PositiveId(count,"quantity"); if id and n then Confirm(string.format(CMD.itemRemove,id,n)) end end):SetPoint("TOPLEFT",365,-95)
  AddResultsPanel(p,"item")
end

local function ParseAuditFields(message)
  local fields={}
  for key,value in tostring(message):gmatch("|([^|=]+)=([^|]*)") do fields[key]=value end
  return fields
end

local function ShortTime(seconds)
  seconds=tonumber(seconds) or 0
  local d=math.floor(seconds/86400); local h=math.floor((seconds%86400)/3600); local m=math.floor((seconds%3600)/60)
  if d>0 then return d.."d "..h.."h" end
  if h>0 then return h.."h "..m.."m" end
  return m.."m"
end

local function SelectedPlayerName()
  if UnitExists("target") and UnitIsPlayer("target") then return UnitName("target") end
end

local function RequireSelectedPlayer()
  local name=SelectedPlayerName()
  if not name and Settings().warnNoTarget then SetStatus("Select the player whose binds you want to change.",true); return end
  return name
end

local function MyHasInstance(id)
  id=tostring(id or "")
  for _,r in ipairs(instanceUI.my) do if tostring(r.id)==id then return true end end
  return false
end

local function BindRow(parent,y,click)
  local row=CreateFrame("Button",nil,parent); row:SetPoint("TOPLEFT",7,y); row:SetPoint("TOPRIGHT",-7,y); row:SetHeight(41)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.075,.08,.095,.96)
  row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",6,-4); row.text:SetPoint("BOTTOMRIGHT",-6,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP"); row.text:SetTextColor(unpack(C.white))
  row:SetScript("OnClick",click); row:Hide(); return row
end

local function RenderInstances()
  if instanceUI.targetLabel then instanceUI.targetLabel:SetText("Selected player: |cffffffff"..(SelectedPlayerName() or "none").."|r") end
  for i,row in ipairs(instanceUI.myRows) do
    local r=instanceUI.my[instanceUI.myOffset+i]
    if r then
      local state=r.locked and "|cff55ff55Locked|r" or "|cffffff55Available|r"; if r.extended then state=state.." Extended" end
      row.data=r; row.text:SetText(string.format("%s |cffaaaaaa[%s]|r\nID %s  •  %s  •  resets %s",r.name,r.difficulty,r.id,state,ShortTime(r.reset))); row:Show()
    else row.data=nil; row:Hide() end
  end
  for i,row in ipairs(instanceUI.targetRows) do
    local r=instanceUI.target[instanceUI.targetOffset+i]
    if r then
      local match=MyHasInstance(r.instance) and "|cff55ff55SAME AS MINE|r" or "|cffffff55DIFFERENT / NOT MINE|r"
      row.data=r; row.text:SetText(string.format("Map %d  •  ID %d  •  Difficulty %d\n%s  •  can reset: %s  •  TTR %s",r.map,r.instance,r.difficulty,match,r.canReset,r.ttr)); row:Show()
    else row.data=nil; row:Hide() end
  end
end

local function RefreshMyInstances(skipRequest)
  instanceUI.my={}; instanceUI.myOffset=0; if not skipRequest then RequestRaidInfo() end
  local total=GetNumSavedInstances() or 0
  for i=1,total do
    local name,id,reset,difficulty,locked,extended,_,isRaid,maxPlayers,difficultyName=GetSavedInstanceInfo(i)
    table.insert(instanceUI.my,{name=name or "Unknown",id=id or "?",reset=reset,difficulty=difficultyName or tostring(difficulty or "?"),difficultyId=difficulty,locked=locked,extended=extended,isRaid=isRaid,maxPlayers=maxPlayers})
  end
  RenderInstances(); SetStatus(total.." personal lockout(s) found")
end

local function InspectTargetInstances()
  if not RequireSelectedPlayer() then return end
  instanceUI.target={}; instanceUI.targetOffset=0; instanceUI.captureUntil=GetTime()+5; RenderInstances(); SendCommand(CMD.instanceList); SetStatus("Collecting binds for "..SelectedPlayerName().."...")
end

local function FilteredAuditMembers()
  local out={}
  for _,r in ipairs(auditUI.members) do if auditUI.filter=="ALL" or r.result==auditUI.filter then table.insert(out,r) end end
  if Settings().problemsFirst then
    local rank={FAIL=1,OFFLINE=2,WARN=3,PASS=4}
    table.sort(out,function(a,b) local ar=rank[a.result] or 5; local br=rank[b.result] or 5; if ar==br then return (a.name or "")<(b.name or "") end; return ar<br end)
  end
  return out
end

local function RenderAudit()
  for i,row in ipairs(auditUI.searchRows) do
    local r=auditUI.search[i]
    if r then row.id=tonumber(r.map); row.label:SetText(string.format("%s — Map %s (%s)",r.name or "Unknown",r.map or "?",r.type or "instance")); row:Show() else row:Hide() end
  end
  auditUI.filtered=FilteredAuditMembers()
  local rowHeight=Settings().compactAuditRows and 28 or 40
  local contentWidth=Settings().wrapAuditReasons and 610 or 1050
  if auditUI.scrollChild then auditUI.scrollChild:SetWidth(contentWidth); auditUI.scrollChild:SetHeight(math.max(1,#auditUI.filtered)*rowHeight) end
  local reportLines={}
  for _,r in ipairs(auditUI.filtered) do
    local color=r.result=="PASS" and "|cff55ff55" or (r.result=="WARN" and "|cffffff55" or (r.result=="OFFLINE" and "|cffaaaaaa" or "|cffff5555"))
    table.insert(reportLines,color..(r.result or "?").."|r  "..(r.name or "Unknown"))
    table.insert(reportLines,"|cffdddddd"..(r.reason or "").."|r")
    table.insert(reportLines,"")
  end
  if auditUI.reportEdit then
    local text=table.concat(reportLines,"\n"); local h=math.max(1,#reportLines*15+10)
    auditUI.reportEdit:SetFont("Fonts\\FRIZQT__.TTF",Settings().auditFontSize or 10); auditUI.reportEdit:SetText(text); auditUI.reportEdit:SetHeight(h)
    auditUI.scrollChild:SetHeight(h)
  end
  for _,row in ipairs(auditUI.memberRows) do row:Hide() end
  if auditUI.scroll then auditUI.scroll:SetVerticalScroll(0); auditUI.scroll:SetHorizontalScroll(0) end
  if auditUI.horizontal then auditUI.horizontal:SetMinMaxValues(0,math.max(0,contentWidth-365)); auditUI.horizontal:SetValue(0) end
  if auditUI.summary then auditUI.summary:SetText(string.format("Showing %d of %d",#auditUI.filtered,#auditUI.members)) end
  for name,button in pairs(auditUI.filterButtons) do button:SetBackdropColor(unpack(name==auditUI.filter and C.selected or C.button)) end
end

ShowSelectableReport=function(title, report)
  if not exportFrame then
    exportFrame=CreateFrame("Frame","REALMOPS_ExportFrame",UIParent); exportFrame:SetWidth(610); exportFrame:SetHeight(410); exportFrame:SetPoint("CENTER"); exportFrame:SetFrameStrata("FULLSCREEN_DIALOG"); Backdrop(exportFrame); Movable(exportFrame,"export")
    exportFrame.title=Label(exportFrame,"RealmOps report"); exportFrame.title:SetPoint("TOPLEFT",14,-14)
    local help=exportFrame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); help:SetPoint("TOPLEFT",14,-34); help:SetText("Select any text and press Ctrl+C. Ctrl+A selects the complete report."); help:SetTextColor(unpack(C.white))
    local scroll=CreateFrame("ScrollFrame","REALMOPS_ExportScroll",exportFrame,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",14,-58); scroll:SetPoint("BOTTOMRIGHT",-34,45); Backdrop(scroll,C.panel)
    exportEdit=CreateFrame("EditBox",nil,scroll); exportEdit:SetMultiLine(true); exportEdit:SetAutoFocus(false); exportEdit:SetFontObject(ChatFontNormal); exportEdit:SetWidth(545); exportEdit:SetTextInsets(6,6,6,6); exportEdit:SetScript("OnEscapePressed",function() exportFrame:Hide() end); scroll:SetScrollChild(exportEdit)
    scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*60)) end)
    Button(exportFrame,"Select All",90,24,function() exportEdit:SetFocus(); exportEdit:HighlightText() end):SetPoint("BOTTOMLEFT",14,12)
    Button(exportFrame,"Close",90,24,function() exportFrame:Hide() end):SetPoint("BOTTOMRIGHT",-14,12)
  end
  exportFrame.title:SetText(title or "RealmOps report")
  exportEdit:SetText(report or ""); exportEdit:SetHeight(math.max(310,select(2,(report or ""):gsub("\n","\n"))*16+40)); exportFrame:Show(); exportEdit:SetFocus(); exportEdit:HighlightText()
end

local function ShowAuditExport()
  if #auditUI.members==0 then SetStatus("Run an instance audit before exporting.",true); return end
  local lines={"RealmOps instance audit",string.format("Map: %s  Difficulty: %s",auditUI.lastMap or "?",auditUI.lastDifficulty or "?"),""}
  for _,r in ipairs(auditUI.members) do table.insert(lines,string.format("%s | %s | %s",r.result or "?",r.name or "Unknown",r.reason or "No reason")) end
  ShowSelectableReport("RealmOps instance audit",table.concat(lines,"\n"))
end

local function AuditResultRow(parent)
  local row=CreateFrame("Button",nil,parent); row:SetHeight(38)
  row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); row:SetBackdropColor(.075,.08,.095,.96)
  row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.text:SetPoint("TOPLEFT",7,-4); row.text:SetPoint("BOTTOMRIGHT",-7,3); row.text:SetJustifyH("LEFT"); row.text:SetJustifyV("TOP")
  row:SetScript("OnEnter",function(self) if Settings().auditTooltips and self.data then GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText((self.data.result or "?").." — "..(self.data.name or "Unknown"),1,.82,0); GameTooltip:AddLine(self.data.reason or "No details",1,1,1,true); GameTooltip:Show() end end)
  row:SetScript("OnLeave",function() GameTooltip:Hide() end); row:Hide(); return row
end


local function EligibilityPanel(parent, title, x, y, w, h)
  local f=CreateFrame("Frame",nil,parent); f:SetPoint("TOPLEFT",x,y); f:SetWidth(w); f:SetHeight(h); Backdrop(f,C.panel)
  local t=Label(f,title,"GameFontNormalSmall"); t:SetPoint("TOPLEFT",10,-9)
  return f
end

local function EligibilityValue(parent, text, x, y, big)
  local f=parent:CreateFontString(nil,"OVERLAY",big and "GameFontNormalLarge" or "GameFontHighlightSmall")
  f:SetPoint("TOPLEFT",x,y); f:SetText(text or "-"); f:SetTextColor(unpack(C.white)); return f
end

local function EligibilityReasonQuest(reason)
  return tonumber(tostring(reason or ""):match("[Qq]uest%s+(%d+)") or tostring(reason or ""):match("(%d%d%d%d%d)"))
end

local function RenderEligibility()
  if not eligibilityUI.title then return end
  local pass,fail,warn=0,0,0
  for _,r in ipairs(auditUI.members) do
    if r.result=="PASS" then pass=pass+1 elseif r.result=="WARN" then warn=warn+1 else fail=fail+1 end
  end
  eligibilityUI.ready:SetText(tostring(pass)); eligibilityUI.blocked:SetText(tostring(fail)); eligibilityUI.warnings:SetText(tostring(warn))
  local total=#auditUI.members
  eligibilityUI.summary:SetText(total>0 and string.format("%d / %d players ready",pass,total) or "Run an audit to evaluate the group")
  local currentTitle="Select an instance"
  for _,r in ipairs(auditUI.search) do if tonumber(r.map)==tonumber(auditUI.lastMap) then currentTitle=r.name or currentTitle break end end
  eligibilityUI.title:SetText(currentTitle)
  eligibilityUI.subtitle:SetText(auditUI.lastMap and string.format("Map %s  •  Difficulty %s",auditUI.lastMap,auditUI.lastDifficulty or 0) or "Search for an instance to begin")
  local req={level=true,difficulty=true,heroic=true,quest=true,lockout=true}
  for _,r in ipairs(auditUI.members) do
    local reason=tostring(r.reason or ""):lower()
    if r.result~="PASS" then
      if reason:find("level") then req.level=false end
      if reason:find("difficult") then req.difficulty=false end
      if reason:find("heroic") then req.heroic=false end
      if reason:find("quest") or EligibilityReasonQuest(r.reason) then req.quest=false end
      if reason:find("lock") or reason:find("instance id") or reason:find("bind") then req.lockout=false end
    end
  end
  local order={{"level","Level"},{"difficulty","Difficulty"},{"heroic","Heroic"},{"quest","Quest chain"},{"lockout","Lockout"}}
  for i,v in ipairs(order) do
    local ok=req[v[1]]; eligibilityUI.requirementTexts[i]:SetText((ok and "|cff55ff55✓ PASS|r  " or "|cffff5555✕ CHECK|r  ")..v[2])
  end
  for i,row in ipairs(eligibilityUI.searchRows) do
    local r=auditUI.search[i]
    if r then row.data=r; row.label:SetText(string.format("%s
|cffaaaaaaMap %s • %s|r",r.name or "Unknown",r.map or "?",r.type or "instance")); row:Show() else row.data=nil; row:Hide() end
  end
  for i,row in ipairs(eligibilityUI.memberRows) do
    local r=auditUI.members[i]
    if r then
      row.data=r
      local color=r.result=="PASS" and "|cff55ff55" or (r.result=="WARN" and "|cffffff55" or "|cffff5555")
      local quest=EligibilityReasonQuest(r.reason)
      local qtext=quest and ("Missing "..quest) or (r.result=="PASS" and "Ready" or "Check")
      row.name:SetText(r.name or "Unknown"); row.quest:SetText(qtext); row.lockout:SetText(tostring(r.reason or ""):lower():find("lock") and "CHECK" or "PASS"); row.diff:SetText(tostring(r.reason or ""):lower():find("difficult") and "CHECK" or "PASS"); row.result:SetText(color..(r.result or "?").."|r"); row:Show()
    else row.data=nil; row:Hide() end
  end
  local selected=eligibilityUI.selected
  if selected then
    local qid=EligibilityReasonQuest(selected.reason)
    eligibilityUI.detailText:SetText(string.format("|cffffd200%s|r

Result: %s

%s%s",selected.name or "Unknown",selected.result or "?",selected.reason or "No details",qid and ("

Blocking quest: "..qid.."
Use ‘Open Quest’ to inspect the chain and audit this quest.") or ""))
  else eligibilityUI.detailText:SetText("Select a player row to inspect the blocker and available actions.") end
  local blockers={}
  for _,r in ipairs(auditUI.members) do if r.result~="PASS" then table.insert(blockers,r) end end
  if #blockers==0 and total>0 then eligibilityUI.recommendation:SetText("|cff55ff55Group ready.|r
All reported checks passed. You can proceed to the instance.")
  elseif #blockers>0 then
    local first=blockers[1]; local qid=EligibilityReasonQuest(first.reason)
    eligibilityUI.recommendation:SetText(string.format("|cffff5555Group not ready.|r
%d player(s) blocked.

First action: resolve %s for %s.",#blockers,qid and ("quest "..qid) or (first.reason or "the reported issue"),first.name or "the player"))
  else eligibilityUI.recommendation:SetText("Search for an instance, select it, and run Group Audit.") end
  local chain={"Quest chain"}
  if questUI.info then table.insert(chain,string.format("|cffffd200%s [%s]|r",questUI.info.title or "Quest",questUI.info.id or "?")) end
  for _,q in ipairs(questUI.chain) do table.insert(chain,string.format("%s  %s [%s]",q.direction or "LINK",q.title or "Unknown",q.id or "?")) end
  if #chain==1 then table.insert(chain,"Select a blocked player and click Open Quest.") end
  eligibilityUI.chainText:SetText(table.concat(chain,"

"))
end

local function BuildEligibility()
  local p=NewPage("Eligibility")
  local search=EligibilityPanel(p,"INSTANCE ACCESS ANALYZER",12,-12,740,74)
  eligibilityUI.searchBox=Edit(search,300,false); eligibilityUI.searchBox:SetPoint("TOPLEFT",12,-34); eligibilityUI.searchBox:SetText("Pit of Saron")
  Button(search,"Search",72,24,function() local q=NonEmpty(eligibilityUI.searchBox,"an instance title"); if q then auditUI.search={}; RenderEligibility(); SendCommand(string.format(CMD.auditSearch,q)); SetStatus("Searching instance access data...") end end):SetPoint("LEFT",eligibilityUI.searchBox,"RIGHT",8,0)
  eligibilityUI.mapBox=Edit(search,70,true); eligibilityUI.mapBox:SetPoint("LEFT",eligibilityUI.searchBox,"RIGHT",92,0)
  eligibilityUI.diffBox=Edit(search,44,true); eligibilityUI.diffBox:SetPoint("LEFT",eligibilityUI.mapBox,"RIGHT",8,0); eligibilityUI.diffBox:SetText(tostring(Settings().defaultDifficulty))
  Button(search,"Group Audit",104,24,function()
    local map=PositiveId(eligibilityUI.mapBox,"map"); local diff=tonumber(eligibilityUI.diffBox:GetText())
    if not map or not diff or diff<0 or diff>3 then SetStatus("Difficulty must be 0–3.",true); return end
    auditUI.lastMap=map; auditUI.lastDifficulty=diff; auditUI.members={}; eligibilityUI.selected=nil; RenderAudit(); RenderEligibility(); SendCommand(string.format(CMD.auditGroup,map,diff)); SetStatus("Running combined eligibility audit...")
  end):SetPoint("LEFT",eligibilityUI.diffBox,"RIGHT",8,0)

  local matches=EligibilityPanel(p,"INSTANCE MATCHES",12,-94,220,222)
  for i=1,6 do
    local row=Button(matches,"",200,30,function(self) if self.data then local m=tonumber(self.data.map); eligibilityUI.mapBox:SetText(m or ""); auditUI.lastMap=m; RenderEligibility(); SetStatus("Selected "..(self.data.name or "instance")) end end)
    row:SetPoint("TOPLEFT",10,-30-(i-1)*31); row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.label:SetPoint("LEFT",7,0); row.label:SetPoint("RIGHT",-5,0); row.label:SetJustifyH("LEFT"); eligibilityUI.searchRows[i]=row; row:Hide()
  end

  local overview=EligibilityPanel(p,"GROUP READINESS",244,-94,508,92)
  eligibilityUI.ready=EligibilityValue(overview,"0",18,-35,true); EligibilityValue(overview,"READY",18,-61)
  eligibilityUI.blocked=EligibilityValue(overview,"0",135,-35,true); EligibilityValue(overview,"BLOCKED",135,-61)
  eligibilityUI.warnings=EligibilityValue(overview,"0",270,-35,true); EligibilityValue(overview,"WARNINGS",270,-61)
  eligibilityUI.summary=EligibilityValue(overview,"Run an audit",370,-42); eligibilityUI.summary:SetWidth(125); eligibilityUI.summary:SetJustifyH("CENTER")

  local requirements=EligibilityPanel(p,"REQUIREMENTS",244,-198,508,118)
  for i,name in ipairs({"Level","Difficulty","Heroic","Quest chain","Lockout"}) do
    local t=EligibilityValue(requirements,"✓ PASS  "..name,14+((i-1)%3)*164,-34-math.floor((i-1)/3)*38); eligibilityUI.requirementTexts[i]=t
  end

  local matrix=EligibilityPanel(p,"PLAYER ELIGIBILITY MATRIX",12,-328,740,218)
  local headers={{"PLAYER",8},{"QUEST",170},{"LOCKOUT",330},{"DIFFICULTY",430},{"READY",565}}
  for _,h in ipairs(headers) do local t=EligibilityValue(matrix,h[1],h[2],-28); t:SetTextColor(unpack(C.gold)) end
  for i=1,5 do
    local row=CreateFrame("Button",nil,matrix); row:SetPoint("TOPLEFT",8,-48-(i-1)*31); row:SetWidth(724); row:SetHeight(28); row:SetBackdrop({bgFile="Interface\Buttons\WHITE8X8"}); row:SetBackdropColor(.07,.075,.09,.96)
    row.name=EligibilityValue(row,"",8,-7); row.quest=EligibilityValue(row,"",162,-7); row.lockout=EligibilityValue(row,"",322,-7); row.diff=EligibilityValue(row,"",422,-7); row.result=EligibilityValue(row,"",557,-7)
    row:SetScript("OnClick",function(self) eligibilityUI.selected=self.data; RenderEligibility() end); row:SetScript("OnEnter",function(self) self:SetBackdropColor(unpack(C.hover)) end); row:SetScript("OnLeave",function(self) self:SetBackdropColor(.07,.075,.09,.96) end); row:Hide(); eligibilityUI.memberRows[i]=row
  end
  Button(matrix,"Export",72,22,ShowAuditExport):SetPoint("BOTTOMRIGHT",-10,8)

  local detail=EligibilityPanel(p,"PLAYER DETAILS",766,-12,250,248)
  eligibilityUI.detailText=detail:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); eligibilityUI.detailText:SetPoint("TOPLEFT",12,-34); eligibilityUI.detailText:SetPoint("BOTTOMRIGHT",-12,50); eligibilityUI.detailText:SetJustifyH("LEFT"); eligibilityUI.detailText:SetJustifyV("TOP")
  Button(detail,"Open Quest",92,22,function() local r=eligibilityUI.selected; local q=r and EligibilityReasonQuest(r.reason); if q then questUI.info=nil; questUI.chain={}; questUI.auditMembers={}; SendCommand(string.format(CMD.questInfo,q)); SendCommand(string.format(CMD.questAudit,q)); SetStatus("Loading blocking quest "..q) else SetStatus("Selected player has no quest blocker.",true) end end):SetPoint("BOTTOMLEFT",10,12)
  Button(detail,"Whisper",70,22,function() local r=eligibilityUI.selected; if r and r.name then ChatFrame_SendTell(r.name) else SetStatus("Select a player first.",true) end end):SetPoint("BOTTOMRIGHT",-10,12)

  local chain=EligibilityPanel(p,"QUEST CHAIN",766,-272,250,150)
  eligibilityUI.chainText=chain:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); eligibilityUI.chainText:SetPoint("TOPLEFT",12,-34); eligibilityUI.chainText:SetPoint("BOTTOMRIGHT",-12,10); eligibilityUI.chainText:SetJustifyH("LEFT"); eligibilityUI.chainText:SetJustifyV("TOP")

  local rec=EligibilityPanel(p,"RECOMMENDATION",766,-434,250,112)
  eligibilityUI.recommendation=rec:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); eligibilityUI.recommendation:SetPoint("TOPLEFT",12,-34); eligibilityUI.recommendation:SetPoint("BOTTOMRIGHT",-12,10); eligibilityUI.recommendation:SetJustifyH("LEFT"); eligibilityUI.recommendation:SetJustifyV("TOP")
  eligibilityUI.title=Label(p,"Select an instance","GameFontNormalLarge"); eligibilityUI.title:SetPoint("TOPLEFT",246,-28)
  eligibilityUI.subtitle=EligibilityValue(p,"Search for an instance to begin",246,-51)
  RenderEligibility()
end

local function BuildInstances()
  local p=NewPage("Instances")
  local auditPage=CreateFrame("Frame",nil,p); auditPage:SetPoint("TOPLEFT",0,-36); auditPage:SetPoint("BOTTOMRIGHT")
  local bindPage=CreateFrame("Frame",nil,p); bindPage:SetPoint("TOPLEFT",0,-36); bindPage:SetPoint("BOTTOMRIGHT"); bindPage:Hide()
  local auditTab=Button(p,"Audit",120,24,function() auditPage:Show(); bindPage:Hide() end,"Group and raid eligibility audit"); auditTab:SetPoint("TOPLEFT",12,-7)
  local bindTab=Button(p,"Binds / Reset",120,24,function() bindPage:Show(); auditPage:Hide(); RenderInstances() end,"Inspect and safely remove instance binds"); bindTab:SetPoint("LEFT",auditTab,"RIGHT",8,0)

  local searchBox=AddField(auditPage,"Instance title",12,-5,225,false)
  Button(auditPage,"Search",70,24,function()
    local title=NonEmpty(searchBox,"an instance title")
    if title then auditUI.search={}; RenderAudit(); SendCommand(string.format(CMD.auditSearch,title)); SetStatus("Searching server instance maps...") end
  end,"Requires mod-realm-ops"):SetPoint("TOPLEFT",247,-22)
  auditUI.mapBox=AddField(auditPage,"Map ID",330,-5,70,true)
  auditUI.diffBox=AddField(auditPage,"Difficulty",415,-5,65,true); auditUI.diffBox:SetText(tostring(Settings().defaultDifficulty))
  local function RunAudit()
    local map=PositiveId(auditUI.mapBox,"map"); local diff=tonumber(auditUI.diffBox:GetText())
    if not map or not diff or diff<0 or diff>3 then SetStatus("Difficulty must be 0, 1, 2, or 3.",true); return end
    auditUI.lastMap=map; auditUI.lastDifficulty=diff; auditUI.members={}; RenderAudit(); SendCommand(string.format(CMD.auditGroup,map,diff)); SetStatus("Auditing group on the server...")
  end
  Button(auditPage,"Audit Group",100,24,RunAudit,"Check every group or raid member"):SetPoint("TOPLEFT",495,-22)

  local searchPanel=CreateFrame("Frame",nil,auditPage); searchPanel:SetPoint("TOPLEFT",12,-59); searchPanel:SetWidth(190); searchPanel:SetHeight(307); Backdrop(searchPanel,C.panel)
  local sh=Label(searchPanel,"Instance matches","GameFontNormalSmall"); sh:SetPoint("TOPLEFT",8,-7)
  for i=1,8 do
    local row=Button(searchPanel,"",174,27,function(self) if self.id then auditUI.mapBox:SetText(self.id); SetStatus("Selected map "..self.id) end end)
    row.label=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); row.label:SetPoint("LEFT",6,0); row.label:SetPoint("RIGHT",-6,0); row.label:SetJustifyH("LEFT"); row.label:SetTextColor(unpack(C.gold))
    row:SetPoint("TOPLEFT",8,-27-(i-1)*30); row:Hide(); auditUI.searchRows[i]=row
  end

  local resultPanel=CreateFrame("Frame",nil,auditPage); resultPanel:SetPoint("TOPLEFT",210,-59); resultPanel:SetPoint("BOTTOMRIGHT",-12,10); Backdrop(resultPanel,C.panel)
  local rh=Label(resultPanel,"Group eligibility and visibility","GameFontNormalSmall"); rh:SetPoint("TOPLEFT",8,-7)
  auditUI.summary=resultPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); auditUI.summary:SetPoint("TOPRIGHT",-164,-7); auditUI.summary:SetTextColor(unpack(C.white))
  local filterNames={"ALL","FAIL","WARN","PASS","OFFLINE"}
  for i,name in ipairs(filterNames) do
    local filterName=name
    local filterButton=Button(resultPanel,filterName,54,18,function() auditUI.filter=filterName; if Settings().rememberAuditFilter then RealmOpsDB.auditFilter=filterName end; RenderAudit() end,"Show "..filterName.." results")
    filterButton:SetPoint("TOPLEFT",8+(i-1)*58,-27); auditUI.filterButtons[filterName]=filterButton
    filterButton:SetScript("OnLeave",function(self) self:SetBackdropColor(unpack(filterName==auditUI.filter and C.selected or C.button)); GameTooltip:Hide() end)
  end
  Button(resultPanel,"Export",70,18,ShowAuditExport,"Open a selectable text report for copying"):SetPoint("TOPRIGHT",-84,-4)
  Button(resultPanel,"Re-audit",70,18,function() if auditUI.lastMap then auditUI.mapBox:SetText(auditUI.lastMap); auditUI.diffBox:SetText(auditUI.lastDifficulty); RunAudit() else SetStatus("Run an audit first.",true) end end,"Repeat the last audit"):SetPoint("TOPRIGHT",-8,-4)
  local scroll=CreateFrame("ScrollFrame","REALMOPS_AuditResultScroll",resultPanel,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",8,-48); scroll:SetPoint("BOTTOMRIGHT",-28,54); auditUI.scroll=scroll
  local child=CreateFrame("Frame",nil,scroll); child:SetWidth(610); child:SetHeight(1); scroll:SetScrollChild(child); auditUI.scrollChild=child
  auditUI.reportEdit=CreateFrame("EditBox",nil,child); auditUI.reportEdit:SetPoint("TOPLEFT",4,-2); auditUI.reportEdit:SetWidth(600); auditUI.reportEdit:SetHeight(1); auditUI.reportEdit:SetMultiLine(true); auditUI.reportEdit:SetAutoFocus(false); auditUI.reportEdit:SetFontObject(GameFontHighlightSmall); auditUI.reportEdit:SetTextColor(unpack(C.white)); auditUI.reportEdit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
  for i=1,40 do auditUI.memberRows[i]=AuditResultRow(child); auditUI.memberRows[i]:Hide() end
  scroll:EnableMouseWheel(true); scroll:SetScript("OnMouseWheel",function(self,delta) if Settings().mouseWheelAudit then self:SetVerticalScroll(math.max(0,self:GetVerticalScroll()-delta*80)) end end)
  local hs=CreateFrame("Slider","REALMOPS_AuditHorizontalScroll",resultPanel,"OptionsSliderTemplate"); hs:SetPoint("BOTTOMLEFT",12,31); hs:SetPoint("BOTTOMRIGHT",-12,31); hs:SetHeight(16); hs:SetMinMaxValues(0,0); hs:SetValueStep(10); hs:SetValue(0); auditUI.horizontal=hs
  _G[hs:GetName().."Low"]:SetText(""); _G[hs:GetName().."High"]:SetText(""); _G[hs:GetName().."Text"]:SetText("")
  hs:SetScript("OnValueChanged",function(_,value) if auditUI.scroll then auditUI.scroll:SetHorizontalScroll(value) end end)
  local legend=Label(resultPanel,"PASS = eligible  •  WARN = context  •  FAIL = blocked  •  Hover for full reason","GameFontHighlightSmall"); legend:SetTextColor(unpack(C.white)); legend:SetPoint("BOTTOMLEFT",12,9)

  local myBox=CreateFrame("Frame",nil,bindPage); myBox:SetPoint("TOPLEFT",12,-4); myBox:SetWidth(295); myBox:SetHeight(260); Backdrop(myBox,C.panel)
  local mh=Label(myBox,"My saved instances","GameFontNormalSmall"); mh:SetPoint("TOPLEFT",9,-8)
  Button(myBox,"Refresh",70,20,RefreshMyInstances,"Refresh client lockouts"):SetPoint("TOPRIGHT",-8,-6)
  for i=1,5 do instanceUI.myRows[i]=BindRow(myBox,-31-(i-1)*44) end
  myBox:EnableMouseWheel(true); myBox:SetScript("OnMouseWheel",function(_,d) instanceUI.myOffset=math.max(0,math.min(math.max(0,#instanceUI.my-5),instanceUI.myOffset-d)); RenderInstances() end)

  local targetBox=CreateFrame("Frame",nil,bindPage); targetBox:SetPoint("TOPLEFT",317,-4); targetBox:SetWidth(295); targetBox:SetHeight(260); Backdrop(targetBox,C.panel)
  instanceUI.targetLabel=Label(targetBox,"Selected player: none","GameFontNormalSmall"); instanceUI.targetLabel:SetPoint("TOPLEFT",9,-8)
  Button(targetBox,"Inspect",70,20,InspectTargetInstances,"Run .instance listbinds for the selected player"):SetPoint("TOPRIGHT",-8,-6)
  for i=1,5 do instanceUI.targetRows[i]=BindRow(targetBox,-31-(i-1)*44,function(self) if self.data then instanceUI.mapBox:SetText(self.data.map); instanceUI.diffBox:SetText(self.data.difficulty); SetStatus("Selected map "..self.data.map..", difficulty "..self.data.difficulty) end end) end
  targetBox:EnableMouseWheel(true); targetBox:SetScript("OnMouseWheel",function(_,d) instanceUI.targetOffset=math.max(0,math.min(math.max(0,#instanceUI.target-5),instanceUI.targetOffset-d)); RenderInstances() end)

  instanceUI.mapBox=AddField(bindPage,"Map ID",14,-282,80,true); instanceUI.diffBox=AddField(bindPage,"Difficulty",110,-282,70,true); instanceUI.diffBox:SetText("0")
  Button(bindPage,"Reset Map",105,24,function()
    local name=RequireSelectedPlayer(); local map=PositiveId(instanceUI.mapBox,"map"); local diff=tonumber(instanceUI.diffBox:GetText())
    if name and map and diff and diff>=0 and diff<=3 then Confirm(string.format(CMD.instanceUnbind,tostring(map),diff),Settings().confirmResetSelected,function() if Settings().autoReaudit and auditUI.lastMap then After(.7,function() auditPage:Show(); bindPage:Hide(); RunAudit() end) end end) else SetStatus("Select a player and enter map ID plus difficulty 0–3.",true) end
  end,"Unbind the selected player from this map and difficulty"):SetPoint("TOPLEFT",198,-299)
  Button(bindPage,"Reset ALL",105,24,function() if RequireSelectedPlayer() then Confirm(CMD.instanceUnbindAll,Settings().confirmResetAll,function() if Settings().autoReaudit and auditUI.lastMap then After(.7,function() auditPage:Show(); bindPage:Hide(); RunAudit() end) end end) end end,"Clear all removable binds for the selected player"):SetPoint("TOPLEFT",313,-299)
  local note=Label(bindPage,"Click a selected-player bind to fill Map ID and Difficulty. Unbinding removes the character bind; it cannot reset an occupied instance or bypass encounter rules.","GameFontHighlightSmall")
  note:SetTextColor(unpack(C.white)); note:SetPoint("TOPLEFT",435,-282); note:SetWidth(175); note:SetJustifyH("LEFT")
  Button(bindPage,"Re-audit",90,22,function() if auditUI.lastMap then auditPage:Show(); bindPage:Hide(); auditUI.mapBox:SetText(auditUI.lastMap); auditUI.diffBox:SetText(auditUI.lastDifficulty); RunAudit() else SetStatus("Run an audit first.",true) end end,"Return to and repeat the last audit"):SetPoint("BOTTOMLEFT",14,13)
  auditUI.filter=(Settings().rememberAuditFilter and RealmOpsDB.auditFilter) or "ALL"
  RenderAudit()
  RenderInstances()
end

local function PositionMinimap()
  local a=RealmOpsDB.minimapAngle or 225; local r=78
  minimapButton:ClearAllPoints(); minimapButton:SetPoint("CENTER",Minimap,"CENTER",math.cos(math.rad(a))*r,math.sin(math.rad(a))*r)
end
local function ShowMain() main:Show(); mini:Hide() end
local function HideMain() main:Hide(); if Settings().showMini then mini:Show() else mini:Hide() end end

local function ApplySettings()
  local s=Settings()
  if main then main:SetScale(s.scale or 1) end
  if minimapButton then
    minimapButton:SetParent(s.mbfCompatibility and UIParent or Minimap)
    PositionMinimap()
    if s.showMinimap then minimapButton:Show() else minimapButton:Hide() end
  end
  if mini then
    if main and main:IsShown() then mini:Hide() elseif s.showMini then mini:Show() else mini:Hide() end
  end
  if auditUI.diffBox and not auditUI.diffBox:HasFocus() then auditUI.diffBox:SetText(tostring(s.defaultDifficulty or 0)) end
  if auditUI.scrollChild then RenderAudit() end
end

local function ResetPositions()
  RealmOpsDB.mainPoint=nil; RealmOpsDB.mainRel=nil; RealmOpsDB.mainX=nil; RealmOpsDB.mainY=nil; RealmOpsDB.miniPoint=nil; RealmOpsDB.miniRel=nil; RealmOpsDB.miniX=nil; RealmOpsDB.miniY=nil; RealmOpsDB.minimapAngle=225
  main:ClearAllPoints(); main:SetPoint("CENTER"); mini:ClearAllPoints(); mini:SetPoint("CENTER",UIParent,"CENTER",290,0); PositionMinimap(); ShowMain(); SetStatus("Positions reset")
end

local function OpenOptions()
  InterfaceOptionsFrame_OpenToCategory(optionsPanel)
  InterfaceOptionsFrame_OpenToCategory(optionsPanel)
end

local function RenderCompatibility()
  if not compatUI.text then return end
  local f=compatUI.data
  if not f then
    compatUI.text:SetText("RealmOps\nAddon      |cffffffff"..ADDON_VERSION.."|r\nModule     |cffaaaaaaNot checked|r\nProtocol   v"..PROTOCOL_VERSION.."\n\nClick Check compatibility to query the running worldserver.")
    return
  end

  local protocolOK=tostring(f.protocol or "")==PROTOCOL_VERSION
  local function Workspace(value)
    value=tostring(value or "unknown")
    if value=="no" then return "|cff55ff55Clean|r" end
    if value=="yes" then return "|cffffff55Modified|r" end
    return "|cffffff55Unknown|r"
  end
  local status=protocolOK and "|cff55ff55Compatible|r" or "|cffff5555Incompatible|r"
  local release=protocolOK and "|cff55ff55Supported|r" or "|cffff5555Unsupported|r"
  local explanation=protocolOK
    and "|cffaaaaaaDifferent addon and module versions can still be supported. If RealmOps behaves unexpectedly, version alignment is a useful first troubleshooting check.|r"
    or "|cffffaaaaThe addon and module use different protocol versions. Update one component before relying on the tool.|r"

  compatUI.text:SetText(string.format(
    "RealmOps\nAddon      |cffffffff%s|r\nModule     |cffffffff%s|r\nProtocol   v%s\nStatus     %s\n\nRelease\n%s (%s)\n%s\n\nCapabilities\n|cffffffff%s|r\n\nCommits\nRealmOps   |cffffffff%s|r\nCore       |cffffffff%s|r\nPlayerbots |cffffffff%s|r\n\nWorkspace\nRealmOps   %s\nCore       %s\nPlayerbots %s\n\nBuild\n%s\nBuilt %s",
    ADDON_VERSION,f.module or "unknown",f.protocol or "?",status,release,f.release or "unknown",explanation,
    f.capabilities or "not advertised",f.modulegit or "unknown",f.core or "unknown",f.playerbots or "unknown",
    Workspace(f.moduledirty),Workspace(f.coredirty),Workspace(f.playerbotsdirty),
    f.build or "unknown",f.built or "unknown"))
end

local function RequestCompatibility()
  compatUI.data=nil; RenderCompatibility(); SendCommand(CMD.version); SetStatus("Checking addon and server-module compatibility...")
end

local function BuildOptions()
  local p=CreateFrame("Frame","REALMOPS_OptionsPanel",UIParent); p.name="RealmOps"; optionsPanel=p
  local title=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetText("RealmOps")
  local version=p:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); version:SetPoint("LEFT",title,"RIGHT",8,0); version:SetText(ADDON_VERSION)
  local note=p:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); note:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-8); note:SetText("Settings are saved separately for each character.")
  local controls={}
  local function Check(parent,store,name,label,key,y,tip)
    local c=CreateFrame("CheckButton","REALMOPS_Opt"..name,parent,"InterfaceOptionsCheckButtonTemplate"); c:SetPoint("TOPLEFT",16,y)
    _G[c:GetName().."Text"]:SetText(label); c.tooltipText=tip; c:SetScript("OnClick",function(self) Settings()[key]=self:GetChecked() and true or false; ApplySettings() end)
    store[key]=c; return c
  end
  Check(p,controls,"StartMinimized","Start minimized after login or reload","startMinimized",-70,"Apply on the next login or /reload.")
  Check(p,controls,"Minimap","Show RealmOps minimap button","showMinimap",-102,"Show the RealmOps button around the minimap.")
  Check(p,controls,"Mini","Show floating RealmOps button when minimized","showMini",-134,"Show the movable RealmOps button when the main window is hidden.")
  Check(p,controls,"MBF","Keep RealmOps outside Minimap Button Frame","mbfCompatibility",-166,"Enabled: MBF cannot collect RealmOps. Disabled: RealmOps can be added to MBF with /mbf scan.")
  Check(p,controls,"Confirm","Confirm destructive commands","confirmCommands",-198,"Ask before delete, remove, reset, reward, and other risky commands.")
  Check(p,controls,"Chat","Hide RealmOps protocol messages from chat","hideAuditChat",-230,"Keep REALMOPS server messages out of normal chat.")

  local scaleLabel=p:CreateFontString(nil,"ARTWORK","GameFontNormal"); scaleLabel:SetPoint("TOPLEFT",22,-278); scaleLabel:SetText("RealmOps window scale")
  local slider=CreateFrame("Slider","REALMOPS_OptScale",p,"OptionsSliderTemplate"); slider:SetPoint("TOPLEFT",22,-302); slider:SetWidth(240); slider:SetMinMaxValues(.75,1.35); slider:SetValueStep(.05)
  _G[slider:GetName().."Low"]:SetText("75%"); _G[slider:GetName().."High"]:SetText("135%"); _G[slider:GetName().."Text"]:SetText("100%")
  slider:SetScript("OnValueChanged",function(self,value) value=math.floor(value*20+.5)/20; Settings().scale=value; _G[self:GetName().."Text"]:SetText(math.floor(value*100+.5).."%"); ApplySettings() end)

  local resetPos=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); resetPos:SetWidth(135); resetPos:SetHeight(24); resetPos:SetText("Reset positions"); resetPos:SetPoint("TOPLEFT",16,-370); resetPos:SetScript("OnClick",ResetPositions)
  local resetAll=CreateFrame("Button",nil,p,"UIPanelButtonTemplate"); resetAll:SetWidth(135); resetAll:SetHeight(24); resetAll:SetText("Restore defaults"); resetAll:SetPoint("LEFT",resetPos,"RIGHT",12,0)
  resetAll:SetScript("OnClick",function() RealmOpsDB.settings={}; RealmOpsDB.auditFilter=nil; Settings(); slider:SetValue(Settings().scale); ApplySettings(); p:GetScript("OnShow")(p); Print("Settings restored to defaults.") end)

  local diagnostics=CreateFrame("Frame",nil,p); diagnostics:SetPoint("TOPLEFT",340,-62); diagnostics:SetWidth(300); diagnostics:SetHeight(408); Backdrop(diagnostics,C.panel)
  local diagTitle=Label(diagnostics,"Compatibility diagnostics"); diagTitle:SetPoint("TOPLEFT",10,-10)
  compatUI.text=diagnostics:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); compatUI.text:SetPoint("TOPLEFT",10,-38); compatUI.text:SetPoint("TOPRIGHT",-10,-38); compatUI.text:SetJustifyH("LEFT"); compatUI.text:SetJustifyV("TOP"); compatUI.text:SetWordWrap(true); compatUI.text:SetTextColor(unpack(C.white))
  local check=CreateFrame("Button",nil,diagnostics,"UIPanelButtonTemplate"); check:SetWidth(150); check:SetHeight(24); check:SetText("Check compatibility"); check:SetPoint("BOTTOMLEFT",10,10); check:SetScript("OnClick",RequestCompatibility)
  RenderCompatibility()

  p:SetScript("OnShow",function()
    local s=Settings(); for key,c in pairs(controls) do c:SetChecked(s[key] and true or false) end
    slider:SetValue(s.scale)
  end)
  InterfaceOptions_AddCategory(p)

  local a=CreateFrame("Frame","REALMOPS_AuditOptionsPanel",UIParent); a.name="Audit & Instances"; a.parent="RealmOps"
  local at=a:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); at:SetPoint("TOPLEFT",16,-16); at:SetText("RealmOps — Audit & Instances")
  local an=a:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); an:SetPoint("TOPLEFT",at,"BOTTOMLEFT",0,-8); an:SetText("Display, filtering, bind-reset safety, and instance defaults.")
  local auditControls={}
  Check(a,auditControls,"AuditTips","Show complete audit reason tooltips","auditTooltips",-70,"Show the complete diagnostic reason while hovering.")
  Check(a,auditControls,"WrapAudit","Wrap long audit reasons","wrapAuditReasons",-102,"Use a narrower result canvas for easier reading.")
  Check(a,auditControls,"AuditWheel","Enable mouse-wheel audit scrolling","mouseWheelAudit",-134,"Scroll raid results with the mouse wheel.")
  Check(a,auditControls,"ProblemsFirst","Sort problems first","problemsFirst",-166,"Order FAIL, OFFLINE, WARN, then PASS.")
  Check(a,auditControls,"RememberFilter","Remember the selected audit filter","rememberAuditFilter",-198,"Restore the last selected result filter.")
  Check(a,auditControls,"AutoAudit","Automatically re-audit after a bind reset","autoReaudit",-230,"Repeat the last audit after an accepted bind reset.")
  Check(a,auditControls,"ConfirmMapReset","Confirm a selected map reset","confirmResetSelected",-262,"Confirm before removing one map/difficulty bind.")
  Check(a,auditControls,"ConfirmAllReset","Confirm reset of all instance binds","confirmResetAll",-294,"Confirm before removing every removable bind.")
  Check(a,auditControls,"WarnTarget","Warn when no player is selected","warnNoTarget",-326,"Prevent bind commands from accidentally applying to yourself.")
  Check(a,auditControls,"CompactRows","Use compact audit result rows","compactAuditRows",-358,"Fit more member results into the audit view.")
  Check(a,auditControls,"ShiftClick","Enable Shift-click link insertion","shiftClickInsert",-390,"With a RealmOps field focused, Shift-click an item, quest, spell, or player link to insert it.")

  local diffLabel=a:CreateFontString(nil,"ARTWORK","GameFontNormal"); diffLabel:SetPoint("TOPLEFT",22,-438); diffLabel:SetText("Default instance difficulty")
  local diff=CreateFrame("Slider","REALMOPS_OptDifficulty",a,"OptionsSliderTemplate"); diff:SetPoint("TOPLEFT",22,-462); diff:SetWidth(200); diff:SetMinMaxValues(0,3); diff:SetValueStep(1)
  _G[diff:GetName().."Low"]:SetText("0"); _G[diff:GetName().."High"]:SetText("3")
  diff:SetScript("OnValueChanged",function(self,value) value=math.floor(value+.5); Settings().defaultDifficulty=value; _G[self:GetName().."Text"]:SetText(tostring(value)); if auditUI.diffBox then auditUI.diffBox:SetText(tostring(value)) end end)

  local fontLabel=a:CreateFontString(nil,"ARTWORK","GameFontNormal"); fontLabel:SetPoint("TOPLEFT",270,-438); fontLabel:SetText("Audit font size")
  local font=CreateFrame("Slider","REALMOPS_OptAuditFont",a,"OptionsSliderTemplate"); font:SetPoint("TOPLEFT",270,-462); font:SetWidth(200); font:SetMinMaxValues(8,14); font:SetValueStep(1)
  _G[font:GetName().."Low"]:SetText("8"); _G[font:GetName().."High"]:SetText("14")
  font:SetScript("OnValueChanged",function(self,value) value=math.floor(value+.5); Settings().auditFontSize=value; _G[self:GetName().."Text"]:SetText(tostring(value)); ApplySettings() end)

  a:SetScript("OnShow",function()
    local s=Settings(); for key,c in pairs(auditControls) do c:SetChecked(s[key] and true or false) end
    diff:SetValue(s.defaultDifficulty); font:SetValue(s.auditFontSize)
  end)
  InterfaceOptions_AddCategory(a)
end

local function BuildUI()
  main=CreateFrame("Frame","REALMOPS_MainFrame",UIParent); main:SetWidth(1050); main:SetHeight(650); main:SetClampedToScreen(true); main:SetFrameStrata("DIALOG"); Backdrop(main); RestorePoint(main,"main","CENTER",0,0); Movable(main,"main")
  local logo=main:CreateTexture(nil,"ARTWORK"); logo:SetTexture("Interface\AddOns\RealmOps\Media\realmops-icon.tga"); logo:SetWidth(28); logo:SetHeight(28); logo:SetPoint("TOPLEFT",14,-8)
  local title=Label(main,"RealmOps  |cffaaaaaa"..ADDON_VERSION.."|r"); title:SetPoint("TOPLEFT",50,-15)
  Button(main,"?",22,20,OpenOptions,"Open RealmOps options"):SetPoint("TOPRIGHT",-66,-10)
  Button(main,"_",22,20,HideMain,"Minimize to floating button"):SetPoint("TOPRIGHT",-38,-10)
  Button(main,"X",22,20,HideMain,"Close"):SetPoint("TOPRIGHT",-10,-10)
  local nav=CreateFrame("Frame",nil,main); nav:SetPoint("TOPLEFT",10,-48); nav:SetPoint("BOTTOMLEFT",10,34); nav:SetWidth(150); Backdrop(nav,C.panel)
  local names={"Eligibility","Character","NPC","Quest","Instances","Teleport","Item"}
  for i,n in ipairs(names) do local b=Button(nav,n,128,32,function() SelectTab(n) end); b:SetPoint("TOPLEFT",11,-12-(i-1)*40); tabs[n]=b end
  local about=nav:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); about:SetPoint("BOTTOMLEFT",12,14); about:SetText("Protocol v"..PROTOCOL_VERSION.."
AzerothCore RealmOps"); about:SetTextColor(.6,.65,.7,1)
  content=CreateFrame("Frame",nil,main); content:SetPoint("TOPLEFT",170,-48); content:SetPoint("BOTTOMRIGHT",-10,34); Backdrop(content,C.panel)
  statusText=main:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); statusText:SetPoint("BOTTOMLEFT",174,12); statusText:SetPoint("BOTTOMRIGHT",-14,12); statusText:SetJustifyH("LEFT")
  BuildEligibility(); BuildCharacter(); BuildNPC(); BuildQuest(); BuildTeleport(); BuildItem(); BuildInstances(); SelectTab(RealmOpsDB.activeTab or "Eligibility")

  mini=CreateFrame("Button","REALMOPS_MiniButton",UIParent); mini:SetWidth(36); mini:SetHeight(28); mini:SetClampedToScreen(true); mini:SetFrameStrata("DIALOG"); Backdrop(mini); RestorePoint(mini,"mini","CENTER",290,0); Movable(mini,"mini")
  local mi=mini:CreateTexture(nil,"ARTWORK"); mi:SetTexture("Interface\AddOns\RealmOps\Media\realmops-icon.tga"); mi:SetAllPoints()
  mini:SetScript("OnClick",function(self) if self._dragged then self._dragged=nil; return end; ShowMain() end); mini:Hide()
  minimapButton=CreateFrame("Button","REALMOPS_MinimapButton",Settings().mbfCompatibility and UIParent or Minimap); minimapButton:SetWidth(24); minimapButton:SetHeight(22); minimapButton:SetFrameStrata("MEDIUM"); minimapButton:RegisterForClicks("LeftButtonUp","RightButtonUp"); minimapButton:RegisterForDrag("LeftButton")
  local bg=minimapButton:CreateTexture(nil,"BACKGROUND"); bg:SetTexture("Interface\Minimap\UI-Minimap-Background"); bg:SetAllPoints()
  local bd=minimapButton:CreateTexture(nil,"OVERLAY"); bd:SetTexture("Interface\Minimap\MiniMap-TrackingBorder"); bd:SetPoint("TOPLEFT",-6,6); bd:SetPoint("BOTTOMRIGHT",6,-6)
  local icon=minimapButton:CreateTexture(nil,"ARTWORK"); icon:SetTexture("Interface\AddOns\RealmOps\Media\realmops-icon.tga"); icon:SetPoint("TOPLEFT",2,-2); icon:SetPoint("BOTTOMRIGHT",-2,2)
  minimapButton:SetScript("OnClick",function(_,button) if button=="RightButton" then HideMain() elseif main:IsShown() then HideMain() else ShowMain() end end)
  minimapButton:SetScript("OnDragStart",function(self) self:SetScript("OnUpdate",function() local mx,my=Minimap:GetCenter(); local px,py=GetCursorPosition(); local s=Minimap:GetEffectiveScale(); RealmOpsDB.minimapAngle=math.deg(math.atan2(py/s-my,px/s-mx)); PositionMinimap() end) end)
  minimapButton:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end); PositionMinimap(); ApplySettings()
  if Settings().startMinimized then HideMain() end
end

local events=CreateFrame("Frame"); events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_ENTERING_WORLD"); events:RegisterEvent("CHAT_MSG_SYSTEM"); events:RegisterEvent("UPDATE_INSTANCE_INFO"); events:RegisterEvent("PLAYER_TARGET_CHANGED")
local compatibilityRequested=false
events:SetScript("OnEvent",function(_,event,arg1)
  if event=="ADDON_LOADED" then if arg1~=ADDON then return end; RealmOpsDB=RealmOpsDB or {}; Settings(); BuildOptions(); BuildUI(); Print("v"..ADDON_VERSION.." loaded. Type /realmops help")
  elseif event=="PLAYER_ENTERING_WORLD" and not compatibilityRequested then compatibilityRequested=true; SendChatMessage(CMD.version,"SAY")
  elseif event=="UPDATE_INSTANCE_INFO" then RefreshMyInstances(true)
  elseif event=="PLAYER_TARGET_CHANGED" then RenderInstances()
  elseif event=="CHAT_MSG_SYSTEM" and tostring(arg1):find("^REALMOPS|") then
    local kind=tostring(arg1):match("^REALMOPS|([^|]+)")
    local f=ParseAuditFields(arg1)
    if kind=="VERSION" then
      compatUI.data=f; RenderCompatibility()
      local ok=tostring(f.protocol or "")==PROTOCOL_VERSION
      SetStatus(ok and "RealmOps server module detected; protocol compatible" or "RealmOps addon/module protocol mismatch",not ok)
    elseif kind=="QUEST_SEARCH" then
      if #questUI.results<6 then table.insert(questUI.results,f) end; RenderQuest(); RenderEligibility(); SetStatus(#questUI.results.." quest match(es) with faction data")
    elseif kind=="QUEST_SEARCH_END" then
      if #questUI.results==0 then SetStatus("No matching quests found.",true) else SetStatus(#questUI.results.." quest result(s); select one for details") end
    elseif kind=="QUEST_INFO" then
      questUI.info=f; questUI.chain={}; RenderQuest(); RenderEligibility(); SetStatus("Loaded quest "..(f.id or "?").." compatibility")
    elseif kind=="QUEST_CHAIN" then
      table.insert(questUI.chain,f); RenderQuest(); RenderEligibility()
    elseif kind=="QUEST_INFO_END" then
      RenderQuest(); RenderEligibility(); SetStatus("Quest details and chain loaded")
    elseif kind=="QUEST_AUDIT_BEGIN" then
      questUI.auditActive=true; questUI.auditMembers={}; questUI.auditQuest=tonumber(f.id); RenderQuest(); RenderEligibility(); SetStatus("Quest group audit started")
    elseif kind=="QUEST_AUDIT_MEMBER" then
      table.insert(questUI.auditMembers,f); RenderQuest(); RenderEligibility()
    elseif kind=="QUEST_AUDIT_END" then
      RenderQuest(); RenderEligibility(); SetStatus("Quest group audit completed for "..#questUI.auditMembers.." member(s)")
    elseif kind=="QUEST_ERROR" then SetStatus(f.reason or "Quest module error",true)
    elseif kind=="SEARCH" then
      if #auditUI.search<8 then table.insert(auditUI.search,f) end; RenderAudit(); RenderEligibility(); SetStatus(#auditUI.search.." instance match(es)")
    elseif kind=="BEGIN" then
      auditUI.members={}; RenderAudit(); RenderEligibility(); SetStatus("Auditing "..(f.name or "instance").."...")
    elseif kind=="MEMBER" then
      table.insert(auditUI.members,f); RenderAudit(); RenderEligibility()
    elseif kind=="END" then
      local pass,fail,warn=0,0,0; for _,r in ipairs(auditUI.members) do if r.result=="PASS" then pass=pass+1 elseif r.result=="WARN" then warn=warn+1 else fail=fail+1 end end
      RenderEligibility(); SetStatus(string.format("Audit complete: %d pass, %d warning, %d fail/offline",pass,warn,fail))
    elseif kind=="ERROR" then SetStatus(f.reason or "Instance audit error",true) end
  elseif event=="CHAT_MSG_SYSTEM" and instanceUI.captureUntil>0 and GetTime()<=instanceUI.captureUntil then
    local plain=tostring(arg1):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local map,inst,perm,diff,canReset,ttr=plain:match("map:%s*(%d+),%s*inst:%s*(%d+),%s*perm:%s*(%a+),%s*diff:%s*(%d+),%s*canReset:%s*(%a+),%s*TTR:%s*(.-)%s*$")
    if map then
      table.insert(instanceUI.target,{map=tonumber(map),instance=tonumber(inst),perm=perm,difficulty=tonumber(diff),canReset=canReset,ttr=ttr})
      RenderInstances(); SetStatus(#instanceUI.target.." selected-player bind(s) captured")
    end
  elseif event=="CHAT_MSG_SYSTEM" and lookup.kind and GetTime()<=lookup.expires then
    local pattern=lookup.kind=="quest" and "|Hquest:(%d+)[^|]*|h([^|]+)|h" or "|Hitem:(%d+)[^|]*|h([^|]+)|h"
    for id,title in tostring(arg1):gmatch(pattern) do
      StoreLookupResult(id,title,arg1:match("(|H"..lookup.kind..":"..id.."[^|]*|h[^|]+|h)"),"")
    end
    -- Playerbot builds commonly print plain lookup lines, for example:
    -- 24510 - [Inside the Frozen Citadel] [Rewarded]
    local plain=tostring(arg1):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
    local id,title,suffix=plain:match("^%s*(%d+)%s*%-%s*(%b[])%s*(.-)%s*$")
    if id and title then StoreLookupResult(id,title,nil,suffix) end
  end
end)

-- Structured module messages are consumed by RealmOps and hidden from normal chat.
if ChatFrame_AddMessageEventFilter then
  ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,message) return Settings().hideAuditChat and tostring(message):find("^REALMOPS|")~=nil end)
end

SLASH_REALMOPS1="/realmops"; SLASH_REALMOPS2="/ro"; SlashCmdList.REALMOPS=function(msg)
  msg=(msg or ""):lower():match("^%s*(.-)%s*$")
  if msg=="reset" then ResetPositions()
  elseif msg=="options" or msg=="config" then OpenOptions()
  elseif msg=="help" then Print("/realmops - toggle, /realmops options - settings, /realmops reset - reset positions")
  elseif main:IsShown() then HideMain() else ShowMain() end
end
