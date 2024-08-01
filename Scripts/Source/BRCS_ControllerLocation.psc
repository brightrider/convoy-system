Scriptname BRCS_ControllerLocation extends Quest

Function CreateLocationAtMe(String name)
    RegisterLocation(name, Game.GetPlayer().PlaceAtMe(Game.GetForm(0x0000003B), abForcePersist = True))
EndFunction

Function RegisterLocation(String name, ObjectReference ref)
    Int location_ = JMap.object()
    JMap.setForm(location_, "ref", ref)
    JMap.setObj(JDB.solveObj(".BRConvoySystem.locations"), name, location_)
EndFunction

Int Function GetLocations()
    Return JDB.solveObj(".BRConvoySystem.locations")
EndFunction

ObjectReference Function GetLocationRef(String name)
    Return JDB.solveForm(".BRConvoySystem.locations." + name + ".ref") as ObjectReference
EndFunction

Function RemoveLocation(String name)
    JMap.removeKey(JDB.solveObj(".BRConvoySystem.locations"), name)
EndFunction
