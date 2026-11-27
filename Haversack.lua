-- Haversack: one bag window in the mUI style, sorted into a few categories.
local ADDON = ...

---------------------------------------------------------------------------
-- Text (English default, German override)
---------------------------------------------------------------------------
local function SpellName(id, fallback)
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
    if not name and GetSpellInfo then name = GetSpellInfo(id) end
    return name or fallback
end

local L = {
    TITLE  = "Haversack",
    QUEST  = "Quest Items",
    FOOD   = "Food & Water",
    OTHER  = "Everything Else",
    COOKFISH = "Cooking & Fishing",
    OPT_COOKFISH = "Combine Cooking and Fishing items into one category",
    OPT_COOKFISH_TIP = "Ingredients, fish, recipes, fishing poles and lures get their own section instead of landing in Everything Else.",
    OPT_SIZE = "Window size",
    OPT_COLUMNS = "Width: slots per row",
    OPT_SLOTSIZE = "Slot size",
    OPT_SIZE_TIP = "The height follows your bags: fewer slots per row or bigger slots make the window taller.",
    OPT_DEFAULTS = "Defaults",
    FREE   = "Free slots",
    RESET  = "Haversack: window position reset.",
    SORT   = "Sort bags",
    PARTIAL = "Only some bags open – press B for all",
    HELP   = "Haversack: open with B or Shift-B. /haversack reset puts the window back in place.",
}
if GetLocale() == "deDE" then
    L.QUEST = "Questgegenstände"
    L.FOOD  = "Essen & Trinken"
    L.OTHER = "Alles andere"
    L.COOKFISH = "Kochen & Angeln"
    L.OPT_COOKFISH = "Kochen und Angeln in einer Kategorie zusammenfassen"
    L.OPT_COOKFISH_TIP = "Zutaten, Fisch, Rezepte, Angeln und Köder bekommen einen eigenen Abschnitt statt unter Alles andere zu landen."
    L.OPT_SIZE = "Fenstergröße"
    L.OPT_COLUMNS = "Breite: Plätze pro Reihe"
    L.OPT_SLOTSIZE = "Platzgröße"
    L.OPT_SIZE_TIP = "Die Höhe richtet sich nach deinen Taschen: weniger Plätze pro Reihe oder größere Plätze machen das Fenster höher."
    L.OPT_DEFAULTS = "Standard"
    L.FREE  = "Freie Plätze"
    L.RESET = "Haversack: Fensterposition zurückgesetzt."
    L.SORT  = "Taschen sortieren"
    L.PARTIAL = "Nur einige Taschen offen – B zeigt alle"
    L.HELP  = "Haversack: Öffnen mit B oder Umschalt-B. /haversack reset setzt das Fenster zurück."
end

