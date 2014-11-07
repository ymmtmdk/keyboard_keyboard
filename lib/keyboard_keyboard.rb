require "keyboard_keyboard/version"

require "unimidi"
require 'curses'

module KeyboardKeyboard
  class Action
    attr_reader :type, :time, :option
    def initialize(type, start, option = {})
      @type = type
      @time = Time.now-start
      @option = option
    end

    def past(start)
      Time.now - start >= @time
    end
  end

  class Keyboard
    def initialize(output)
      @output = output
    end

    def press(note, volume = 100)
      @output.puts(0x90, note, volume)
    end

    def release(note, volume = 100)
      @output.puts(0x80, note, volume)
    end
  end

  class Player
    def initialize(score, keyboard)
      @score = score
      @keyboard = keyboard
      @start = Time.now
      @bar_position = 0
    end

    def stop
      @start = nil
      @bar_position = nil
    end

    def perform
      action = @score[@bar_position]
      if action.past(@start)
        case action.type
        when :on
          @keyboard.press action.option[:note]
        when :off
          @keyboard.release action.option[:note]
        when :stop
          stop
          return
        end
        @bar_position += 1
      end
    end

    def is_playing?
      !!@start
    end
  end

  class Recoder
    attr_reader :score
    def initialize
      @score = nil
      @start = nil
    end

    def rec
      @start = Time.now
      @score = []
      @score << Action.new(:start, @start)
    end

    def stop
      @score << Action.new(:stop, @start)
      @start = nil
    end

    def note_on(note)
      @score << Action.new(:on, @start, note: note)
    end

    def note_off(note)
      @score << Action.new(:off, @start, note: note)
    end

    def is_recording?
      !!@start
    end

    def is_recorded?
      @score && !is_recording?
    end
  end

  class Conductor
    def initialize(keyboard)
      @keyboard = keyboard
      @note_str = "g a b c d e f g a b c d"
      @keys_str = "a s d f g h j k l ; : ]"
      @note_num = "-5 -3 -1 0 2 4 5 7 9 11 12 14"

      sub_str = "q w e t y i o p ["
      sub_num = "-6 -4 -2 1 3 6 8 10 13"
      @base_note = 4*12

      @note_map = {}
      note = @note_num.split(/ /) + sub_num.split(/ /)
      keys = @keys_str.split(/ /) + sub_str.split(/ /)
      note.each_index{|i|
        @note_map[keys[i]] = note[i].to_i
      }

      Curses.timeout = 10
      @recorder = Recoder.new
      @player = nil
    end

    def draw_text(y ,x ,text, is_reverse=false)
      Curses.setpos(y, x)
      Curses.attrset(Curses::A_REVERSE) if is_reverse
      Curses.addstr(text)
      Curses.attrset(Curses::A_NORMAL) if is_reverse
    end

    def draw
      y = 0
      draw_text(0,    0, "notes: #{@note_str.upcase}")
      draw_text(y+=1, 0, "keys : #{@keys_str}")
      draw_text(y+=1, 0, "")
      draw_text(y+=1, 0, "sfhit+R: start recording", @recorder.is_recording?)
      draw_text(y+=1, 0, "sfhit+S: stop recording")
      draw_text(y+=1, 0, "sfhit+P: play recording", @player && @player.is_playing?)
      draw_text(y+=1, 0, "sfhit+Q: quit")
      draw_text(y+=1, 0, "")
      draw_text(y+=1, 0, "1: increment base note")
      draw_text(y+=1, 0, "2: decrement base note")
      draw_text(y+=1, 0, "base note: #{@base_note}")
      draw_text(y+=1, 0, "")
      draw_text(y+=1, 0, "let's play: ")
      Curses.setpos(y,12)
    end

    def getc
      Curses.getch
    end

    def busywork
      prev_note = nil

      loop{
        char = getc
        case char
        when '1'
          @base_note -= 1
        when '2'
          @base_note += 1
        when 'R'
          @recorder.rec unless @recorder.is_recording?
        when 'S'
          @recorder.stop if @recorder.is_recording?
        when 'P'
          if @recorder.is_recorded?
            @player = Player.new(@recorder.score, @keyboard)
          end
        when ' '
          @keyboard.release prev_note
          @recorder.note_off prev_note if @recorder.is_recording?
        when 'Q'
          break
        end

        if nt = @note_map[char]
          if prev_note
            @keyboard.release prev_note
            @recorder.note_off prev_note if @recorder.is_recording?
          end
          note = @base_note + nt
          @keyboard.press note
          @recorder.note_on note if @recorder.is_recording?
          prev_note = note
        end

        @player.perform if @player && @player.is_playing?

        draw
      }
    end
  end
end

if __FILE__ == $0
  keyboard = KeyboardKeyboard::Keyboard.new(UniMIDI::Output.open(0))
  KeyboardKeyboard::Conductor.new(keyboard).busywork
end
