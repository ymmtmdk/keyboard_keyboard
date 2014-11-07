# KeyboardKeyboard

A CUI MIDI keyboard.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keyboard_keyboard', github: "ymmtmdk/keyboard_keyboard"
```

And then execute:

    $ bundle

## Usage

```ruby
require 'keyboard_keyboard'

keyboard = KeyboardKeyboard::Keyboard.new(UniMIDI::Output.open(0))
KeyboardKeyboard::Conductor.new(keyboard).busywork
```

## Contributing

1. Fork it ( https://github.com/ymmtmdk/keyboard_keyboard/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