---------------------------------------------------------------------------
-- Categories (matched by item ID / item class, never by English names)
---------------------------------------------------------------------------
local function Set(list) local t = {} for _, id in ipairs(list) do t[id] = true end return t end
local function Join(...)
    local out = {}
    for i = 1, select("#", ...) do for _, v in ipairs((select(i, ...))) do out[#out + 1] = v end end
    return out
end

local RegisterSettings   -- defined near the events
local SOUL_SHARD = 6265   -- shown as a counter in the footer, not in the grid

-- Shared material lists
local HERBS = { 765, 785, 2447, 2449, 2450, 2452, 2453, 3355, 3356, 3357, 3358, 3369, 3818, 3819,
    3820, 3821, 4625, 8153, 8831, 8836, 8838, 8839, 8845, 8846, 13463, 13464, 13465, 13466, 13467, 13468 }
local VIALS = { 3371, 3372, 8925, 18256 }
local ORES = { 2770, 2771, 2772, 2775, 2776, 3858, 7911, 10620, 11370 }
local BARS = { 2840, 2841, 2842, 3575, 3576, 3577, 3859, 3860, 6037, 11371, 12359, 12360, 17771 }
local STONES = { 2835, 2836, 2838, 7912, 12365 }
local LEATHER = { 2934, 2318, 2319, 4234, 4304, 8170,           -- leather
    783, 4232, 4235, 8169, 8171,                                -- hides
    8154, 8167, 7286, 7392, 15408, 15412, 15414, 15415, 15416, 15417 } -- scales & special hides
local CURED = { 4231, 4233, 4236, 8172, 15407 }
local SALT = { 4289, 8150, 15409 }
local THREAD = { 2320, 2321, 4291, 8343, 14341 }
local DYES = { 2324, 2604, 2605, 4340, 4341, 4342, 6260, 6261, 10290 }

-- Trade goods / recipe subclass numbers (same on every client)
local TG_PARTS, TG_EXPLOSIVES, TG_DEVICES = 1, 2, 3
local TG_CLOTH, TG_LEATHER, TG_METAL, TG_HERB, TG_ENCHANTING = 5, 6, 7, 9, 12
local RC_LEATHER, RC_TAILOR, RC_ENGI, RC_BLACKSMITH, RC_ALCHEMY, RC_ENCH = 1, 2, 3, 4, 6, 8

-- Main professions, in the order they claim shared materials (crafting before gathering).
-- skillLine = profession skill line ID, spells = all rank spell IDs (Apprentice .. Artisan).
local PROFESSIONS = {
    { key = "ENCH", en = "Enchanting", de = "Verzauberkunst", skillLine = 333,
      spells = { 7411, 7412, 7413, 13920 }, trade = { TG_ENCHANTING }, recipe = RC_ENCH,
      items = Join({
        10940, 11083, 11137, 11176, 16204,                                    -- dusts
        10938, 10939, 10998, 11082, 11134, 11135, 11174, 11175, 16202, 16203, -- essences
        10978, 11084, 11138, 11139, 11177, 11178, 14343, 14344, 20725,        -- shards, Nexus Crystal
        6217, 6218, 6338, 6339, 11128, 11130, 11144, 11145, 16206, 16207,     -- rods
      }, VIALS) },
    { key = "TAILOR", en = "Tailoring", de = "Schneiderei", skillLine = 197,
      spells = { 3908, 3909, 3910, 12180 }, trade = { TG_CLOTH }, recipe = RC_TAILOR,
      items = Join({
        2589, 2592, 4306, 4338, 14047, 14256, 14342, -- cloth
        2996, 2997, 4305, 4339, 14048,               -- bolts
        14227,                                       -- Ironweb Spider Silk
      }, THREAD, DYES) },
    { key = "ALCH", en = "Alchemy", de = "Alchemie", skillLine = 171,
      spells = { 2259, 3101, 3464, 11611 }, trade = { TG_HERB }, recipe = RC_ALCHEMY,
      items = Join({
        7067, 7068, 7069, 7070,               -- elemental earth/fire/air/water
        7076, 7078, 7080, 7082, 12803, 12808, -- essences
      }, HERBS, VIALS) },
    { key = "BS", en = "Blacksmithing", de = "Schmiedekunst", skillLine = 164,
      spells = { 2018, 3100, 3538, 9785 }, trade = { TG_METAL }, recipe = RC_BLACKSMITH,
      items = Join({ 2880, 3466, 5956 }, BARS, STONES) }, -- flux, hammer
    { key = "ENGI", en = "Engineering", de = "Ingenieurskunst", skillLine = 202,
      spells = { 4036, 4037, 4038, 12656 }, trade = { TG_PARTS, TG_EXPLOSIVES, TG_DEVICES, TG_METAL }, recipe = RC_ENGI,
      items = Join({
        4357, 4364, 4377, 10505, 15992,                   -- blasting powder
        4359, 4361, 4371, 4375, 4382, 4387, 4389, 4399, 4400, 4404,
        7191, 10558, 10559, 10560, 10561, 15994, 16000,   -- parts
        6219, 10498,                                      -- spanner, micro-adjustor
      }, BARS, STONES) },
    { key = "LW", en = "Leatherworking", de = "Lederverarbeitung", skillLine = 165,
      spells = { 2108, 3104, 3811, 10662 }, trade = { TG_LEATHER }, recipe = RC_LEATHER,
      items = Join(LEATHER, CURED, SALT, THREAD, DYES) },
    { key = "MINE", en = "Mining", de = "Bergbau", skillLine = 186,
      spells = { 2575, 2576, 3564, 10248 }, trade = { TG_METAL },
      items = Join({ 2901 }, ORES, BARS, STONES) },  -- Mining Pick
    { key = "HERB", en = "Herbalism", de = "Kräuterkunde", skillLine = 182,
      spells = { 2366, 2368, 3570, 11993 }, trade = { TG_HERB },
      items = HERBS },
    { key = "SKIN", en = "Skinning", de = "Kürschnerei", skillLine = 393,
      spells = { 8613, 8617, 8618, 10768 }, trade = { TG_LEATHER },
      items = Join({ 7005 }, LEATHER) },             -- Skinning Knife
}
-- Camping features (WoW: Forever) that need a main profession, tiers 1 to 3.
-- Cooking, First Aid and Fishing camp items have no category and stay in Everything Else.
local CAMP = {
    ALCH   = { 279956, 279970, 279990 }, -- Mana Well, Fermenter, Alchemy Laboratory
    BS     = { 279944, 279988, 279955 }, -- Sharpening Wheel, Anvil, Master Forge
    ENCH   = { 279976, 279985, 279987 }, -- Enchanted Lute, Arcane Salvager, Arcane Forge
    ENGI   = { 279950, 279949, 279989 }, -- Reagent Bot, Repair Bot, Anarchist's Workbench
    HERB   = { 279962, 279964, 279947 }, -- Incense Candle, Greenhouse, Seed Hybridizer
    LW     = { 279978, 279941, 279945 }, -- Camp Tent, Tanning Rack, Sewing Machine
    MINE   = { 279960, 279948, 279952 }, -- Lodestone, Rock Garden, Molten Foundry
    SKIN   = { 279979, 279969, 279938 }, -- Camp Chair, Field Guide, Trapper's Workbench
    TAILOR = { 279972, 279943, 279959 }, -- Faction Banner, Spinning Wheel, Loom
}

for _, p in ipairs(PROFESSIONS) do
    p.label = GetLocale() == "deDE" and p.de or p.en
    p.itemSet = Set(Join(p.items, CAMP[p.key] or {}))
    p.tradeSet = Set(p.trade)
end

-- Which main professions this character has (refreshed when skills change)
local known = {}
local function RefreshProfessions()
    wipe(known)
    local bySkillLine = {}
    for _, p in ipairs(PROFESSIONS) do bySkillLine[p.skillLine] = p end

    -- 1) modern profession API (skill line IDs, language-safe)
    if GetProfessions and GetProfessionInfo then
        local p1, p2 = GetProfessions()
        for _, idx in pairs({ p1, p2 }) do
            local skillLine = select(7, GetProfessionInfo(idx))
            if skillLine and bySkillLine[skillLine] then known[bySkillLine[skillLine].key] = true end
        end
    end
    -- 2) any rank of the profession spell (all ranks share one name, so check by ID)
    local isKnown = IsPlayerSpell or IsSpellKnown
    for _, p in ipairs(PROFESSIONS) do
        for _, id in ipairs(p.spells) do
            if isKnown and isKnown(id) then known[p.key] = true break end
        end
    end
    -- 3) classic skill list, compared with the game's own spell names
    if GetNumSkillLines and GetSkillLineInfo then
        local names = {}
        for _, p in ipairs(PROFESSIONS) do
            names[p.label] = p
            local s = SpellName(p.spells[1], nil)
            if s then names[s] = p end
        end
        for i = 1, GetNumSkillLines() do
            local name, isHeader = GetSkillLineInfo(i)
            if name and not isHeader and names[name] then known[names[name].key] = true end
        end
    end
end

