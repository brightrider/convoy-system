Scriptname BRCS_ControllerFrontend extends Quest

Import PO3_SKSEFunctions

BRCS_Controller Property Controller Auto
BRCS_ControllerLocation Property ControllerLocation Auto

GlobalVariable Property ScanRadius Auto

String CreateConvoy_SelectedName            = "None"
Actor CreateConvoy_SelectedLeader           = None
Actor CreateConvoy_SelectedGuard            = None
String CreateConvoy_SelectedTarget          = "None"
String CreateConvoy_SelectedLeaderDesc      = "None"
String CreateConvoy_SelectedGuardDesc       = "None"
Int CreateConvoy_SelectedPrisoners          = 0

Event OnInit()
    CreateConvoy_SelectedPrisoners = JArray.object()
    JValue.retain(CreateConvoy_SelectedPrisoners)
EndEvent

Function ShowMainLocationMenu()
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu
    listMenu.AddEntryItem("Add new location here")
    listMenu.AddEntryItem("Manage locations")
    listMenu.OpenMenu()
    Int choice = listMenu.GetResultInt()
    If choice == 0
        UIExtensions.InitMenu("UITextEntryMenu")
        UIExtensions.OpenMenu("UITextEntryMenu")
        String locName = UIExtensions.GetMenuResultString("UITextEntryMenu")
        If !locName
            Debug.Notification("Cannot create location with empty name.")
            ShowMainLocationMenu()
            Return
        EndIf
        ControllerLocation.CreateLocationAtMe(locName)
        Debug.Notification("Location " + locName + " created at current player position.")
        ShowMainLocationMenu()
    ElseIf choice == 1
        ShowListLocationMenu()
    EndIf
EndFunction

Function ShowListLocationMenu()
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu

    Int locations = ControllerLocation.GetLocations()
    String key_ = JMap.nextKey(locations)
    If !key_
        Debug.Notification("No locations found.")
        ShowMainLocationMenu()
        Return
    EndIf
    While key_
        listMenu.AddEntryItem(key_)
        key_ = JMap.nextKey(locations, key_)
    EndWhile

    listMenu.OpenMenu()
    String locName = listMenu.GetResultString()
    If locName
        UIListMenu listMenu_ = UIExtensions.GetMenu("UIListMenu") As UIListMenu
        listMenu_.AddEntryItem("Remove location")
        listMenu_.OpenMenu()
        Int choice = listMenu_.GetResultInt()
        If choice == 0
            ControllerLocation.RemoveLocation(locName)
            Debug.Notification("Location " + locName + " removed.")
        EndIf
        ShowListLocationMenu()
    Else
        ShowMainLocationMenu()
    EndIf
EndFunction

Function ShowMainConvoyMenu()
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu
    listMenu.AddEntryItem("Add new convoy")
    listMenu.AddEntryItem("Manage convoys")
    listMenu.OpenMenu()
    Int choice = listMenu.GetResultInt()
    If choice == 0
        ShowCreateConvoyMenu(GetNearbyActors())
    ElseIf choice == 1
        ShowManageConvoysMenu()
    EndIf
EndFunction

