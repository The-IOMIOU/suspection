local pc=FindFirstOf("BasePlayer_C")
local l=pc:K2_GetActorLocation(); local f=pc:GetActorForwardVector()
local a=FindAllOf("CyberneticsSwat_V2_C")[1]
a:K2_SetActorLocation({X=l.X+f.X*500,Y=l.Y+f.Y*500,Z=l.Z+20}, false, {}, true)
P("tp", a:GetFName():ToString(), a:GetTeam())
