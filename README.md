# Stroke order animator

[![Pub](https://img.shields.io/pub/v/stroke_order_animator.svg)](https://pub.dev/packages/stroke_order_animator)
[![codecov](https://codecov.io/github/chill-chinese/stroke-order-animator/graph/badge.svg?token=NJ011RT2X0)](https://codecov.io/github/chill-chinese/stroke-order-animator)

This package implements stroke order animations and quizzes of Chinese characters based on
[Make me a Hanzi](https://github.com/skishore/makemeahanzi), available under the [ARPHIC public license](ARPHICPL.txt).

Try the [web version](https://chill-chinese.github.io/stroke-order-animator) or see it in action in the [Chill Chinese App](https://chill-chinese.com).

Read the [docs](https://pub.dev/documentation/stroke_order_animator/latest/stroke_order_animator/stroke_order_animator-library.html).

Check out the [example](example/lib/main.dart).

![](doc/output.gif)

# Contributing

## Set up a developer environment

Install

- [just](https://github.com/casey/just)

All available tasks can be displayed by running `just`.

The following tasks are a prerequisite for all other tasks.
They are not added as dependencies to all other tasks because they take
too long to execute and don't need to be executed often.

Install dependencies:

    just get-dependencies

## Run CI pipeline

Run the following commands to make sure that everything works as expected:

    just lint
    just test

## Generate coverage report

Run the following to generate an HTML coverage report combining unit test and integration test coverage:

    genhtml 'coverage/*_lcov.info' -o coverage/html --branch-coverage --ignore-errors inconsistent --ignore-errors count,count

Then open the resulting file in a browser, for example:

    firefox coverage/html/index.html

## Generate code

Code generation is used for test mocks.
Generate code whenever you change the interface of a class that is mocked
somewhere:

    just generate-code

Generated code must be checked into source control so that it doesn't have to
be rebuilt during every CI run.

## Cut a release

- Set the local main branch to the desired commit
- Push the main branch!
- Run `dart run tool/generate_changelog.dart <lastVersion>` and prune output
  as desired
- Run `gh release create` or create a new release on GitHub
- Copy the changelog
