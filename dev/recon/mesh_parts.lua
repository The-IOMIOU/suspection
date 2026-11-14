-- which skeletal meshes make up a suspect, a SWAT squad member and the player (safe: no TArray iteration)
local function nm(o) local ok,r=pcall(function() return o:GetFName():ToString() end) return ok and r or "-" end
local owners = {}
local sus = (FindAllOf("SuspectCharacter") or {})[1]; local swat = (FindAllOf("SWATCharacter") or {})[1]
local ply; for _,c in ipairs(FindAllOf("PlayerCharacter") or {}) do if not nm(c:GetClass()):find("Custom") then ply = c end end
if sus then owners[sus:GetFullName()] = "SUS" end
if swat then owners[swat:GetFullName()] = "SWAT" end
if ply then owners[ply:GetFullName()] = "PLY" end
local out = {SUS={}, SWAT={}, PLY={}}
for _,c in ipairs(FindAllOf("SkeletalMeshComponent") or {}) do
  local ok, own = pcall(function() return c:GetOwner() end)
  if ok and own and own:IsValid() then local tag = owners[own:GetFullName()]
    if tag then local m; pcall(function() m = c.SkeletalMesh end); if not m then pcall(function() m = c.SkeletalMeshAsset end) end
      table.insert(out[tag], nm(c).."="..nm(m)) end end
end
for k,v in pairs(out) do P(k, #v, table.concat(v, "  ")) end
