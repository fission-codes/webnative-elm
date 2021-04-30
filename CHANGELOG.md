# Changelog

### 6.0.0

__⚠️ Requires webnative 0.24 or later!__

New `Path` type, along with a new `Path` module and helper functions.


### 5.0.0

- Fixed typo `loadFilesystem` should be `loadFileSystem`
- Export `defaultInitOptions`
- Show error if webnative failed to load
- Return the `getFs` and `portNames` used in the `setup` and `request` javascript functions.


### 4.0.0-3 (NPM)

- Don't try to send response to Elm if the port is not defined.
- Rename `processRequest` to `request`.


### 4.0.0-2 (NPM)

- Expose `processRequest` on the javascript side, in case you want to set up the incoming port yourself.


### 4.0.0

- Improved the return value of `Webnative.decodeResponse`
- Forgot to expose the new `Error` type 😅


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
