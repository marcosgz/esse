# esse

**This project is under development and may suffer constant structural changes. I don't recommend using it right now**

Simple and efficient way to organize queries/mapping/indices/tasks based on the official elasticsearch-ruby.

## Why to use it?
Some facts to use this library:

### Don't spend time learning our DLS
You don't need to spend time learning our DSL or gem usage to start using it. All you need know is the elasticsearch syntax. You are free to build your queries/mappings/settings using JSON/RubyHash flexibility. And keeping simple any elasticsearch upgrade and its syntax changes.

### Multiple ElasticSearch Versions
You can use multiple elasticsearch servers with different versions in an elegant way. Take a look at [LINK TO TOPIC](#anchors-id-here) for more details.

### It's pure Ruby
Yeah!! Nor [activesupport](http://github.com/rails/rails/tree/master/activesupport) dependency and all its monkey patchings. But if you are using rails, suggest install `esse-rails` extension that makes things even easier. Use the [Get started with esse-rails](#anchors-id-here) for more details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'esse'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install esse

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcosgz/esse.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
