# Shoes-Spec

Scarpe, like Shoes before it, tried a variety of display technologies for the [Shoes](https://shoesrb.com) UI app library. Different attempts reached different levels of functionality and maturity.

But it's hard to do more than say, "Shoes3 seemed the most mature, Shoes4 had a good DSL parser but not as good a display library" or similar qualitative, very rough judgements. How would you tell? Are things defined by how close to Shoes3 they got? What about clear bugs in Shoes3? What counts as "really" Shoes?

The Shoes Spec, like the Ruby Spec before it, tries to try to spell out these differences and test Shoes implementations. The Shoes Spec isn't the definition -- nobody appointed me the Emperor of Shoes. Instead, it's a place to argue. If we think Shoes should do one thing or another, we can talk through it, write tests and see what current kinds of Shoes do.

Shoes-Spec uses Minitest as its primary testing language, with a Shoes-specific test API for things like finding widgets, clicking buttons and so on. Shoes-spec is *also* the project of specifying that test API. But each Shoes-compatible display service implements the API methods.

## Installation and Usage

Normally you'll clone the shoes-spec repository in order to use it:

    $ git clone https://github.com/scarpe-team/shoes-spec.git

If you want to test an existing Shoes implementation, you'll find them in the "implementations" directory. Normally you can cd into the appropriate subdirectory and then run "bundle exec rake shoes-spec"

## Test Case Limitations

Shoes-Spec works with a variety of display services. That means, for instance, that your test code and your Shoes application may be running in different processes, or even possibly on different computers. A display service that's designed for that (e.g. Scarpe-Wasm compiles your Shoes app to Wasm and tests with Capybara and a remote browser) will be able to patch over some of that, for instance by creating proxy objects and shipping Ruby code back and forth.

But there are still some important limitations when writing test code. For instance:

* your test code can be in a different process, so global variables aren't shared. Similarly, there may be no actual display-service objects in memory when the test code runs if there's a remote server (e.g. wv_relay or scarpe-wasm).
* your test code doesn't run in the Shoes::App object. In fact it can't -- the method button() will make a button in that object, while button() in your test code will find a Shoes::Button.

## Development

Shoes-spec can work with a variety of display services. That's the whole reason it exists. But it needs to know how to run each one.

The basic unit of Shoes-Spec is a single test -- a Shoes application with a chunk of test code to run against it once it's running.

You can find test cases under "cases" in this repo.

For a single implementation, run "bundle exec rake shoes-spec" in its directory. Some implementations may have more than one way they can be run -- for instance, scarpe-webview can run with Calzini or Tiranti, and it's possible to run with packaged Shoes apps or dynamically.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/scarpe-team/shoes-spec. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/scarpe-team/shoes-spec/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Shoes::Spec project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/scarpe-team/shoes-spec/blob/main/CODE_OF_CONDUCT.md).
