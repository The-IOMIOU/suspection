local h = StaticFindObject("/Script/AssetRegistry.Default__AssetRegistryHelpers")
local out = {}
h:GetAssetRegistry():GetAssetsByPath(FName("/Game/ReadyOrNot/Level"), out, true, false)
local seen={}
for i,v in pairs(out) do local ok,_ = pcall(function()
  local a = v.get and v:get() or v
  local cls = a.AssetClassPath.AssetName:ToString()
  if cls=="World" then local pn=a.PackageName:ToString() local d=pn:match("^/Game/ReadyOrNot/Level/([^/]+/[^/]+)/") or pn
    if pn:find("Core") or pn:find("_P$") or not seen[d] then seen[d]=1 P(pn) end end end) end
