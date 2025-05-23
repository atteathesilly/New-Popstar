#===============================================================================
# * Unreal Time System - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It makes the time in game uses its
# own clock that only pass when you are in game instead of using real time
# (like Minecraft and Zelda: Ocarina of Time).
#
#== INSTALLATION ===============================================================
#
# To this script works, put it above main OR convert into a plugin.
#
#== HOW TO USE =================================================================
#
# This script automatic works after installed.
#
# If you wish to add/reduce time, there are 3 ways:
#
# 1. EXTRA_SECONDS/EXTRA_DAYS are variables numbers that hold time passage;
# The time in these variable isn't affected by PROPORTION.
# Example: When the player sleeps you wish to the time in game advance
# 8 hours, so put in EXTRA_SECONDS a game variable number and sum
# 28800 (60*60*8) in this variable every time that the players sleeps.
#
# 2. 'UnrealTime.add_seconds(seconds)' and 'UnrealTime.add_days(days)' does the
# same thing, in fact, EXTRA_SECONDS/EXTRA_DAYS call these methods.
#
# 3. 'UnrealTime.advance_to(16,17,18)' advance the time to a fixed time of day,
# 16:17:18 on this example.
#
#== NOTES ======================================================================
#
# If you wish to some parts still use real time like the Trainer Card start time
# and Pokémon Trainer Memo, just change 'pbGetTimeNow' to 'Time.now' in their
# scripts.
#
# This script uses the Ruby Time class. Before Essentials version 19 (who came
# with 64-bit ruby) it can only have 1901-2038 range.
#
# Some time methods:
# 'pbGetTimeNow.year', 'pbGetTimeNow.mon' (the numbers from 1-12),
# 'pbGetTimeNow.day','pbGetTimeNow.hour', 'pbGetTimeNow.min',
# 'pbGetTimeNow.sec', 'pbGetAbbrevMonthName(pbGetTimeNow.mon)',
# 'pbGetTimeNow.strftime("%A")' (displays weekday name),
# 'pbGetTimeNow.strftime("%I:%M %p")' (displays Hours:Minutes pm/am)
#
#===============================================================================

if defined?(PluginManager) && !PluginManager.installed?("Unreal Time System")
    PluginManager.register({
      :name    => "Unreal Time System",
      :version => "1.1.1",
      :link    => "https://www.pokecommunity.com/showthread.php?t=285831",
      :credits => "FL",
    })
end