local CLASS_CONSUMABLE = (Enum.ItemClass and Enum.ItemClass.Consumable) or 0
local CLASS_TRADEGOODS = (Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7
local CLASS_RECIPE     = (Enum.ItemClass and Enum.ItemClass.Recipe) or 9
local CLASS_QUEST      = (Enum.ItemClass and Enum.ItemClass.Questitem) or 12
local CLASS_WEAPON     = (Enum.ItemClass and Enum.ItemClass.Weapon) or 2
local CLASS_ARMOR      = (Enum.ItemClass and Enum.ItemClass.Armor) or 4
local SUB_FOOD         = (Enum.ItemConsumableSubclass and Enum.ItemConsumableSubclass.Fooddrink) or 5
local TG_COOKING       = (Enum.ItemTradeGoodsSubclass and Enum.ItemTradeGoodsSubclass.Cooking) or 8
local WEAPON_FISHPOLE  = (Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Fishingpole) or 20
local RC_COOKING, RC_FISHING = 5, 9   -- recipe subclasses (books)

-- Optional "Cooking & Fishing" category (off by default, see the options page).
-- Matched by class/subclass plus these item IDs: poles, lures, spices.
local COOKFISH_ITEMS = Set({
    6256, 6365, 6366, 6367, 12225, 19022, 19970, 25978,  -- fishing poles
    6529, 6530, 6532, 6533, 6811,                        -- lures, bait
    2678, 2692, 3713,                                    -- Mild / Hot / Soothing Spices
})

local FOOD_SPELL  = SpellName(433, nil)  -- "Food", in the client language
local DRINK_SPELL = SpellName(430, nil)  -- "Drink"

local CATEGORIES = {
    { key = "QUEST", label = L.QUEST },
    { key = "FOOD",  label = L.FOOD },
}
for _, p in ipairs(PROFESSIONS) do CATEGORIES[#CATEGORIES + 1] = { key = p.key, label = p.label } end
CATEGORIES[#CATEGORIES + 1] = { key = "COOKFISH", label = L.COOKFISH }
CATEGORIES[#CATEGORIES + 1] = { key = "OTHER", label = L.OTHER }

local function ProfessionFor(itemID, classID, subClassID)
    for _, p in ipairs(PROFESSIONS) do
        if known[p.key] and (p.itemSet[itemID]
            or (classID == CLASS_TRADEGOODS and p.tradeSet[subClassID])
            or (classID == CLASS_RECIPE and p.recipe and subClassID == p.recipe)) then
            return p.key
        end
    end
end

local function Categorize(itemID, bag, slot)

    local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
    if classID == CLASS_QUEST then return "QUEST" end
    local q = C_Container.GetContainerItemQuestInfo and C_Container.GetContainerItemQuestInfo(bag, slot)
    if q and (q.isQuestItem or q.questID) then return "QUEST" end

    local prof = ProfessionFor(itemID, classID, subClassID)
    if prof then return prof end

    if HaversackDB and HaversackDB.combineCookFish
        and (COOKFISH_ITEMS[itemID]
            or (classID == CLASS_TRADEGOODS and subClassID == TG_COOKING)
            or (classID == CLASS_WEAPON and subClassID == WEAPON_FISHPOLE)
            or (classID == CLASS_RECIPE and (subClassID == RC_COOKING or subClassID == RC_FISHING))) then
        return "COOKFISH"
    end

    if classID == CLASS_CONSUMABLE then
        if subClassID == SUB_FOOD then return "FOOD" end
        local spell = C_Item.GetItemSpell and C_Item.GetItemSpell(itemID)
        if spell and (spell == FOOD_SPELL or spell == DRINK_SPELL) then return "FOOD" end
    end
    return "OTHER"
end

---------------------------------------------------------------------------
-- mUI look
---------------------------------------------------------------------------
local function HasMUI() return type(_G.mUI) == "table" and _G.mUI.Skin and _G.mUI.Color and _G.mUI.db end

local function ThemeColor()
    if HasMUI() then
        local ok, c = pcall(_G.mUI.Color, _G.mUI, 0.15)
        if ok and c then return c[1], c[2], c[3], c[4] or 1 end
    end
    return 0.15, 0.15, 0.15, 1
end

local function SkinFrame(obj)
    if not obj or not HasMUI() then return end
    if obj.GetObjectType and obj:GetObjectType() == "Texture" then
        pcall(_G.mUI.Skin, _G.mUI, { obj }, true)
    else
        pcall(_G.mUI.Skin, _G.mUI, obj)
    end
end

---------------------------------------------------------------------------
-- Layout constants
---------------------------------------------------------------------------
-- COLUMNS and SIZE can be changed on the options page (see ApplyDimensions)
local DEFAULT_COLUMNS, DEFAULT_SIZE = 10, 37
local MIN_COLUMNS, MAX_COLUMNS, MIN_SIZE, MAX_SIZE = 6, 20, 28, 48
local COLUMNS, SIZE, GAP = DEFAULT_COLUMNS, DEFAULT_SIZE, 4
local BORDER_SIZE = 1.5        -- rarity frame thickness in pixels
local QUALITY_MIN = (Enum.ItemQuality and Enum.ItemQuality.Uncommon) or 2
local PAD_X, TOP, HEADER_H, FOOTER_H = 12, 62, 20, 30
local CONTENT_W = COLUMNS * SIZE + (COLUMNS - 1) * GAP

-- Backpack + every equipped bag (incl. soul/special bags). Unused IDs just have 0 slots.
local BAGS, PLAYER_BAG = {}, {}
local LAST_BAG = math.max(4, NUM_BAG_SLOTS or 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 0)
for bag = 0, LAST_BAG do BAGS[#BAGS + 1] = bag PLAYER_BAG[bag] = true end

---------------------------------------------------------------------------
-- Main frame
---------------------------------------------------------------------------
local f = CreateFrame("Frame", "HaversackFrame", UIParent, "ButtonFrameTemplate")
f:SetSize(CONTENT_W + PAD_X * 2, 300)
f:SetFrameStrata("MEDIUM")
f:SetToplevel(true)
f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:Hide()

if f.Inset then f.Inset:Hide() end
if ButtonFrameTemplate_HideButtonBar then pcall(ButtonFrameTemplate_HideButtonBar, f) end
if f.SetTitle then f:SetTitle(L.TITLE) elseif f.TitleText then f.TitleText:SetText(L.TITLE) end
-- darker background behind the slots
local BG_DARKNESS = 0.6   -- 0 = default background, 1 = black
f.tbDarken = f:CreateTexture(nil, "BACKGROUND", nil, 7)
f.tbDarken:SetColorTexture(0, 0, 0, BG_DARKNESS)
if f.Bg then
    f.tbDarken:SetAllPoints(f.Bg)
else
    f.tbDarken:SetPoint("TOPLEFT", 4, -22)
    f.tbDarken:SetPoint("BOTTOMRIGHT", -4, 4)
end

local PORTRAIT = "Interface\\Icons\\INV_Misc_Bag_08"
if f.SetPortraitToAsset then
    f:SetPortraitToAsset(PORTRAIT)
elseif f.portrait and SetPortraitToTexture then
    SetPortraitToTexture(f.portrait, PORTRAIT)
end

-- Search box
local search = CreateFrame("EditBox", "HaversackSearchBox", f, "SearchBoxTemplate")
search:SetSize(CONTENT_W - 52 - 30, 20)
search:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X + 50, -32) -- clear of the portrait
search:SetAutoFocus(false)
search:HookScript("OnTextChanged", function(self)
    if C_Container.SetItemSearch then C_Container.SetItemSearch(self:GetText() or "") end
end)

-- Sort button (the game's own "Clean Up Bags": sorts and merges stacks)
local sortButton = CreateFrame("Button", nil, f)
sortButton:SetSize(24, 24)
sortButton:SetPoint("LEFT", search, "RIGHT", 6, 0)
local function SetSortArt(tex, atlas, fallback)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        tex:SetAtlas(atlas)
    else
        tex:SetTexture(fallback)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
end
local BROOM = "Interface\\Icons\\INV_Pet_Broom"
sortButton:SetNormalTexture(BROOM)
SetSortArt(sortButton:GetNormalTexture(), "bags-button-autosort-up", BROOM)
sortButton:SetPushedTexture(BROOM)
SetSortArt(sortButton:GetPushedTexture(), "bags-button-autosort-down", BROOM)
sortButton:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
sortButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(BAG_CLEANUP_BAGS or L.SORT, 1, 1, 1)
    GameTooltip:Show()
end)
sortButton:SetScript("OnLeave", GameTooltip_Hide)
sortButton:SetScript("OnClick", function()
    if InCombatLockdown() then return end
    PlaySound(SOUNDKIT.UI_BAG_SORTING_01 or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    C_Container.SortBags()
end)
local hasSort = C_Container and C_Container.SortBags and true or false
if not hasSort then sortButton:Hide() end

-- Footer with gold
local footer = CreateFrame("Frame", nil, f)
footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 8, 6)
footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 6)
footer:SetHeight(22)
footer.bg = footer:CreateTexture(nil, "BACKGROUND")
footer.bg:SetAllPoints()
footer.bg:SetColorTexture(0, 0, 0, 0.45)
footer.border = footer:CreateTexture(nil, "BORDER")
footer.border:SetPoint("TOPLEFT"); footer.border:SetPoint("TOPRIGHT")
footer.border:SetHeight(1)
footer.money = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
footer.money:SetPoint("RIGHT", footer, "RIGHT", -8, 0)
footer.free = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
footer.free:SetPoint("LEFT", footer, "LEFT", 8, 0)

local function CoinString(money)
    if C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString then
        return C_CurrencyInfo.GetCoinTextureString(money)
    end
    return GetCoinTextureString(money)
end

-- Soul Shard counter next to the gold (warlocks only; class token is language-safe)
footer.shards = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
footer.shards:SetPoint("RIGHT", footer.money, "LEFT", -14, 0)
local IS_WARLOCK = select(2, UnitClass("player")) == "WARLOCK"

local function UpdateMoney()
    footer.money:SetText(CoinString(GetMoney()))
    if IS_WARLOCK then
        local count = C_Item.GetItemCount(SOUL_SHARD) or 0
        local icon = C_Item.GetItemIconByID(SOUL_SHARD) or 134075
        footer.shards:SetFormattedText("%d |T%s:11:11:0:0:64:64:5:59:5:59|t", count, icon)
        footer.shards:Show()
    else
        footer.shards:Hide()
    end
end

---------------------------------------------------------------------------
-- Item buttons
-- The slot buttons are BORROWED from Blizzard's own bag windows. Blizzard made
-- them, so the game trusts them in combat (moving / using items works), and
-- Blizzard keeps updating icons, counts, cooldowns, locks, search and new-item
-- glow itself. Haversack only moves them into categories and adds its look.
-- Never call Blizzard's button methods from here (that would taint them);
-- only position, show/hide and draw our own textures.
---------------------------------------------------------------------------
local used, headers, styled = {}, {}, {}
local borrowed = {}   -- every Blizzard slot button we have ever moved into our window

-- Square "Caith"-style slot: soft shadow, black edge, thin frame, square icon
local FRAME_COLOR = { 0.3, 0.3, 0.3 }
local ICON_INSET = 1 + BORDER_SIZE + 1   -- black edge + frame + 1px black gap

local function Inset(tex, parent, px)
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", parent, "TOPLEFT", px, -px)
    tex:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -px, px)
end

local function StyleButton(b)
    if styled[b] then return styled[b] end
    local s = {}

    -- soft shadow: stacked transparent black squares reaching outside the slot
    for i, alpha in ipairs({ 0.35, 0.2, 0.1 }) do
        local sh = b:CreateTexture(nil, "BACKGROUND", nil, -8)
        sh:SetColorTexture(0, 0, 0, alpha)
        Inset(sh, b, -i)
    end
    -- black base (outer 1px edge and the gap around the icon)
    local base = b:CreateTexture(nil, "BACKGROUND", nil, -7)
    base:SetColorTexture(0, 0, 0, 1)
    base:SetAllPoints()
    -- empty slot fill
    local slotBG = b:CreateTexture(nil, "BACKGROUND", nil, -6)
    slotBG:SetColorTexture(0.09, 0.09, 0.09, 1)
    Inset(slotBG, b, ICON_INSET)

    -- frame: gray, or rarity / quest colored
    s.border = {}
    for i = 1, 4 do
        local t = b:CreateTexture(nil, "OVERLAY", nil, 1)
        t:SetColorTexture(1, 1, 1, 1)
        s.border[i] = t
    end
    local tb, o = s.border, 1
    tb[1]:SetPoint("TOPLEFT", b, "TOPLEFT", o, -o); tb[1]:SetPoint("TOPRIGHT", b, "TOPRIGHT", -o, -o); tb[1]:SetHeight(BORDER_SIZE)
    tb[2]:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", o, o); tb[2]:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -o, o); tb[2]:SetHeight(BORDER_SIZE)
    tb[3]:SetPoint("TOPLEFT", b, "TOPLEFT", o, -o); tb[3]:SetPoint("BOTTOMLEFT", b, "BOTTOMLEFT", o, o); tb[3]:SetWidth(BORDER_SIZE)
    tb[4]:SetPoint("TOPRIGHT", b, "TOPRIGHT", -o, -o); tb[4]:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -o, o); tb[4]:SetWidth(BORDER_SIZE)

    -- square icon (crop the round-ish edges of the art)
    local icon = b.icon or b.Icon
    if icon then
        Inset(icon, b, ICON_INSET)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    if b.Cooldown then Inset(b.Cooldown, b, ICON_INSET) end

    -- square highlight / pressed look instead of Blizzard's rounded ones
    local hl = b.GetHighlightTexture and b:GetHighlightTexture()
    if hl then hl:SetColorTexture(1, 1, 1, 0.15) Inset(hl, b, ICON_INSET) end
    local pushed = b.GetPushedTexture and b:GetPushedTexture()
    if pushed then pushed:SetColorTexture(0, 0, 0, 0.35) Inset(pushed, b, ICON_INSET) end
    if b.NewItemTexture then Inset(b.NewItemTexture, b, 1) end

    s.level = b:CreateFontString(nil, "OVERLAY")
    s.level:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
    s.level:SetPoint("CENTER", b, "BOTTOM", 0, 8)
    s.level:Hide()

    s.free = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    s.free:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -3, 3)
    s.free:SetTextColor(0.6, 0.6, 0.6)
    s.free:Hide()

    b:HookScript("OnEnter", function(self)
        local st = styled[self]
        if st and st.isFree and used[self] then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(L.FREE .. ": " .. (st.freeCount or 0), 1, 1, 1)
            GameTooltip:Show()
        end
    end)

    styled[b] = s
    return s
