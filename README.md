# Pilipinas

It's a collection of Regions, Provinces, Cities/Municipalities & Barangays within Philippines.

It's a file based PH directory. If you want to get data from db, use `gem pinas`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pilipinas'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pilipinas

## Usage

```ruby
# All Regions
Pilipinas::Region.all

# All Provinces
Pilipinas::Province.all

# All Cities/Municipalities
Pilipinas::City.all

# All Barangays
Pilipinas::Barangay.all

# Finding record thru find_by_(code/name) method
region = Pilipinas::Region.find_by_name("REGION V (Bicol Region)")

# Get provinces by region
region.provinces
```
## Acknowledgement

The data used in this gem is from `gem pinas`. Kudos!

## TODO

* Add a form helper

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/denmarkmeralpis/pilipinas. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Pilipinas project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/pilipinas/blob/master/CODE_OF_CONDUCT.md).
