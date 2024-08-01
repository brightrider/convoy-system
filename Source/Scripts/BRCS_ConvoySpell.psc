Scriptname BRCS_ConvoySpell extends activemagiceffect

BRCS_ControllerFrontend Property Frontend Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Frontend.ShowMainConvoyMenu()
EndEvent
