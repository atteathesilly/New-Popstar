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
#===============================================================================
# You have absconded with my fungus
#===============================================================================
class PokeBattle_Move_AbscondFungus < PokeBattle_Move
    def switchOutMove?; return true; end
    def pbCalcDamage(user, target, numTargets = 1)
        if target.hasRaisedStatSteps?
            pbShowAnimation(@id, user, target, 1) # Stat step-draining animation
            @battle.pbDisplay(_INTL("{1} stole the target's boosted stats!", user.pbThis))
            showAnim = true
            GameData::Stat.each_battle do |s|
                next if target.steps[s.id] <= 0
                if user.pbCanRaiseStatStep?(s.id, user,
self) && user.pbRaiseStatStep(s.id, target.steps[s.id], user, showAnim)
                    showAnim = false
                end
                target.steps[s.id] = 0
            end
        end
        super
    end

    def getEffectScore(_user, target)
        score = 0
        GameData::Stat.each_battle do |s|
            next if target.steps[s.id] <= 0
            score += target.steps[s.id] * 20
        end
        return score
    end

    def shouldHighlight?(_user, target)
        return target.hasRaisedStatSteps?
    end

    def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
        return if user.fainted? || numHits == 0
        switchOutUser(user,switchedBattlers)
    end

    def getEffectScore(user, target)
        return getSwitchOutEffectScore(user)
    end
end