end

local function SetFrameColor(s, r, g, bl)
    for _, t in ipairs(s.border) do t:SetVertexColor(r, g, bl, 1) end
end

-- mUI already draws item levels on Blizzard's bag buttons, so only draw ours without mUI
local function UpdateItemLevel(s, bag, slot, info)
    s.level:Hide()
    if _G.mUI then return end
    if not info or not info.itemID then return end
    local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(info.itemID)
    if classID ~= CLASS_WEAPON and classID ~= CLASS_ARMOR then return end
    local item = Item:CreateFromBagAndSlot(bag, slot)
    if item:IsItemEmpty() then return end
    local wantID = info.itemID
    item:ContinueOnItemLoad(function()
        local now = C_Container.GetContainerItemInfo(bag, slot)
        if not now or now.itemID ~= wantID then return end
        local ilvl = item:GetCurrentItemLevel()
        if not ilvl then return end
        local _, _, _, hex = C_Item.GetItemQualityColor(item:GetItemQuality() or 1)
        s.level:SetFormattedText("|c%s%d|r", hex or "ffffffff", ilvl)
        s.level:Show()
    end)
end

-- Our look on top of whatever Blizzard drew (only textures we own or plain hide/alpha)
local function Decorate(b, bag, slot, info)
    local s = StyleButton(b)
    if b.IconBorder then b.IconBorder:Hide() end
    if b.ItemSlotBackground then b.ItemSlotBackground:SetAlpha(0) end
    local normal = b.GetNormalTexture and b:GetNormalTexture()
    if normal then normal:SetAlpha(0) end

    local q = C_Container.GetContainerItemQuestInfo and info and C_Container.GetContainerItemQuestInfo(bag, slot)
    local tex = b.IconQuestTexture
    if tex then
        if q and q.questID and not q.isActive then
            Inset(tex, b, ICON_INSET)   -- keep the "!" for quest starters
        else
            tex:Hide()                  -- the yellow frame below replaces the round quest border
        end
    end

    if q and (q.questID or q.isQuestItem) then
        SetFrameColor(s, 1, 0.8, 0)
    elseif info and info.quality and info.quality >= QUALITY_MIN then
        SetFrameColor(s, C_Item.GetItemQualityColor(info.quality))
    else
        SetFrameColor(s, FRAME_COLOR[1], FRAME_COLOR[2], FRAME_COLOR[3])
    end

    UpdateItemLevel(s, bag, slot, info)
    s.isFree = nil
    s.free:Hide()
    return s
