BattleHandlers::MoveBaseTypeModifierAbility.add(:PITCHBLACK,
  proc { |ability, _user, move, type|
      next if type != :NORMAL || !GameData::Type.exists?(:DARK)
      move.powerBoost = true
      next :DARK
  }
)

BattleHandlers::MoveBaseTypeModifierAbility.add(:PURIFIED,
  proc { |ability, _user, move, type|
      next if type != :NORMAL || !GameData::Type.exists?(:FAIRY)
      move.powerBoost = true
      next :FAIRY
  }
)

BattleHandlers::DamageCalcTargetAbility.add(:SPACEPARASITE,
  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
    if type == :ICE
      mults[:final_damage_multiplier] *= 1.5
      target.aiLearnsAbility(ability) unless aiCheck
    elsif type != :ICE
      mults[:base_damage_multiplier] /= 2
      target.aiLearnsAbility(ability) unless aiCheck      
    end
  }
)

BattleHandlers::UserAbilityStartOfMove.copy(:PROTEAN,:MIRACULOUS)

#BattleHandlers::DamageCalcTargetAbility.add(:MIRACULOUS,
#  proc { |ability, user, target, move, mults, _baseDmg, type, aiCheck|
#    if type == user.type
#      mults[:final_damage_multiplier] *= 2
#      target.aiLearnsAbility(ability) unless aiCheck
#    end 
#  }
#)

BattleHandlers::AbilityOnSwitchIn.add(:ORBGRABBER,
  proc { |ability, battler, battle, aiCheck|
      next 0 unless battle.icy?
      next 0 unless battler.canAddItem?(:DEATHORB)
      next 8 if aiCheck
      battle.pbShowAbilitySplash(battler, ability)
      battler.giveItem(:DEATHORB)
      battle.pbDisplay(_INTL("{1} discovers the Orb of Death in the snow!", battler.pbThis, getItemName(:PEARLOFFATE)))
      battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::UserAbilityEndOfMove.add(:BUTTERFLYBLADE,
  proc { |ability, user, targets, move, _battle|
    next unless move.bladeMove?
    user.pbRecoverHPFromMultiDrain(targets, 0.13, ability: ability)
  } 
)