module UnrealTime
    # Set false to disable this system (returns Time.now)
    ENABLED = true

    # Time proportion here.
    # So if it is 100, one second in real time will be 100 seconds in game.
    # If it is 60, one second in real time will be one minute in game.
    PROPORTION = 60

    # Starting on Essentials v17, the map tone only try to refresh tone each 30
    # real time seconds.
    # If this variable number isn't -1, the game use this number instead of 30.
    # When time is changed with advance_to or add_seconds, the tone refreshes.
    TONE_CHECK_INTERVAL = 10.0

    # Make this true to time only pass at field (Scene_Map)
    # A note to scripters: To make time pass on other scenes, put line
    # '$PokemonGlobal.addNewFrameCount' near to line 'Graphics.update'
    TIME_STOPS = true

    # Make this true to time pass in battle, during turns and command selection.
    # This won't affect the Pokémon and Bag submenus.
    # Only works if TIME_STOPS=true.
    BATTLE_PASS = true

    # Make this true to time pass when the Dialog box or the main menu are open.
    # This won't affect the submenus like Pokémon and Bag.
    # Only works if TIME_STOPS=true.
    TALK_PASS = true

    # Choose switch number that when true the time won't pass (or -1 to cancel).
    # Only works if TIME_STOPS=true.
    SWITCH_STOPS = -1

    # Choose variable(s) number(s) that can hold time passage (or -1 to cancel).
    # Look at description for more details.
    EXTRA_SECONDS = -1
    EXTRA_DAYS = -1

    # Initial date. In sequence: Year, month, day, hour and minutes.
    # Method UnrealTime.reset resets time back to this time.
    def self.initial_date
        return Time.local(2000, 1, 1, 12, 0)
    end

    # Advance to next time. If time already passed, advance
    # into the time on the next day.
    # Hour is 0..23
    def self.advance_to(hour, min = 0, sec = 0)
        raise RangeError, "hour is #{hour}, should be 0..23" if hour < 0 || hour > 23
        day_seconds = 60 * 60 * 24
        seconds_now = pbGetTimeNow.hour * 60 * 60 + pbGetTimeNow.min * 60 + pbGetTimeNow.sec
        target_seconds = hour * 60 * 60 + min * 60 + sec
        seconds_added = target_seconds - seconds_now
        seconds_added += day_seconds if seconds_added < 0
        add_seconds(seconds_added)
        PBDayNight.sheduleToneRefresh
    end

    # Resets time to initial_date.
    def self.reset
        raise "Method doesn't work when TIME_STOPS is false!" unless TIME_STOPS
        $game_variables[EXTRA_SECONDS] = 0 if EXTRA_DAYS > 0
        $game_variables[EXTRA_DAYS] = 0 if EXTRA_DAYS > 0
        $PokemonGlobal.newFrameCount = 0
        $PokemonGlobal.extraYears = 0
        PBDayNight.sheduleToneRefresh
    end

    # Does the same thing as EXTRA_SECONDS variable.
    def self.add_seconds(seconds)
        raise "Method doesn't work when TIME_STOPS is false!" unless TIME_STOPS
        $PokemonGlobal.newFrameCount += (seconds * Graphics.frame_rate) / PROPORTION.to_f
        PBDayNight.sheduleToneRefresh
    end

    def self.add_minutes(minutes)
        add_seconds(60 * minutes)
    end

    def self.add_hours(hours)
        add_seconds(60 * 60 * hours)
    end

    def self.add_days(days)
        add_seconds(60 * 60 * 24 * days)
    end

    NEED_32_BIT_FIX = [""].pack("p").size <= 4
end