end

local function GetHeader(key, label)
    local h = headers[key]
    if not h then
        h = CreateFrame("Frame", nil, f)
        h:SetSize(CONTENT_W, HEADER_H)
        h.text = h:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        h.text:SetPoint("LEFT", h, "LEFT", 1, 0)
        h.text:SetText(label)
        h.line = h:CreateTexture(nil, "ARTWORK")
        h.line:SetHeight(1)
        h.line:SetPoint("LEFT", h.text, "RIGHT", 6, 0)
        h.line:SetPoint("RIGHT", h, "RIGHT", 0, 0)
        headers[key] = h
    end
    local r, g, b = ThemeColor()
    h.line:SetColorTexture(r + 0.25, g + 0.25, b + 0.25, 0.8)
    return h
end

---------------------------------------------------------------------------
-- Blizzard's bag windows: kept open (so they keep updating) but invisible
---------------------------------------------------------------------------
local NUM_FRAMES = NUM_CONTAINER_FRAMES or 13
local function AllBlizzardFrames()
    local list = {}
    if ContainerFrameCombinedBags then list[#list + 1] = ContainerFrameCombinedBags end
    for i = 1, NUM_FRAMES do
        local c = _G["ContainerFrame" .. i]
        if c then list[#list + 1] = c end
    end
    return list
end

local function ShowsPlayerBag(frame)
    return frame == ContainerFrameCombinedBags or PLAYER_BAG[frame:GetID()]
end

-- Invisible windows must not catch the mouse. Their parts (close button, search
-- box, money, portrait menu...) stay where Blizzard put them, only their mouse is
-- switched off: our X button clicks Blizzard's close buttons (see below).
local concealed = {}   -- [window] = true
local muted = {}       -- [region] = true, mouse switched off by us

-- Slot buttons (ours to show) are recognized by their bag function, not by
-- object type: the type name differs between clients.
local function IsSlotButton(child)
    return child.GetBagID ~= nil or child:IsObjectType("ItemButton")
end

local function SetChildMouse(frame, on)
    for _, child in ipairs({ frame:GetChildren() }) do
        if not IsSlotButton(child) then
            if on then
                if muted[child] then child:EnableMouse(true) muted[child] = nil end
            elseif child:IsMouseEnabled() then
                child:EnableMouse(false)
                muted[child] = true
            end
            SetChildMouse(child, on)
        end
    end
end

local function Conceal(frame)
    if not concealed[frame] then
        concealed[frame] = true
        frame:SetAlpha(0)
        frame:EnableMouse(false)
    end
    -- rescanned each time: Blizzard moves some parts (search box, token bar) between windows
    SetChildMouse(frame, false)
end

local function Unconceal(frame)
    if concealed[frame] then
        concealed[frame] = nil
        frame:SetAlpha(1)
        frame:EnableMouse(true)
        SetChildMouse(frame, true)
    end
    -- a reused window may still have slot buttons we borrowed earlier
    if frame.EnumerateValidItems then
        for _, b in frame:EnumerateValidItems() do
            if b and b:GetParent() ~= frame then b:SetParent(frame) end
            if b then borrowed[b] = nil end
        end
    end
end

local function BlizzardBagsOpen()
    local open = false
    for _, frame in ipairs(AllBlizzardFrames()) do
        if frame:IsShown() then
            if ShowsPlayerBag(frame) then
                open = true
                if not concealed[frame] then Conceal(frame) end
            else
                Unconceal(frame)   -- bank bags keep their normal window
            end
        end
    end
    return open
end

---------------------------------------------------------------------------
-- Sorting & layout
---------------------------------------------------------------------------
-- Within a category: item type, then rarity (best first), then name.
local function SortItems(a, b)
    if a.classID ~= b.classID then return (a.classID or 99) < (b.classID or 99) end
    if a.quality ~= b.quality then return (a.quality or 0) > (b.quality or 0) end
    if a.name ~= b.name then return a.name < b.name end
    if a.itemID ~= b.itemID then return a.itemID < b.itemID end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end

-- Everything Else: rarity first (epic, rare, uncommon, common, poor), then the same as above.
local function SortByRarity(a, b)
    if a.quality ~= b.quality then return (a.quality or 0) > (b.quality or 0) end
    if a.classID ~= b.classID then return (a.classID or 99) < (b.classID or 99) end
    if a.name ~= b.name then return a.name < b.name end
    if a.itemID ~= b.itemID then return a.itemID < b.itemID end
    if a.bag ~= b.bag then return a.bag < b.bag end
    return a.slot < b.slot
end

local pendingCombat = false
local inLayout = false

-- Width = slots per row, slot size scales everything; the height follows the contents.
local function Clamp(v, lo, hi, default)
    v = tonumber(v) or default
    return math.max(lo, math.min(hi, math.floor(v + 0.5)))
end
local function ApplyDimensions()
    local db = HaversackDB or {}
    COLUMNS = Clamp(db.columns, MIN_COLUMNS, MAX_COLUMNS, DEFAULT_COLUMNS)
    SIZE = Clamp(db.slotSize, MIN_SIZE, MAX_SIZE, DEFAULT_SIZE)
    CONTENT_W = COLUMNS * SIZE + (COLUMNS - 1) * GAP
    f:SetWidth(CONTENT_W + PAD_X * 2)
    search:SetWidth(CONTENT_W - 52 - (hasSort and 30 or 0))
end

local function Layout()
    if not f:IsShown() or inLayout then return end
    inLayout = true

    local groups = {}
    for _, c in ipairs(CATEGORIES) do groups[c.key] = {} end
    local freeEntry, freeCount, totalSlots = nil, 0, 0
    local bagFamily = {}   -- [bag] = bag family (0 = normal bag), looked up once per layout
    local seen = {}
    wipe(used)

    -- Only some bags open (a bag-bar click opens just that bag)? Then show their
    -- real contents, Soul Shards included, and say so in the footer.
    local partial = false
    for _, bag in ipairs(BAGS) do
        if (C_Container.GetContainerNumSlots(bag) or 0) > 0 and not IsBagOpen(bag) then
            partial = true
            break
        end
    end

    -- The combined window comes first in AllBlizzardFrames, so its buttons win when
    -- a bag is also open in its own window (e.g. after clicking it on the bag bar).
    for _, frame in ipairs(AllBlizzardFrames()) do
        if frame:IsShown() and ShowsPlayerBag(frame) and frame.EnumerateValidItems then
            Conceal(frame)
            for _, b in frame:EnumerateValidItems() do
                local bag = b and b:GetBagID()
                local slot = bag and b:GetID()
                local key = bag and (bag * 1000 + slot)
                if bag and PLAYER_BAG[bag] and not seen[key] then
                    seen[key] = true
                    borrowed[b] = true
                    -- special bags (soul bag, quiver, herb bag...) only hold one kind of
                    -- item, so they don't count as free space
                    if bagFamily[bag] == nil then
                        local _, family = C_Container.GetContainerNumFreeSlots(bag)
                        bagFamily[bag] = family or 0
                    end
                    local normalBag = bagFamily[bag] == 0
                    if normalBag then totalSlots = totalSlots + 1 end
                    local info = C_Container.GetContainerItemInfo(bag, slot)
                    if info and info.itemID then
                        -- Soul Shards are left out of the grid: the footer counter shows them
                        if info.itemID ~= SOUL_SHARD or partial then
                            local name, _, _, _, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(info.itemID)
                            if not classID then classID = select(6, C_Item.GetItemInfoInstant(info.itemID)) end
                            tinsert(groups[Categorize(info.itemID, bag, slot)], {
                                button = b, info = info, bag = bag, slot = slot, itemID = info.itemID,
                                quality = info.quality or 0, name = name or "", classID = classID,
                            })
                        end
                    elseif normalBag then
                        freeCount = freeCount + 1
                        -- one empty slot of a normal bag stands for all of them
                        if not freeEntry then
                            freeEntry = { button = b, bag = bag, slot = slot, isFree = true }
                        end
                    end
                end
            end
        end
    end
    for _, h in pairs(headers) do h:Hide() end
    if freeEntry then tinsert(groups.OTHER, freeEntry) end

    local combat = InCombatLockdown()
    local y = -TOP
    for _, c in ipairs(CATEGORIES) do
        local items = groups[c.key]
        if #items > 0 then
            local h = GetHeader(c.key, c.label)
            h:ClearAllPoints()
            h:SetWidth(CONTENT_W)
            h:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X, y)
            h:Show()
            y = y - HEADER_H

            local free
            if items[#items].isFree then free = tremove(items) end
            table.sort(items, c.key == "OTHER" and SortByRarity or SortItems)
            if free then tinsert(items, free) end

            for i, it in ipairs(items) do
                local b = it.button
                if combat and b:IsProtected() then
                    pendingCombat = true
                else
                    local col = (i - 1) % COLUMNS
                    local row = math.floor((i - 1) / COLUMNS)
                    if b:GetParent() ~= f then b:SetParent(f) end
                    -- undo a mouse switch-off from an older Haversack pass
                    if muted[b] then muted[b] = nil end
                    local ext = b.extendedFrame
                    if not b:IsMouseEnabled() and not (ext and ext:IsShown()) then b:EnableMouse(true) end
                    b:SetFrameLevel(f:GetFrameLevel() + 5)
                    b:SetSize(SIZE, SIZE)
                    b:ClearAllPoints()
                    b:SetPoint("TOPLEFT", f, "TOPLEFT", PAD_X + col * (SIZE + GAP), y - row * (SIZE + GAP))
                    b:Show()
                end
                local s = Decorate(b, it.bag, it.slot, it.info)
                if it.isFree then
                    s.isFree = true
                    s.freeCount = freeCount
                    s.free:SetText(freeCount)
                    s.free:Show()
                end
                used[b] = it
            end
            y = y - math.ceil(#items / COLUMNS) * (SIZE + GAP) - 4
        end
    end

    -- every other borrowed slot (extra empties, Soul Shards, duplicates, slots of
    -- windows that were closed) stays out of sight
    for b in pairs(borrowed) do
        if not used[b] and b:GetParent() == f then
            if combat and b:IsProtected() then
                pendingCombat = true
            else
                b:Hide()
            end
        end
    end

    if partial then
        footer.free:SetText("|cffffd100" .. L.PARTIAL .. "|r")
    else
        footer.free:SetText(L.FREE .. ": " .. freeCount .. "/" .. totalSlots)
    end
    f:SetHeight(-y + FOOTER_H + 6)
    UpdateMoney()
    inLayout = false
end

local layoutQueued = false
local function QueueLayout()
    if layoutQueued then return end
    layoutQueued = true
    C_Timer.After(0, function()
        layoutQueued = false
        Layout()
    end)
end

-- Re-apply our layout right after Blizzard updates or re-anchors its buttons
local hooked = {}
local function HookBlizzardFrames()
    for _, frame in ipairs(AllBlizzardFrames()) do
        if not hooked[frame] then
            hooked[frame] = true
            for _, method in ipairs({ "UpdateItems", "UpdateItemLayout", "UpdateItemSlots" }) do
                if type(frame[method]) == "function" then
                    hooksecurefunc(frame, method, function(self)
                        if f:IsShown() and self:IsShown() and ShowsPlayerBag(self) then Layout() end
                    end)
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Skin (re-applied on every show so mUI theme changes are picked up)
---------------------------------------------------------------------------
local function ApplySkin()
    SkinFrame(f.NineSlice)
    if f.Bg then SkinFrame(f.Bg) end
    if search.Left then SkinFrame(search.Left); SkinFrame(search.Middle); SkinFrame(search.Right) end
    local r, g, b = ThemeColor()
    footer.border:SetColorTexture(r + 0.2, g + 0.2, b + 0.2, 0.9)
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
local function DefaultPosition()
    f:ClearAllPoints()
    f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -60, 110)
end

local function RestorePosition()
    local p = HaversackDB and HaversackDB.pos
    f:ClearAllPoints()
    if p then
        f:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", p.x, p.y)
    else
        DefaultPosition()
    end
end

f:SetScript("OnDragStart", function(self) self:StartMoving() end)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x = self:GetRight() * scale - UIParent:GetRight()
    local y = self:GetBottom() * scale
    HaversackDB.pos = { x = x, y = y }
    -- keep anchored at the bottom right so the window grows upwards
    self:ClearAllPoints()
    self:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", x / scale, y / scale)
end)

---------------------------------------------------------------------------
-- Open / close follows Blizzard's bags (B key, bag buttons, vendors, mail...)
---------------------------------------------------------------------------
-- Nothing here calls CloseAllBags / OpenAllBags / ToggleAllBags: called from an
-- addon they taint Blizzard's bag code, and items or action buttons then get
-- blocked in combat. Opening and closing always goes through Blizzard itself.

-- No X button: the only taint-free ways to close Blizzard's bags are Blizzard's
-- own (B, Shift-B, Escape, leaving a vendor...). A secure X button would make
-- this window protected, so it could no longer open or close in combat.
if f.CloseButton then f.CloseButton:Hide() end

-- B normally opens only the backpack. Send whatever key opens the backpack to
-- Blizzard's own "Open All Bags" (the Shift-B action) instead, as an override
-- binding: the game runs it itself, so nothing is tainted. Your real key
-- bindings are not changed.
local bindOwner = CreateFrame("Frame")
local boundKeys, bindPending = nil, false
local function RedirectBackpackKey()
    if InCombatLockdown() then bindPending = true return end
    local keys = { GetBindingKey("TOGGLEBACKPACK") }
    local id = table.concat(keys, ",")
    if id == boundKeys then return end   -- our own change fires UPDATE_BINDINGS too
    boundKeys = id
    ClearOverrideBindings(bindOwner)
    for _, key in ipairs(keys) do
        SetOverrideBinding(bindOwner, false, key, "OPENALLBAGS")
    end
end

f:SetScript("OnShow", function()
    HookBlizzardFrames()
    ApplySkin()
    Layout()
end)
f:SetScript("OnHide", function()
    search:SetText("")
    search:ClearFocus()
end)

-- Our window simply follows Blizzard's: shown while any of your bags is open.
-- (Escape, NPCs, vendors etc. close Blizzard's bags themselves.)
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function()
    local open = BlizzardBagsOpen()
    if open ~= f:IsShown() then f:SetShown(open) end
end)

---------------------------------------------------------------------------
-- Options page: ESC > Options > AddOns > Haversack
---------------------------------------------------------------------------
-- A plain slider with our own track and thumb (no template: works on every client)
local function MakeSlider(parent, label, lo, hi, get, set)
    local s = CreateFrame("Slider", nil, parent)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(240, 16)
    s:SetMinMaxValues(lo, hi)
    s:SetValueStep(1)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:EnableMouseWheel(true)
    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0, 0, 0, 0.6)
    track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(6)
    local thumb = s:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.8, 0.64, 1, 1)   -- lavender, like the addon title
    thumb:SetSize(10, 16)
    s:SetThumbTexture(thumb)
    s.label = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    s.label:SetPoint("BOTTOMLEFT", s, "TOPLEFT", 0, 4)
    s.label:SetText(label)
    s.value = s:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    s.value:SetPoint("LEFT", s, "RIGHT", 12, 0)
    s.lo = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.lo:SetPoint("TOPLEFT", s, "BOTTOMLEFT", 0, -2); s.lo:SetText(lo)
    s.hi = s:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    s.hi:SetPoint("TOPRIGHT", s, "BOTTOMRIGHT", 0, -2); s.hi:SetText(hi)
    s.Refresh = function(self)
        self.syncing = true
        self:SetValue(get())
        self.syncing = false
        self.value:SetText(get())
    end
    s:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v + 0.5)
        self.value:SetText(v)
        if not self.syncing and v ~= get() then set(v) end
    end)
    s:SetScript("OnMouseWheel", function(self, delta)
        self:SetValue(math.max(lo, math.min(hi, self:GetValue() + delta)))
    end)
    return s