Function ShowCreateConvoyMenu(ObjectReference[] nearbyActors)
    Int locations = ControllerLocation.GetLocations()
    String locName = JMap.nextKey(locations)
    If !locName
        Debug.Notification("Convoy creation requires at least one location defined.")
        ShowMainConvoyMenu()
        Return
    EndIf

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu
    listMenu.AddEntryItem("Name: " + CreateConvoy_SelectedName)
    listMenu.AddEntryItem("Leader: " + CreateConvoy_SelectedLeaderDesc)
    listMenu.AddEntryItem("Guard: " + CreateConvoy_SelectedGuardDesc)
    listMenu.AddEntryItem("Target: " + CreateConvoy_SelectedTarget)
    listMenu.AddEntryItem("Configure prisoners")
    listMenu.AddEntryItem("Confirm")
    listMenu.OpenMenu()
    Int choice = listMenu.GetResultInt()
    If choice == 0
        UIExtensions.InitMenu("UITextEntryMenu")
        UIExtensions.OpenMenu("UITextEntryMenu")
        String convoyName = UIExtensions.GetMenuResultString("UITextEntryMenu")
        If convoyName
            CreateConvoy_SelectedName = convoyName
        EndIf
        ShowCreateConvoyMenu(nearbyActors)
    ElseIf choice == 1
        ObjectReference selectedActor = ShowSelectActorMenu(nearbyActors)
        If selectedActor
            CreateConvoy_SelectedLeader = selectedActor As Actor
            CreateConvoy_SelectedLeaderDesc = selectedActor.GetDisplayName()
        EndIf
        ShowCreateConvoyMenu(nearbyActors)
    ElseIf choice == 2
        ObjectReference selectedActor = ShowSelectActorMenu(nearbyActors)
        If selectedActor
            CreateConvoy_SelectedGuard = selectedActor As Actor
            CreateConvoy_SelectedGuardDesc = selectedActor.GetDisplayName()
        Else
            CreateConvoy_SelectedGuard = None
            CreateConvoy_SelectedGuardDesc = "None"
        EndIf
        ShowCreateConvoyMenu(nearbyActors)
    ElseIf choice == 3
        UIListMenu listMenu_ = UIExtensions.GetMenu("UIListMenu") As UIListMenu

        Int i = 0
        While locName
            listMenu_.AddEntryItem(locName)
            locName = JMap.nextKey(locations, locName)
        EndWhile

        listMenu_.OpenMenu()
        String locName_ = listMenu_.GetResultString()
        If locName_
            CreateConvoy_SelectedTarget = locName_
        EndIf

        ShowCreateConvoyMenu(nearbyActors)
    ElseIf choice == 4
        ShowConfigurePrisonersMenu(nearbyActors)
    ElseIf choice == 5
        If CreateConvoy_SelectedName == "None" ||\
            !CreateConvoy_SelectedLeader ||\
            CreateConvoy_SelectedTarget == "None" ||\
            !CreateConvoy_SelectedPrisoners

            Debug.Notification("Name, Leader, Target and Prisoners must be set.")
            ShowCreateConvoyMenu(nearbyActors)
            Return
        EndIf

        Controller.CreateConvoy(CreateConvoy_SelectedName, CreateConvoy_SelectedLeader,\
            JValue.deepCopy(CreateConvoy_SelectedPrisoners), CreateConvoy_SelectedTarget, CreateConvoy_SelectedGuard)

        Debug.Notification("Convoy " + CreateConvoy_SelectedName + " created.")

        CreateConvoy_SelectedName       = "None"
        CreateConvoy_SelectedLeader     = None
        CreateConvoy_SelectedGuard      = None
        CreateConvoy_SelectedTarget     = "None"
        CreateConvoy_SelectedLeaderDesc = "None"
        CreateConvoy_SelectedGuardDesc  = "None"
        JArray.clear(CreateConvoy_SelectedPrisoners)

        ShowMainConvoyMenu()
    Else
        ShowMainConvoyMenu()
    EndIf
EndFunction

Function ShowConfigurePrisonersMenu(ObjectReference[] nearbyActors)
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu

    listMenu.AddEntryItem("Add prisoner")

    Int i = 0
    While i < JArray.count(CreateConvoy_SelectedPrisoners)
        listMenu.AddEntryItem((JArray.getForm(CreateConvoy_SelectedPrisoners, i) As ObjectReference).GetDisplayName())
        i += 1
    EndWhile

    listMenu.OpenMenu()
    Int choice = listMenu.GetResultInt()
    If choice == 0
        ObjectReference prisoner = ShowSelectActorMenu(nearbyActors)
        If prisoner
            JArray.addForm(CreateConvoy_SelectedPrisoners, prisoner)
        EndIf
        ShowConfigurePrisonersMenu(nearbyActors)
    ElseIf choice > 0
        JArray.eraseIndex(CreateConvoy_SelectedPrisoners, choice - 1)
        ShowConfigurePrisonersMenu(nearbyActors)
    Else
        ShowCreateConvoyMenu(nearbyActors)
    EndIf
EndFunction

Function ShowManageConvoysMenu()
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu

    Int convoys = Controller.GetConvoys()
    String key_ = JMap.nextKey(convoys)
    If !key_
        Debug.Notification("No convoys found.")
        ShowMainConvoyMenu()
        Return
    EndIf
    Int names = JArray.object()
    JValue.retain(names)
    While key_
        JArray.addStr(names, key_)
        Int convoy = JMap.getObj(convoys, key_)
        String status = JMap.getStr(convoy, "status")
        listMenu.AddEntryItem(key_ + " (" + status + ")")
        key_ = JMap.nextKey(convoys, key_)
    EndWhile

    listMenu.OpenMenu()
    Int choice = listMenu.GetResultInt()
    If choice >= 0
        ShowManageConvoyMenu(JArray.getStr(names, choice))
    Else
        ShowMainConvoyMenu()
    EndIf

    JValue.release(names)
