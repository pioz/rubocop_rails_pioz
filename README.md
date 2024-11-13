# Pioz Ruby styling for Rails

## Installation

First add this to your Gemfile:

```ruby
gem "rubocop_rails_pioz", require: false, group: [:development], github: 'pioz/rubocop_rails_pioz'
```

Then run `bundle`, then `bundle binstubs rubocop`.

Then add a default `.rubocop.yml` file in the root of your application with:

```yml
# Pioz Ruby styling for Rails
inherit_gem:
  rubocop_rails_pioz: rubocop.yml

# Your own specialized rules go here
```

Now you can run `./bin/rubocop` to check for compliance and `./bin/rubocop -a` to automatically fix violations.


## License

This gem is released under the [MIT License](https://opensource.org/license/mit/).
