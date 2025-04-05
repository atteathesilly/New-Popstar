#===============================================================================
# Type effectiveness is multiplied by the Psychic-type's effectiveness against
# the target. (NESP's signatures)
#===============================================================================
class PokeBattle_Move_EffectivenessIncludesPsychicType < PokeBattle_Move
  def pbCalcTypeModSingle(moveType, defType, user=nil, target=nil)
      ret = super
      if GameData::Type.exists?(:PSYCHIC)
          psychicEff = Effectiveness.calculate_one(:PSYCHIC, defType)
          ret *= psychicEff.to_f / Effectiveness::NORMAL_EFFECTIVE_ONE
      end
      return ret
  end
end
#===============================================================================
# User copies target's types, also dizzies them (Droppy Copy)
#===============================================================================
class PokeBattle_Move_DroppyCopy < PokeBattle_DizzyMove
  def ignoresSubstitute?(_user); return true; end

  def pbMoveFailed?(user, _targets, show_message)
      unless user.canChangeType?
          if show_message
              @battle.pbDisplay(_INTL("But it failed, since #{user.pbThis(true)} can't have its types changed!"))
          end
          return true
      end
      return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
      newTypes = target.pbTypes(true)
      if newTypes.length == 0 # Target has no type to copy
          @battle.pbDisplay(_INTL("But it failed, since #{target.pbThis(true)} has no types!")) if show_message
          return true
      end
      if user.pbTypes == target.pbTypes && user.effects[:Type3] == target.effects[:Type3]
          @battle.pbDisplay(_INTL("But it failed, since #{user.pbThis(true)} && #{target.pbThis(true)} share the exact same types!")) if show_message
          return true
      end
      return false
  end

  def pbEffectAgainstTarget(user, target)
      user.pbChangeTypes(target)
      @battle.pbDisplay(_INTL("{1}'s type changed to match {2}'s!",
         user.pbThis, target.pbThis(true)))
  end
  def initialize(battle, move)
    super
    @statusToApply = :DIZZY
  end
end
#===============================================================================
# Revives a fainted party member back to 100% HP if a foe fainted last turn (Kirby Dance)
#===============================================================================
class PokeBattle_Move_KirbyDance < PokeBattle_PartyMemberEffectMove
    def legalChoice(pokemon)
        return false unless super
        return false unless pokemon.fainted?
        return true
    end

	def pbMoveFailed?(user, targets, show_message)
        unless user.pbOpposingSide.faintLastRound?
            @battle.pbDisplay(_INTL("But it failed, since there was no victory to celebrate!")) if show_message
            return true
        end
        super
    end

    def effectOnPartyMember(pokemon)
        pokemon.heal
        @battle.pbDisplay(_INTL("{1} recovered all the way to full health!", pokemon.name))
    end

    def getEffectScore(_user, _target)
        return 250
    end
end