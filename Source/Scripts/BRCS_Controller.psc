Scriptname BRCS_Controller extends Quest

Import PO3_SKSEFunctions
Import ActorUtil

BRCS_ControllerLocation Property ControllerLocation Auto

Spell Property LocationSpell Auto
Spell Property ConvoySpell Auto

Package Property Package_Travel Auto
Package Property Package_Follow Auto
Package Property Package_DoNothing Auto
Keyword Property Package_Travel_Kwd Auto
Keyword Property Package_Follow_Kwd Auto

Event OnInit()
    Int mainEntry = JMap.object()
    Int locations = JMap.object()
    Int convoys = JMap.object()
    JMap.setObj(mainEntry, "locations", locations)
    JMap.setObj(mainEntry, "convoys", convoys)
    JDB.setObj("BRConvoySystem", mainEntry)

    Actor player = Game.GetPlayer()
    player.AddSpell(LocationSpell, False)
    player.AddSpell(ConvoySpell, False)

    RegisterForSingleUpdate(15.0)
EndEvent

Event OnConvoyArrive(String name)
    JMap.setStr(JDB.solveObj(".BRConvoySystem.convoys." + name), "status", "arrived")

    Int handle = ModEvent.Create("BRCS_ConvoyArrive")
    If handle
        ModEvent.PushString(handle, name)
        ModEvent.Send(handle)
    EndIf
EndEvent

Event OnUpdate()
    Int convoys = JDB.solveObj(".BRConvoySystem.convoys")
    String convoyName = JMap.nextKey(convoys)
    While convoyName
        Int convoy = JMap.getObj(convoys, convoyName)

        If JMap.getInt(convoy, "handsBehindHead") == 1
            Int prisoners = JMap.getObj(convoy, "prisoners")
            Int i = 0
            While i < JArray.count(prisoners)
                Actor prisoner = JArray.getForm(prisoners, i) As Actor
                Debug.SendAnimationEvent(prisoner, "HandsBehindHead")
                i += 1
            EndWhile
        EndIf

        convoyName = JMap.nextKey(convoys, convoyName)
    EndWhile

    RegisterForSingleUpdate(15.0)
EndEvent

Function CreateConvoy(String name, Actor leader, Int prisoners, String locName, Actor guard = None)
    Int convoy = JMap.object()
    JMap.setStr(convoy, "status", "created")
    JMap.setForm(convoy, "leader", leader)
    JMap.setObj(convoy, "prisoners", prisoners)
    JMap.setForm(convoy, "guard", guard)
    JMap.setStr(convoy, "locName", locName)
    JMap.setInt(convoy, "handsBehindHead", 0)
    JMap.setInt(convoy, "trackId", -1)
    JMap.setObj(JDB.solveObj(".BRConvoySystem.convoys"), name, convoy)

    AddPackageOverride(leader, Package_DoNothing)
    leader.EvaluatePackage()

    Int i = 0
    Actor prevActor = leader
    While i < JArray.count(prisoners)
        Actor prisoner = JArray.getForm(prisoners, i) As Actor
        SetLinkedRef(prisoner, prevActor, Package_Follow_Kwd)
        AddPackageOverride(prisoner, Package_Follow)
        prisoner.EvaluatePackage()
        i += 1
        prevActor = prisoner
    EndWhile

    If guard
        SetLinkedRef(guard, prevActor, Package_Follow_Kwd)
        AddPackageOverride(guard, Package_Follow)
        guard.EvaluatePackage()
    EndIf
EndFunction

Function StartConvoy(String name, Bool handsBehindHead = True)
    Int convoy = JDB.solveObj(".BRConvoySystem.convoys." + name)

    JMap.setStr(convoy, "status", "travel")

    If handsBehindHead
        JMap.setInt(convoy, "handsBehindHead", 1)

        Int prisoners = JMap.getObj(convoy, "prisoners")
        Int i = 0
        While i < JArray.count(prisoners)
            Actor prisoner = JArray.getForm(prisoners, i) As Actor
            Debug.SendAnimationEvent(prisoner, "HandsBehindHead")
            i += 1
        EndWhile
    EndIf

    Actor leader = JMap.getForm(convoy, "leader") As Actor
    SetLinkedRef(leader, ControllerLocation.GetLocationRef(JMap.getStr(convoy, "locName")), Package_Travel_Kwd)
    RemovePackageOverride(leader, Package_DoNothing)
    AddPackageOverride(leader, Package_Travel)
    leader.EvaluatePackage()
EndFunction

Bool Function TrackConvoy(String name)
    Int convoy = JDB.solveObj(".BRConvoySystem.convoys." + name)
    Actor leader = JMap.getForm(convoy, "leader") As Actor

    Int i = 0
    While i < 10
        If (GetAliasById(i) As ReferenceAlias).ForceRefIfEmpty(leader)
            JMap.setInt(convoy, "trackId", i)
            SetObjectiveDisplayed(i, abForce = True)
            Return True
        EndIf
        i += 1
    EndWhile

    Return False
EndFunction

Function UntrackConvoy(String name)
    Int convoy = JDB.solveObj(".BRConvoySystem.convoys." + name)
    Int trackId = JMap.getInt(convoy, "trackId")
    If trackId == -1
        Return
    EndIf

    SetObjectiveDisplayed(trackId, False, True)
    (GetAliasById(trackId) As ReferenceAlias).Clear()

    JMap.setInt(convoy, "trackId", -1)
EndFunction

Int Function GetConvoys()
    Return JDB.solveObj(".BRConvoySystem.convoys")
EndFunction

Int Function GetConvoy(String name)
    Return JDB.solveObj(".BRConvoySystem.convoys." + name)
EndFunction

Function DestroyConvoy(String name)
    Int convoy = JDB.solveObj(".BRConvoySystem.convoys." + name)

    UntrackConvoy(name)

    Actor leader = JMap.getForm(convoy, "leader") As Actor
    RemovePackageOverride(leader, Package_Travel)
    RemovePackageOverride(leader, Package_DoNothing)
    leader.EvaluatePackage()

    JMap.setInt(convoy, "handsBehindHead", 0)
    Int prisoners = JMap.getObj(convoy, "prisoners")
    Int i = JArray.count(prisoners)
    While i > 0
        i -= 1
        Actor prisoner = JArray.getForm(prisoners, i) As Actor
        Debug.SendAnimationEvent(prisoner, "OffsetStop")
        RemovePackageOverride(prisoner, Package_Follow)
        prisoner.EvaluatePackage()
    EndWhile

    Actor guard = JMap.getForm(convoy, "guard") As Actor
    If guard
        RemovePackageOverride(guard, Package_Follow)
        guard.EvaluatePackage()
    EndIf

    JMap.removeKey(JDB.solveObj(".BRConvoySystem.convoys"), name)
EndFunction

Bool Function IsActorAssigned(ObjectReference ref)
    Int convoys = JDB.solveObj(".BRConvoySystem.convoys")
    String convoyName = JMap.nextKey(convoys)
    While convoyName
        Int convoy = JMap.getObj(convoys, convoyName)

        If (JMap.getForm(convoy, "leader") As ObjectReference) == ref
            Return True
        EndIf

        If (JMap.getForm(convoy, "guard") As ObjectReference) == ref
            Return True
        EndIf

        Int prisoners = JMap.getObj(convoy, "prisoners")
        Int i = 0
        While i < JArray.count(prisoners)
            If (JArray.getForm(prisoners, i) As ObjectReference) == ref
                Return True
            EndIf
            i += 1
        EndWhile

        convoyName = JMap.nextKey(convoys, convoyName)
    EndWhile

    Return False
EndFunction
