# Shoes-Spec

Scarpe, like Shoes before it, tried a variety of display technologies for the [Shoes](https://shoesrb.com) UI app library. Different attempts reached different levels of functionality and maturity.

But it's hard to do more than say, "Shoes3 seemed the most mature, Shoes4 had a good DSL parser but not as good a display library" or similar qualitative, very rough judgements. How would you tell? Are things defined by how close to Shoes3 they got? What about clear bugs in Shoes3? What counts as "really" Shoes?

The Shoes Spec, like the Ruby Spec before it, sets out to try to spell out these differences and test Shoes implementations. Like the Ruby Spec, the Shoes Spec isn't the definition -- nobody appointed me the Emperor of Shoes. Instead, it's a place to argue. If we think Shoes should do one thing or another, we can talk through it, write tests and see what current kinds of Shoes do.

Shoes-Spec uses Minitest as its primary testing language, with a Shoes-specific test API for things like finding widgets, clicking buttons and so on.

## Installation and Usage

Normally you'll clone the shoes-spec repository in order to use it:

    $ git clone https://github.com/scarpe-team/shoes-spec.git

If you want to test an existing Shoes implementation, you'll find them in the "implementations" directory. Normally you can cd into the appropriate subdirectory and then run "bundle exec rake shoes-spec"

## Development

Shoes-spec can work with a variety of display services. That's the whole reason it exists. But it needs to know how to run each one.

The basic unit of Shoes-Spec is a single test -- a Shoes application with a chunk of test code to run against it once it's running.

TODO: sections for running locally, packaging, etc.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/shoes-spec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/shoes-spec/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Shoes::Spec project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scarpe-team/shoes-spec/blob/main/CODE_OF_CONDUCT.md).