end

local function SetDimension(key, v)
    HaversackDB[key] = v
    ApplyDimensions()
    QueueLayout()
end

RegisterSettings = function()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local c = CreateFrame("Frame")
    local title = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Haversack")
    local cb = CreateFrame("CheckButton", nil, c, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -12)
    cb.text = cb.text or cb.Text
    cb.text:SetText(L.OPT_COOKFISH)
    cb:SetChecked(HaversackDB.combineCookFish and true or false)
    cb:SetScript("OnClick", function(self)
        HaversackDB.combineCookFish = self:GetChecked() and true or false
        QueueLayout()
    end)
    local tip = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tip:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, -2)
    tip:SetWidth(520)
    tip:SetJustifyH("LEFT")
    tip:SetText(L.OPT_COOKFISH_TIP)

    -- Window size
    local sizeHead = c:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    sizeHead:SetPoint("TOPLEFT", tip, "BOTTOMLEFT", -28, -28)
    sizeHead:SetText(L.OPT_SIZE)
    local cols = MakeSlider(c, L.OPT_COLUMNS, MIN_COLUMNS, MAX_COLUMNS,
        function() return COLUMNS end, function(v) SetDimension("columns", v) end)
    cols:SetPoint("TOPLEFT", sizeHead, "BOTTOMLEFT", 4, -30)
    local size = MakeSlider(c, L.OPT_SLOTSIZE, MIN_SIZE, MAX_SIZE,
        function() return SIZE end, function(v) SetDimension("slotSize", v) end)
    size:SetPoint("TOPLEFT", cols, "BOTTOMLEFT", 0, -40)
    local sizeTip = c:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sizeTip:SetPoint("TOPLEFT", size, "BOTTOMLEFT", 0, -22)
    sizeTip:SetWidth(520)
    sizeTip:SetJustifyH("LEFT")
    sizeTip:SetText(L.OPT_SIZE_TIP)
    local reset = CreateFrame("Button", nil, c, "UIPanelButtonTemplate")
    reset:SetSize(110, 22)
    reset:SetPoint("TOPLEFT", sizeTip, "BOTTOMLEFT", 0, -12)
    reset:SetText(L.OPT_DEFAULTS)
    reset:SetScript("OnClick", function()
        HaversackDB.columns, HaversackDB.slotSize = nil, nil
        ApplyDimensions()
        QueueLayout()
        cols:Refresh(); size:Refresh()
    end)

    c:SetScript("OnShow", function()
        cb:SetChecked(HaversackDB.combineCookFish and true or false)
        cols:Refresh(); size:Refresh()
    end)
    pcall(function() Settings.RegisterAddOnCategory(Settings.RegisterCanvasLayoutCategory(c, "Haversack")) end)
