-- Crafting presentation behavior; native artwork still needs a client check.
local fresh, craftingWorld, craftRecipe, test, equal, truth, secret = ...
local function serviceWorld()
    local w,A=craftingWorld()
    w.recipes[4]=craftRecipe(4,nil); w.recipes[4].info.name="Enchant Chest - Test"
    w.recipeIDs={1,2,3,4}; w.selectedID=4
    A.Crafting.Tick()
    return w,A
end
local function list(A,showAll)
    A.DB.data.settings.showAllRecipes=showAll==true
    A.CraftingUI.mode="profit"; A.CraftingUI.Refresh()
end

test("service view shows material cost and quote instead of inapplicable auction profits", function()
    local w,A=serviceWorld(); local UI=A.CraftingUI
    equal(UI.values[1].text,"4s 00c"); equal(UI.values[2].text,"4s 00c")
    equal(UI.valueLabels[2].text,"Quote / service"); truth(UI.serviceHelp:IsShown())
    for index=3,5 do equal(UI.values[index]:IsShown(),false); equal(UI.valueLabels[index]:IsShown(),false) end
    truth(string.find(UI.yield.text,"Service",1,true)); truth(string.find(UI.reason.text,"quote ready",1,true))
    equal(A.Crafting.selected.saleMin,nil); equal(A.Crafting.selected.profitMin,nil)
end)
test("switching from a service restores item sale profit and return fields", function()
    local w,A=serviceWorld(); w.selectedID=1; A.Crafting.Tick(); local UI=A.CraftingUI
    equal(UI.valueLabels[2].text,"Cost / item"); equal(UI.values[4].text,"+4s 55c")
    for index=3,5 do truth(UI.values[index]:IsShown()); truth(UI.valueLabels[index]:IsShown()) end
    equal(UI.serviceHelp:IsShown(),false)
end)
test("catalog totals distinguish quoted services from missing price data", function()
    local w,A=serviceWorld()
    w.recipes[5]=craftRecipe(5,999); w.recipeIDs={1,4,5}
    A.Crafting.Invalidate(); A.Crafting.Tick(); list(A,true)
    local summary=A.CraftingUI.CatalogSummary()
    equal(summary.priced,1); equal(summary.services,1); equal(summary.missing,1)
    truth(string.find(A.CraftingUI.catalogStatus.text,"1 services",1,true))
    local text=A.UI.DiagnosticsText(); truth(string.find(text,"services=1; quote_only=0; needs_data=1",1,true))
end)
test("all-recipes service rows show numeric quotes and still select the native recipe", function()
    local w,A=serviceWorld(); list(A,true); A.CraftingUI.SetSearch("ENCHANT chest")
    local button=A.CraftingUI.catalogRows[1]
    equal(button.recipeID,4); equal(button.profit.text,"4s 00c"); equal(button.percent.text,"Service")
    button.scripts.OnClick(button); equal(w.selectedID,4); equal(A.CraftingUI.mode,"recipe")
    equal(w.openRecipeCalls,1); equal(w.requests,1)
end)
test("recipe search is case insensitive literal text with trimmed whitespace", function()
    local w,A=craftingWorld(); w.recipes[1].info.name="Blue Robe [A+B]%"
    A.Crafting.Tick(); list(A,true); local UI=A.CraftingUI
    UI.SetSearch("  rObE [A+B]%  "); equal(#UI.CatalogView(),1); equal(UI.CatalogView()[1].recipeID,1)
    UI.SetSearch(".*"); equal(#UI.CatalogView(),0); truth(UI.empty:IsShown())
    UI.SetSearch(secret); equal(UI.search,".*")
    UI.clearSearch.scripts.OnClick(); equal(#UI.CatalogView(),3); equal(UI.page,1)
end)
test("search and sorting reuse published recipe valuations without pricing calls", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); list(A,true); local UI=A.CraftingUI
    local builds,published,requests=A.Crafting.builds,A.Crafting.rows,w.requests
    local reads=0; local native=C_TradeSkillUI.GetRecipeSchematic
    C_TradeSkillUI.GetRecipeSchematic=function(...) reads=reads+1; return native(...) end
    UI.SetSearch("Recipe"); local rows=UI.CatalogView()
    for _=1,25 do UI.Refresh(); equal(UI.CatalogView(),rows) end
    UI.sortReturn.scripts.OnClick(); UI.sortProfit.scripts.OnClick()
    equal(A.Crafting.builds,builds); equal(A.Crafting.rows,published); equal(w.requests,requests); equal(reads,0)
end)
test("search honors the profitable-only filter and does not mutate ranked rows", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); list(A,false); local UI=A.CraftingUI
    local ranked=A.Crafting.Ranked("profit"); UI.SetSearch("Recipe 2"); equal(#UI.CatalogView(),0)
    UI.showAllButton.scripts.OnClick(); equal(#UI.CatalogView(),1); equal(UI.CatalogView()[1].profitMin,-100)
    equal(A.Crafting.Ranked("profit"),ranked); equal(#ranked,2)
    UI.searchBox.scripts.OnEscapePressed(UI.searchBox); equal(UI.search,""); equal(#UI.CatalogView(),3)
end)
test("search results invalidate when a complete recipe catalog is published", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); list(A,true); local UI=A.CraftingUI
    UI.SetSearch("Blue"); local old=UI.CatalogView(); equal(#old,0)
    w.recipes[1].info.name="Blue Robe"; A.Crafting.Invalidate(); A.Crafting.Tick()
    equal(#UI.CatalogView(),1); truth(UI.CatalogView()~=old); equal(A.Crafting.publications,2)
end)
test("a profession change clears its local recipe search without changing saved filters", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); list(A,true); local UI=A.CraftingUI
    UI.searchBox:SetText("Recipe 1"); UI.SetSearch("Recipe 1"); equal(#UI.CatalogView(),1)
    w.professionID=197; A.Crafting.Tick()
    equal(UI.search,""); equal(UI.searchBox.text,""); equal(#UI.CatalogView(),3)
    equal(A.DB.Settings().showAllRecipes,true)
end)
test("catalog count summaries remain on the complete published list while rebuilding", function()
    local w,A=serviceWorld(); list(A,true); local UI=A.CraftingUI
    local summary=UI.CatalogSummary(); equal(summary.services,1)
    w.recipeIDs={}; for id=1,45 do w.recipeIDs[id]=id; w.recipes[id]=craftRecipe(id,200) end
    A.Crafting.Invalidate(); A.Crafting.Tick(); equal(UI.CatalogSummary(),summary)
    A.Crafting.Tick(); equal(UI.CatalogSummary(),summary)
    A.Crafting.Tick(); truth(UI.CatalogSummary()~=summary); equal(UI.CatalogSummary().count,45)
    equal(UI.CatalogSummary().services,0)
end)
test("material columns retain full quantities sources and missing-price state", function()
    local w,A=craftingWorld(); A.Crafting.Tick(); local material=A.CraftingUI.materialRows[1]
    equal(material.quantity.text,"2"); equal(material.source.text,"AH low"); equal(material.total.text,"2s 00c")
    A.DB.Snapshot().prices[100]=nil; A.Crafting.Tick()
    equal(material.quantity.text,"2"); equal(material.source.text,"Missing"); equal(material.total.text,"Unavailable")
    equal(A.CraftingUI.quoteText,nil)
end)
test("unknown vendor cost remains visit supplier in the aligned material table", function()
    local w,A=craftingWorld(); w.recipes[1].schematic.reagentSlotSchematics[1].reagents={{itemID=2320}}
    A.Crafting.Tick(); local material=A.CraftingUI.materialRows[1]
    equal(material.source.text,"Visit supplier"); equal(material.total.text,"Unavailable")
    equal(A.CraftingUI.quoteText,nil); equal(A.CraftingUI.CatalogSummary().services,0)
end)
test("markup changes update the service quote without inventing resale profit", function()
    local w,A=serviceWorld(); local UI=A.CraftingUI
    UI.markup:SetText("20"); truth(UI.ApplyMarkup()); equal(A.DB.Settings().quoteMarkup,20)
    equal(UI.values[2].text,"4s 80c"); equal(UI.quoteText,"Enchant Chest - Test - 4s 80c ea")
    equal(A.Crafting.selected.profitMin,nil); equal(A.Crafting.builds,1)
    UI.markup:SetText("1001"); equal(UI.ApplyMarkup(),false); equal(A.DB.Settings().quoteMarkup,20)
    w.combat=true; UI.markup:SetText("25"); equal(UI.ApplyMarkup(),false); equal(A.DB.Settings().quoteMarkup,20)
end)
test("service hover quotes use the current markup without revaluing the catalog", function()
    local w,A=serviceWorld(); list(A,true); local UI=A.CraftingUI
    UI.SetSearch("Enchant"); A.DB.data.settings.quoteMarkup=20
    local button=UI.catalogRows[1]; local builds=A.Crafting.builds
    button.scripts.OnEnter(button); truth(GameTooltip:IsShown())
    equal(GameTooltip.lines[4].right,"4s 80c"); equal(A.Crafting.builds,builds)
    button.scripts.OnLeave(button); equal(GameTooltip:IsShown(),false); equal(w.requests,1)
end)
test("a service-only profession has a useful profitable-view empty message", function()
    local w,A=serviceWorld(); w.recipeIDs={4}; A.Crafting.Invalidate(); A.Crafting.Tick(); list(A,false)
    equal(#A.CraftingUI.CatalogView(),0); truth(A.CraftingUI.empty:IsShown())
    truth(string.find(A.CraftingUI.empty.text,"services",1,true)); equal(A.CraftingUI.CatalogSummary().missing,0)
    A.CraftingUI.showAllButton.scripts.OnClick(); equal(A.CraftingUI.empty:IsShown(),false)
    equal(A.CraftingUI.catalogRows[1].profit.text,"4s 00c")
end)