module PBDayNight
    HourlyTones = [
        Tone.new(-70, -90,  15, 55),   # Night           # Midnight
        Tone.new(-70, -90,  15, 55),   # Night
        Tone.new(-70, -90,  15, 55),   # Night
        Tone.new(-70, -90,  15, 55),   # Night
        Tone.new(-60, -70,  -5, 50),   # Night
        Tone.new(-40, -50, -35, 50),   # Day/morning
        Tone.new(-40, -50, -35, 50),   # Day/morning     # 6AM
        Tone.new(-40, -50, -35, 50),   # Day/morning
        Tone.new(-40, -50, -35, 50),   # Day/morning
        Tone.new(-20, -25, -15, 20),   # Day/morning
        Tone.new(  0,   0,   0,  0),   # Day
        Tone.new(  0,   0,   0,  0),   # Day
        Tone.new(  0,   0,   0,  0),   # Day             # Noon
        Tone.new(  0,   0,   0,  0),   # Day
        Tone.new(  0,   0,   0,  0),   # Day/afternoon
        Tone.new(  0,   0,   0,  0),   # Day/afternoon
        Tone.new(  0,   0,   0,  0),   # Day/afternoon
        Tone.new(  0,   0,   0,  0),   # Day/afternoon
        Tone.new( -5, -30, -20,  0),   # Day/evening     # 6PM
        Tone.new(-15, -60, -10, 20),   # Day/evening
        Tone.new(-15, -60, -10, 20),   # Day/evening
        Tone.new(-40, -75,   5, 40),   # Night
        Tone.new(-70, -90,  15, 55),   # Night
        Tone.new(-70, -90,  15, 55)    # Night
      ]
      @cachedTone = nil
      @dayNightToneLastUpdate = nil
      @oneOverSixty = 1/60.0
    
      # Returns true if it's day.
      def self.isDay?(time=nil)
        time = pbGetTimeNow if !time
        return (time.hour>=5 && time.hour<20)
      end
    
      # Returns true if it's night.
      def self.isNight?(time=nil)
        time = pbGetTimeNow if !time
        return (time.hour>=20 || time.hour<5)
      end
    
      # Returns true if it's morning.
      def self.isMorning?(time=nil)
        time = pbGetTimeNow if !time
        return (time.hour>=5 && time.hour<10)
      end
    
      # Returns true if it's the afternoon.
      def self.isAfternoon?(time=nil)
        time = pbGetTimeNow if !time
        return (time.hour>=14 && time.hour<17)
      end
    
      # Returns true if it's the evening.
      def self.isEvening?(time=nil)
        time = pbGetTimeNow if !time
        return (time.hour>=17 && time.hour<20)
      end
    
      # Gets a number representing the amount of daylight (0=full night, 255=full day).
      def self.getShade
        time = pbGetDayNightMinutes
        time = (24*60)-time if time>(12*60)
        return 255*time/(12*60)
      end
    
      # Gets a Tone object representing a suggested shading
      # tone for the current time of day.
      def self.getTone
        @cachedTone ||= Tone.new(0, 0, 0)
        return @cachedTone unless Settings::TIME_SHADING
        toneNeedUpdate = (!@dayNightToneLastUpdate ||
          Graphics.frame_count - @dayNightToneLastUpdate >=
          Graphics.frame_rate * UnrealTime::TONE_CHECK_INTERVAL
                         )
        if toneNeedUpdate
            getToneInternal
            applyOutdoorEffects
            @dayNightToneLastUpdate = Graphics.frame_count
        end
        return @cachedTone
    end

    # Shedule a tone refresh on the next try (probably next frame)
    def self.sheduleToneRefresh
        @dayNightToneLastUpdate = nil
    end
    
      def self.pbGetDayNightMinutes
        now = pbGetTimeNow   # Get the current in-game time
        return (now.hour*60)+now.min
      end
    
      private
    
      def self.getToneInternal
        if [413, 414].include?($game_map.map_id) # Eventide Isle
          @cachedTone = PBDayNight::HourlyTones[21]
          echoln("Faking overworld tone for Eventide Isle")
        elsif $Options.forced_time_tint == 0
            # Calculates the tone for the current frame, used for day/night effects
            realMinutes = pbGetDayNightMinutes
            hour   = realMinutes / 60
            minute = realMinutes % 60
            tone         = PBDayNight::HourlyTones[hour]
            nexthourtone = PBDayNight::HourlyTones[(hour + 1) % 24]
            # Calculate current tint according to current and next hour's tint and
            # depending on current minute
            @cachedTone.red   = ((nexthourtone.red - tone.red) * minute * @oneOverSixty) + tone.red
            @cachedTone.green = ((nexthourtone.green - tone.green) * minute * @oneOverSixty) + tone.green
            @cachedTone.blue  = ((nexthourtone.blue - tone.blue) * minute * @oneOverSixty) + tone.blue
            @cachedTone.gray  = ((nexthourtone.gray - tone.gray) * minute * @oneOverSixty) + tone.gray
        elsif $Options.forced_time_tint
            fakeHour = [nil, 6, 12, 18, 0][$Options.forced_time_tint]
            @cachedTone = PBDayNight::HourlyTones[fakeHour]
        end
    end
end

