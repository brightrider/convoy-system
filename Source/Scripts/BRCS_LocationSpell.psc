Scriptname BRCS_LocationSpell extends activemagiceffect

BRCS_ControllerFrontend Property Frontend Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Frontend.ShowMainLocationMenu()
EndEvent
