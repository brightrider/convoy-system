;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname PF_BRCS_Travel_05014C03 Extends Package Hidden

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(Actor akActor)
;BEGIN CODE
Int convoys = JDB.solveObj(".BRConvoySystem.convoys")

String key_ = JMap.nextKey(convoys)
While key_
    Int convoy = JMap.getObj(convoys, key_)
    Actor leader = JMap.getForm(convoy, "leader") As Actor
    If akActor == leader
        Controller.OnConvoyArrive(key_)
        key_ = ""
    Else
        key_ = JMap.nextKey(convoys, key_)
    EndIf
EndWhile
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment

BRCS_Controller Property Controller  Auto  