def pbGetTimeNow
    return Time.now if !$PokemonGlobal || !UnrealTime::ENABLED
    day_seconds = 60 * 60 * 24
    if UnrealTime::TIME_STOPS
        # Sum the extra values to newFrameCount
        if UnrealTime::EXTRA_SECONDS > 0
            UnrealTime.add_seconds(pbGet(UnrealTime::EXTRA_SECONDS))
            $game_variables[UnrealTime::EXTRA_SECONDS] = 0
        end
        if UnrealTime::EXTRA_DAYS > 0
            UnrealTime.add_seconds(day_seconds * pbGet(UnrealTime::EXTRA_DAYS))
            $game_variables[UnrealTime::EXTRA_DAYS] = 0
        end
    elsif UnrealTime::EXTRA_SECONDS > 0 && UnrealTime::EXTRA_DAYS > 0
        # Checks to regulate the max/min values at UnrealTime::EXTRA_SECONDS
        while pbGet(UnrealTime::EXTRA_SECONDS) >= day_seconds
            $game_variables[UnrealTime::EXTRA_SECONDS] -= day_seconds
            $game_variables[UnrealTime::EXTRA_DAYS] += 1
        end
        while pbGet(UnrealTime::EXTRA_SECONDS) <= -day_seconds
            $game_variables[UnrealTime::EXTRA_SECONDS] += day_seconds
            $game_variables[UnrealTime::EXTRA_DAYS] -= 1
        end
    end
    start_time = UnrealTime.initial_date
    if UnrealTime::TIME_STOPS
        time_played = $PokemonGlobal.newFrameCount
    else
        time_played = Graphics.frame_count
    end
    time_played = (time_played * UnrealTime::PROPORTION) / Graphics.frame_rate
    time_jumped = 0
    time_jumped += pbGet(UnrealTime::EXTRA_SECONDS) if UnrealTime::EXTRA_SECONDS > -1
    time_jumped += pbGet(UnrealTime::EXTRA_DAYS) * day_seconds if UnrealTime::EXTRA_DAYS > - 1
    time_ret = 0
    # Before Essentials V19, there is a year limit. To prevent crashes due to this
    # limit, every time that you reach in year 2036 the system will subtract 6
    # years (to works with leap year) from your date and sum in
    # $PokemonGlobal.extraYears. You can sum your actual year with this extraYears
    # when displaying years.
    loop do
        time_fix = 0
        time_fix = $PokemonGlobal.extraYears * day_seconds * (365 * 6 + 1) / 6 if $PokemonGlobal.extraYears != 0
        time_ret = start_time + (time_played + time_jumped - time_fix)
        break if !UnrealTime::NEED_32_BIT_FIX || time_ret.year < 2036
        $PokemonGlobal.extraYears += 6
    end
    return time_ret
end

def speedingUpTime?
    debugControl && Input.pressex?(0x54) # T, for time
end

class PokemonGlobalMetadata
    attr_writer :newFrameCount # Became float when using extra values
    attr_writer :extraYears

    def addNewFrameCount
        return if UnrealTime::SWITCH_STOPS > 0 && $game_switches[UnrealTime::SWITCH_STOPS]
        if speedingUpTime?
            self.newFrameCount += 100
            PBDayNight.sheduleToneRefresh
        else
            self.newFrameCount += 1
        end
    end

    def newFrameCount
        @newFrameCount ||= 0
        return @newFrameCount
    end

    def extraYears
        @extraYears ||= 0
        return @extraYears
    end
end

