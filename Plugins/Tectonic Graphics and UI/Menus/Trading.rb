#===============================================================================
#
#===============================================================================
class PokemonTrade_Scene
    def pbUpdate
      pbUpdateSpriteHash(@sprites)
    end
  
    def pbRunPictures(pictures,sprites)
      loop do
        for i in 0...pictures.length
          pictures[i].update
        end
        for i in 0...sprites.length
          if sprites[i].is_a?(IconSprite)
            setPictureIconSprite(sprites[i],pictures[i])
          else
            setPictureSprite(sprites[i],pictures[i])
          end
        end
        Graphics.update
        Input.update
        running = false
        for i in 0...pictures.length
          running = true if pictures[i].running?
        end
        break if !running
      end
    end
  
    def pbStartScreen(pokemon,pokemon2,trader1,trader2)
      @sprites = {}
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99999
      @pokemon  = pokemon
      @pokemon2 = pokemon2
      @trader1  = trader1
      @trader2  = trader2
      addBackgroundOrColoredPlane(@sprites,"background","tradebg",
         Color.new(248,248,248),@viewport)
      @sprites["rsprite1"] = PokemonSprite.new(@viewport)
      @sprites["rsprite1"].setPokemonBitmap(@pokemon,false)
      @sprites["rsprite1"].setOffset(PictureOrigin::Bottom)
      @sprites["rsprite1"].x = Graphics.width/2
      @sprites["rsprite1"].y = 264
      @sprites["rsprite1"].z = 10
      @pokemon.species_data.apply_metrics_to_sprite(@sprites["rsprite1"], 1)
      @sprites["rsprite2"] = PokemonSprite.new(@viewport)
      @sprites["rsprite2"].setPokemonBitmap(@pokemon2,false)
      @sprites["rsprite2"].setOffset(PictureOrigin::Bottom)
      @sprites["rsprite2"].x = Graphics.width/2
      @sprites["rsprite2"].y = 264
      @sprites["rsprite2"].z = 10
      @pokemon2.species_data.apply_metrics_to_sprite(@sprites["rsprite2"], 1)
      @sprites["rsprite2"].visible = false
      @sprites["msgwindow"] = pbCreateMessageWindow(@viewport)
      pbFadeInAndShow(@sprites)
    end
  
    def pbScene1
      spriteBall = IconSprite.new(0,0,@viewport)
      pictureBall = PictureEx.new(0)
      picturePoke = PictureEx.new(0)
      ballimage = sprintf("Graphics/Battle animations/ball_%s", @pokemon.poke_ball)
      if !pbResolveBitmap(ballimage)
        ballimage = sprintf("Graphics/Battle animations/ball_%02d", pbGetBallType(@pokemon.poke_ball))
      end
      ballopenimage = sprintf("Graphics/Battle animations/ball_%s_open", @pokemon.poke_ball)
      if !pbResolveBitmap(ballimage)
        ballopenimage = sprintf("Graphics/Battle animations/ball_%02d_open", pbGetBallType(@pokemon.poke_ball))
      end
      # Starting position of ball
      pictureBall.setXY(0,Graphics.width/2,48)
      pictureBall.setName(0,ballimage)
      pictureBall.setSrcSize(0,32,64)
      pictureBall.setOrigin(0,PictureOrigin::Center)
      pictureBall.setVisible(0,true)
      # Starting position of sprite
      picturePoke.setXY(0,@sprites["rsprite1"].x,@sprites["rsprite1"].y)
      picturePoke.setOrigin(0,PictureOrigin::Bottom)
      picturePoke.setVisible(0,true)
      # Change Pokémon color
      picturePoke.moveColor(2,5,Color.new(31*8,22*8,30*8,255))
      # Recall
      delay = picturePoke.totalDuration
      picturePoke.setSE(delay,"Battle recall")
      pictureBall.setName(delay,ballopenimage)
      pictureBall.setSrcSize(delay,32,64)
      # Move sprite to ball
      picturePoke.moveZoom(delay,8,0)
      picturePoke.moveXY(delay,8,Graphics.width/2,48)
      picturePoke.setSE(delay+5,"Battle jump to ball")
      picturePoke.setVisible(delay+8,false)
      delay = picturePoke.totalDuration+1
      pictureBall.setName(delay,ballimage)
      pictureBall.setSrcSize(delay,32,64)
      # Make Poké Ball go off the top of the screen
      delay = picturePoke.totalDuration+10
      pictureBall.moveXY(delay,6,Graphics.width/2,-32)
      # Play animation
      pbRunPictures(
         [picturePoke,pictureBall],
         [@sprites["rsprite1"],spriteBall]
      )
      spriteBall.dispose
    end
  
    def pbScene2
      spriteBall = IconSprite.new(0,0,@viewport)
      pictureBall = PictureEx.new(0)
      picturePoke = PictureEx.new(0)
      ballimage = sprintf("Graphics/Battle animations/ball_%s", @pokemon2.poke_ball)
      if !pbResolveBitmap(ballimage)
        ballimage = sprintf("Graphics/Battle animations/ball_%02d", pbGetBallType(@pokemon2.poke_ball))
      end
      ballopenimage = sprintf("Graphics/Battle animations/ball_%s_open", @pokemon2.poke_ball)
      if !pbResolveBitmap(ballimage)
        ballopenimage = sprintf("Graphics/Battle animations/ball_%02d_open", pbGetBallType(@pokemon2.poke_ball))
      end
      # Starting position of ball
      pictureBall.setXY(0,Graphics.width/2,-32)
      pictureBall.setName(0,ballimage)
      pictureBall.setSrcSize(0,32,64)
      pictureBall.setOrigin(0,PictureOrigin::Center)
      pictureBall.setVisible(0,true)
      # Starting position of sprite
      picturePoke.setOrigin(0,PictureOrigin::Bottom)
      picturePoke.setZoom(0,0)
      picturePoke.setColor(0,Color.new(31*8,22*8,30*8,255))
      picturePoke.setVisible(0,false)
      # Dropping ball
      y = Graphics.height-96-16-16   # end point of Poké Ball
      delay = picturePoke.totalDuration+2
      for i in 0...4
        t = [4,4,3,2][i]   # Time taken to rise or fall for each bounce
        d = [1,2,4,8][i]   # Fraction of the starting height each bounce rises to
        delay -= t if i==0
        if i>0
          pictureBall.setZoomXY(delay,100+5*(5-i),100-5*(5-i))   # Squish
          pictureBall.moveZoom(delay,2,100)                      # Unsquish
          pictureBall.moveXY(delay,t,Graphics.width/2,y-100/d)
        end
        pictureBall.moveXY(delay+t,t,Graphics.width/2,y)
        pictureBall.setSE(delay+2*t,"Battle ball drop")
        delay = pictureBall.totalDuration
      end
      picturePoke.setXY(delay,Graphics.width/2,y)
      # Open Poké Ball
      delay = pictureBall.totalDuration+15
      pictureBall.setSE(delay,"Battle recall")
      pictureBall.setName(delay,ballopenimage)
      pictureBall.setSrcSize(delay,32,64)
      pictureBall.setVisible(delay+5,false)
      # Pokémon appears and enlarges
      picturePoke.setVisible(delay,true)
      picturePoke.moveZoom(delay,8,100)
      picturePoke.moveXY(delay,8,Graphics.width/2,@sprites["rsprite2"].y)
      # Return Pokémon's color to normal and play cry
      delay = picturePoke.totalDuration
      picturePoke.moveColor(delay,5,Color.new(31*8,22*8,30*8,0))
      cry = GameData::Species.cry_filename_from_pokemon(@pokemon2)
      pbBGMStop
      picturePoke.setSE(delay,cry) if cry
      # Play animation
      pbRunPictures(
         [picturePoke,pictureBall],
         [@sprites["rsprite2"],spriteBall]
      )
      spriteBall.dispose
      pbMEPlay("Evolution success")
    end
  
    def pbEndScreen
      pbDisposeMessageWindow(@sprites["msgwindow"])
      pbFadeOutAndHide(@sprites)
      pbDisposeSpriteHash(@sprites)
      @viewport.dispose
      newspecies = @pokemon2.check_evolution_on_trade(@pokemon)
      if newspecies
        evo = PokemonEvolutionScene.new
        evo.pbStartScreen(@pokemon2,newspecies)
        evo.pbEvolution(false)
        evo.pbEndScreen
      end
      $PokemonTemp.dependentEvents.refresh_sprite(false)
    end
  
    def pbTrade
      pbBGMStop
      @pokemon.play_cry
      speciesname1=GameData::Species.get(@pokemon.species).name
      speciesname2=GameData::Species.get(@pokemon2.species).name
      pbMessageDisplay(@sprites["msgwindow"],
         _ISPRINTF("{1:s}\r\nID: {2:05d}   OT: {3:s}\\wtnp[0]",
         @pokemon.name,@pokemon.owner.public_id,@pokemon.owner.name)) { pbUpdate }
      pbMessageWaitForInput(@sprites["msgwindow"],50,true) { pbUpdate }
      pbPlayDecisionSE
      pbMEPlay("Evolution start")
      pbBGMPlay("Evolution")
      pbScene1
      pbMessageDisplay(@sprites["msgwindow"],
         _INTL("For {1}'s {2},\r\n{3} sends {4}.\1",@trader1,speciesname1,@trader2,speciesname2)) { pbUpdate }
      pbMessageDisplay(@sprites["msgwindow"],
         _INTL("{1} bids farewell to {2}.",@trader2,speciesname2)) { pbUpdate }
      pbScene2
      pbMessageDisplay(@sprites["msgwindow"],
         _ISPRINTF("{1:s}\r\nID: {2:05d}   OT: {3:s}\1",
         @pokemon2.name,@pokemon2.owner.public_id,@pokemon2.owner.name)) { pbUpdate }
      pbMessageDisplay(@sprites["msgwindow"],
         _INTL("Take good care of {1}.",speciesname2)) { pbUpdate }
    end
  end
  
  def pbStartTrade(pokemonIndex,newpoke,nickname,trainerName,trainerClass=:POKEMONTRAINER_Androgynous)
    myPokemon = $Trainer.party[pokemonIndex]
    pbTakeItemsFromPokemon(myPokemon) if myPokemon.hasItem?
    receivingPokemon = createTradedPokemon(newpoke,myPokemon.level,nickname,trainerName,trainerClass)
    pbStartTradeGraphics(myPokemon,receivingPokemon,trainerName)
    $Trainer.party[pokemonIndex] = receivingPokemon
    refreshFollow(false)
  end

  def pbStartBoxTrade(myPokemon,storageLocation,newpoke,nickname,trainerName,trainerClass=:POKEMONTRAINER_Androgynous)
    storageBox = storageLocation[0]
    boxIndex = storageLocation[1]
    pbTakeItemsFromPokemon(myPokemon) if myPokemon.hasItem?
    receivingPokemon = createTradedPokemon(newpoke,myPokemon.level,nickname,trainerName,trainerClass)
    pbStartTradeGraphics(myPokemon,receivingPokemon,trainerName)
    if storageBox == -1
      $Trainer.party[boxIndex] = receivingPokemon
      discoverPokemon(receivingPokemon)
      refreshFollow(false) if storageBox == -1
    else
      $PokemonStorage.pbDelete(storageBox, boxIndex)
      pbAddPokemonFromTrade(receivingPokemon)
    end
  end

  def createTradedPokemon(newpoke,level,nickname,trainerName,trainerClass=:POKEMONTRAINER_Androgynous)
    opponent = NPCTrainer.new(trainerName,trainerClass)
    opponent.id = $Trainer.make_foreign_ID
    if newpoke.is_a?(Pokemon)
      newpoke.owner = Pokemon::Owner.new_from_trainer(opponent)
      receivingPokemon = newpoke
    else
      species_data = GameData::Species.try_get(newpoke)
      raise _INTL("Species does not exist ({1}).", newpoke) if !species_data
      receivingPokemon = Pokemon.new(species_data.id, level, opponent)
      receivingPokemon.reset_moves
    end
    receivingPokemon.name          = nickname
    receivingPokemon.obtain_method = 2   # traded
    receivingPokemon.record_first_moves
    $Trainer.pokedex.register(receivingPokemon)
    $Trainer.pokedex.set_owned(receivingPokemon.species)
    return receivingPokemon
  end
  
  def pbStartTradeGraphics(myPokemon,yourPokemon,opponentName)
    pbFadeOutInWithMusic {
      evo = PokemonTrade_Scene.new
      evo.pbStartScreen(myPokemon,yourPokemon,$Trainer.name,opponentName)
      evo.pbTrade
      evo.pbEndScreen
    }
  end