EndFunction

Function ShowManageConvoyMenu(String name)
    Int convoy = Controller.GetConvoy(name)
    String status = JMap.getStr(convoy, "status")
    Int trackId = JMap.getInt(convoy, "trackId")

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu
    If status == "created"
        listMenu.AddEntryItem("Start convoy")
        listMenu.AddEntryItem("Start convoy (Hands Behind Head)")
    EndIf
    If trackId == -1
        listMenu.AddEntryItem("Track convoy")
    Else
        listMenu.AddEntryItem("Stop tracking convoy")
    EndIf
    listMenu.AddEntryItem("Show convoy details")
    listMenu.AddEntryItem("Destroy convoy")

    listMenu.OpenMenu()
    String choice = listMenu.GetResultString()
    If choice == "Start convoy"
        Controller.StartConvoy(name, False)
        ShowManageConvoyMenu(name)
    ElseIf choice == "Start convoy (Hands Behind Head)"
        Controller.StartConvoy(name, True)
        ShowManageConvoyMenu(name)
    ElseIf choice == "Track convoy"
        If !Controller.TrackConvoy(name)
            Debug.Notification("You have reached the maximum number of tracked convoys (10).")
        EndIf
        ShowManageConvoyMenu(name)
    ElseIf choice == "Stop tracking convoy"
        Controller.UntrackConvoy(name)
        ShowManageConvoyMenu(name)
    ElseIf choice == "Show convoy details"
        ShowConvoyDetailsMenu(name)
        ShowManageConvoyMenu(name)
    ElseIf choice == "Destroy convoy"
        Controller.DestroyConvoy(name)
        ShowManageConvoysMenu()
    Else
        ShowManageConvoysMenu()
    EndIf
EndFunction

Function ShowConvoyDetailsMenu(String name)
    Int convoy = Controller.GetConvoy(name)

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu
    listMenu.AddEntryItem("Name: " + name)
    listMenu.AddEntryItem("Status: " + JMap.getStr(convoy, "status"))
    listMenu.AddEntryItem("Target: " + JMap.getStr(convoy, "locName"))
    listMenu.AddEntryItem("Leader: " + (JMap.getForm(convoy, "leader") As Actor).GetDisplayName())
    Actor guard = JMap.getForm(convoy, "guard") As Actor
    If guard
        listMenu.AddEntryItem("Guard: " + guard.GetDisplayName())
    Else
        listMenu.AddEntryItem("Guard: None")
    EndIf
    listMenu.AddEntryItem("Prisoners:")
    Int prisoners = JMap.getObj(convoy, "prisoners")
    Int i = 0
    While i < JArray.count(prisoners)
        listMenu.AddEntryItem((JArray.getForm(prisoners, i) As Actor).GetDisplayName())
        i += 1
    EndWhile

    listMenu.OpenMenu()
    If listMenu.GetResultInt() >= 0
        ShowConvoyDetailsMenu(name)
    EndIf
EndFunction

Actor Function ShowSelectActorMenu(ObjectReference[] actors)
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") As UIListMenu

    Int validActors = JArray.object()
    JValue.retain(validActors)
    Int i = 0
    While i < actors.Length
        If !Controller.IsActorAssigned(actors[i]) &&\
            actors[i] != Game.GetPlayer() &&\
            actors[i] != CreateConvoy_SelectedLeader &&\
            actors[i] != CreateConvoy_SelectedGuard &&\
            JArray.countForm(CreateConvoy_SelectedPrisoners, actors[i]) == 0

            JArray.addForm(validActors, actors[i])
        EndIf
        i += 1
    EndWhile

    i = 0
    While i < JArray.count(validActors)
        listMenu.AddEntryItem((JArray.getForm(validActors, i) As Actor).GetDisplayName())
        i += 1
    EndWhile

    If i == 0
        Debug.Notification("No nearby actors found.")
        JValue.release(validActors)
        Return None
    EndIf

    listMenu.OpenMenu()
    Int choice = listMenu.GetResultInt()
    If choice == -1
        Return None
    EndIf

    Actor result = JArray.getForm(validActors, choice) As Actor
    JValue.release(validActors)
    Return result
EndFunction

ObjectReference[] Function GetNearbyActors()
    Return FindAllReferencesWithKeyword(\
        Game.GetPlayer(), Game.GetForm(0x00013794), ScanRadius.GetValue(), False)
EndFunction