def pbDayNightTint(object)
    return if !$scene.is_a?(Scene_Map)
    if Settings::TIME_SHADING && GameData::MapMetadata.exists?($game_map.map_id) &&
       GameData::MapMetadata.get($game_map.map_id).outdoor_map
      tone = PBDayNight.getTone
      object.tone.set(tone.red,tone.green,tone.blue,tone.gray)
    else
      object.tone.set(0,0,0,0)
    end
  end
  
  
  
  #===============================================================================
  # Moon phases and Zodiac
  #===============================================================================
  # Calculates the phase of the moon.
  # 0 - New Moon
  # 1 - Waxing Crescent
  # 2 - First Quarter
  # 3 - Waxing Gibbous
  # 4 - Full Moon
  # 5 - Waning Gibbous
  # 6 - Last Quarter
  # 7 - Waning Crescent
  def moonphase(time=nil) # in UTC
    time = pbGetTimeNow if !time
    transitions = [
       1.8456618033125,
       5.5369854099375,
       9.2283090165625,
       12.9196326231875,
       16.6109562298125,
       20.3022798364375,
       23.9936034430625,
       27.6849270496875]
    yy = time.year-((12-time.mon)/10.0).floor
    j = (365.25*(4712+yy)).floor + (((time.mon+9)%12)*30.6+0.5).floor + time.day+59
    j -= (((yy/100.0)+49).floor*0.75).floor-38 if j>2299160
    j += (((time.hour*60)+time.min*60)+time.sec)/86400.0
    v = (j-2451550.1)/29.530588853
    v = ((v-v.floor)+(v<0 ? 1 : 0))
    ag = v*29.53
    for i in 0...transitions.length
      return i if ag<=transitions[i]
    end
    return 0
  end
  
  # Calculates the zodiac sign based on the given month and day:
  # 0 is Aries, 11 is Pisces. Month is 1 if January, and so on.
  def zodiac(month,day)
    time = [
       3,21,4,19,   # Aries
       4,20,5,20,   # Taurus
       5,21,6,20,   # Gemini
       6,21,7,20,   # Cancer
       7,23,8,22,   # Leo
       8,23,9,22,   # Virgo
       9,23,10,22,  # Libra
       10,23,11,21, # Scorpio
       11,22,12,21, # Sagittarius
       12,22,1,19,  # Capricorn
       1,20,2,18,   # Aquarius
       2,19,3,20    # Pisces
    ]
    for i in 0...12
      return i if month==time[i*4] && day>=time[i*4+1]
      return i if month==time[i*4+2] && day<=time[i*4+3]
    end
    return 0
  end
  
  # Returns the opposite of the given zodiac sign.
  # 0 is Aries, 11 is Pisces.
  def zodiacOpposite(sign)
    return (sign+6)%12
  end
  
  # 0 is Aries, 11 is Pisces.
  def zodiacPartners(sign)
    return [(sign+4)%12,(sign+8)%12]
  end
  
  # 0 is Aries, 11 is Pisces.
  def zodiacComplements(sign)
    return [(sign+1)%12,(sign+11)%12]
  end
  
  #===============================================================================
  # Days of the week
  #===============================================================================
  def pbIsWeekday(wdayVariable,*arg)
    timenow = pbGetTimeNow
    wday = timenow.wday
    ret = false
    for wd in arg
      ret = true if wd==wday
    end
    if wdayVariable>0
      $game_variables[wdayVariable] = [
         _INTL("Sunday"),
         _INTL("Monday"),
         _INTL("Tuesday"),
         _INTL("Wednesday"),
         _INTL("Thursday"),
         _INTL("Friday"),
         _INTL("Saturday")][wday]
      $game_map.need_refresh = true if $game_map
    end
    return ret
  end
  
  #===============================================================================
  # Months
  #===============================================================================
  def pbIsMonth(monVariable,*arg)
    timenow = pbGetTimeNow
    thismon = timenow.mon
    ret = false
    for wd in arg
      ret = true if wd==thismon
    end
    if monVariable>0
      $game_variables[monVariable] = pbGetMonthName(thismon)
      $game_map.need_refresh = true if $game_map
    end
    return ret
  end
  
  def pbGetMonthName(month)
    return [_INTL("January"),
            _INTL("February"),
            _INTL("March"),
            _INTL("April"),
            _INTL("May"),
            _INTL("June"),
            _INTL("July"),
            _INTL("August"),
            _INTL("September"),
            _INTL("October"),
            _INTL("November"),
            _INTL("December")][month-1]
  end
  
  def pbGetAbbrevMonthName(month)
    return ["",
            _INTL("Jan."),
            _INTL("Feb."),
            _INTL("Mar."),
            _INTL("Apr."),
            _INTL("May"),
            _INTL("Jun."),
            _INTL("Jul."),
            _INTL("Aug."),
            _INTL("Sep."),
            _INTL("Oct."),
            _INTL("Nov."),
            _INTL("Dec.")][month]
  end
  
  #===============================================================================
  # Seasons
  #===============================================================================
  def pbGetSeason
    return (pbGetTimeNow.mon-1)%4
  end
  
  def pbIsSeason(seasonVariable,*arg)
    thisseason = pbGetSeason
    ret = false
    for wd in arg
      ret = true if wd==thisseason
    end
    if seasonVariable>0
      $game_variables[seasonVariable] = [
         _INTL("Spring"),
         _INTL("Summer"),
         _INTL("Autumn"),
         _INTL("Winter")][thisseason]
      $game_map.need_refresh = true if $game_map
    end
    return ret
  end
  
  def pbIsSpring; return pbIsSeason(0,0); end # Jan, May, Sep
  def pbIsSummer; return pbIsSeason(0,1); end # Feb, Jun, Oct
  def pbIsAutumn; return pbIsSeason(0,2); end # Mar, Jul, Nov
  def pbIsFall; return pbIsAutumn; end
  def pbIsWinter; return pbIsSeason(0,3); end # Apr, Aug, Dec
  
  def pbGetSeasonName(season)
    return [_INTL("Spring"),
            _INTL("Summer"),
            _INTL("Autumn"),
            _INTL("Winter")][season]
  end
  