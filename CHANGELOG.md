# Changelog


### 3.0.0

- Fixed issue with `publish` producing an error in `Webnative.decodeResponse`
- Replaced `Maybe Context` with `Context` in the errors returned from `Webnative.decodeResponse`
- Added an `Error` type along side the error message
- Improved documentation


### 2.1.0

- Expose `Wnfs.Directory` module
- Improve documentation


### 2.0.0

- **Ability to initialise webnative via Elm**
- **Only one pair of ports instead of two**
- Now works if the ports aren't present (eg. because of Elm dead code elimination)
- Error handling
- Added an example to the tests