end

---------------------------------------------------------------------------
-- Events (item visuals are Blizzard's job; these only re-sort or update the footer)
---------------------------------------------------------------------------
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("BAG_UPDATE_DELAYED")
driver:RegisterEvent("PLAYER_MONEY")
driver:RegisterEvent("GET_ITEM_INFO_RECEIVED")
driver:RegisterEvent("QUEST_ACCEPTED")
driver:RegisterEvent("QUEST_REMOVED")
driver:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
driver:RegisterEvent("PLAYER_REGEN_ENABLED")
driver:RegisterEvent("SKILL_LINES_CHANGED")
driver:RegisterEvent("SPELLS_CHANGED")
driver:RegisterEvent("UPDATE_BINDINGS")

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_LOGIN" then
        HaversackDB = HaversackDB or {}
        if HaversackDB.combineCookFish == nil then HaversackDB.combineCookFish = false end
        ApplyDimensions()
        RegisterSettings()
        RestorePosition()
        RefreshProfessions()
        HookBlizzardFrames()
        RedirectBackpackKey()
        -- make the Blizzard bag windows invisible right away (no flash on first open)
        for _, frame in ipairs(AllBlizzardFrames()) do
            if ShowsPlayerBag(frame) or frame:GetID() == 0 then Conceal(frame) end
        end
    elseif event == "SKILL_LINES_CHANGED" or event == "SPELLS_CHANGED" then
        RefreshProfessions()
        QueueLayout()
    elseif event == "PLAYER_MONEY" then
        UpdateMoney()
    elseif event == "UPDATE_BINDINGS" then
        RedirectBackpackKey()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if bindPending then bindPending = false RedirectBackpackKey() end
        if pendingCombat then pendingCombat = false QueueLayout() end
    elseif event == "UNIT_QUEST_LOG_CHANGED" then
        if arg1 == "player" then QueueLayout() end
    else
        QueueLayout()
    end
end)

SLASH_HAVERSACK1 = "/haversack"
SLASH_HAVERSACK2 = "/hsack"
SlashCmdList.HAVERSACK = function(msg)
    if msg and msg:lower():match("reset") then
        HaversackDB.pos = nil
        DefaultPosition()
        print(L.RESET)
    else
        print(L.HELP)
    end
end
