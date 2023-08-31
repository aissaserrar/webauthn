# webauthn

[![Codemagic build status](https://api.codemagic.io/apps/633340e00c4aebaccd791790/633340e00c4aebaccd79178f/status_badge.svg)](https://codemagic.io/apps/633340e00c4aebaccd791790/633340e00c4aebaccd79178f/latest_build)
[![Pub Version](https://img.shields.io/pub/v/webauthn)](https://pub.dev/packages/webauthn)

This plugin is meant to implement the [WebAuthn Authenticator Model](https://www.w3.org/TR/webauthn/#sctn-authenticator-model). This model is heavily based off the [DuoLabs Android Implementation](https://github.com/duo-labs/android-webauthn-authenticator) of this library.

This plugin relies on the [local_auth plugin](https://pub.dev/packages/local_auth), so it can only support the platforms supported by that plugin.

## Getting Started

### Setup for local_auth

We rely on local_auth in the background, so you need to configure your apps to work properly
with this plugin. See the [iOS Integration](https://pub.dev/packages/local_auth#ios-integration) and [Android Integration](https://pub.dev/packages/local_auth#android-integration) sections.

If you want customize the dialog messages for the biometric prompt, you will need to add the platform-specific local_auth implementation packages (See the "Dialogs" section of the [Usage](https://pub.dev/packages/local_auth#usage) instructions on local_auth). These custom messages can then be passed to `Authenticator.makeCredential`.

### Setup for flutter_secure_storage

Because we need to use [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) we have a minimum SDK requirement.
In `[project]/android/app/build.gradle` set `minSdkVersion` to >= 18.

```
android {
    ...
    defaultConfig {
        ...
        minSdkVersion 18
        ...
    }
}
```

### File generation

This project uses [code generated libraries](https://docs.flutter.dev/development/data-and-backend/json#serializing-json-using-code-generation-libraries) for JSON handling with classes, and for unit tests mocks.

To generate code once, use `dart run build_runner build`. To continuously regenerate use `dart run build_runner watch`.

The generated files are comitted to the repo, so you shouldn't have to do this unless you are making changes.

## Testing

The test suite can be run using `flutter test` command.

### Sqlite Test Setup

Any test of an object interacting with a plugin needs to have a mock created to abstract out the plugin's behavior. The one exception to this is the `db/` tests that were designed to validate that the queries return the expected data. This is accomplished using the [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) package. Depending on what platform you are using, you will need to follow the [Getting Started](https://pub.dev/packages/sqflite_common_ffi#getting-started) steps for your platform to make sure that you have valid sqlite3 libraries on your system.

## Usage

The main entry point to all of the functionality is the `Authenticator` object.

```dart
// Authenticator(bool authencationRequired, bool strongboxRequired)
final authenticator = Authenticator(true, true);
```

The `Authenticator` object is safe to instantiate multiple times.

The arguments passed to the construtor determine whether the keys it generates will require biometric authentication (i.e. we can turn it off for testing) and if the keys should be stored by the platform's StrongBox keystore (not fully supported).

Note that StrongBox keystore is only available on some Android devices.

### Make Credential (User Regstration)

You can create a new credential by passing a `MakeCredentialOptions` object to `Authenticator.makeCredential()`. A `MakeCredentialOptions` object can be instantiated manually or can be deserialized from the following JSON format.

The JSON format mostly tracks the arguments to [authenticatorMakeCredential](https://www.w3.org/TR/webauthn/#sctn-op-make-cred) from the WebAuthn specification, with a few changes necessary for the serialization of binary data. An example is below:
```json
{
    "authenticatorExtensions": "", // optional and currently ignored
    "clientDataHash": "LTCT/hWLtJenIgi0oUhkJz7dE8ng+pej+i6YI1QQu60=", // base64
    "credTypesAndPubKeyAlgs": [
        ["public-key", -7]
    ],
    "excludeCredentials": [
        {
            "type": "public-key",
            "id": "lVGyXHwz6vdYignKyctbkIkJto/ADbYbHhE7+ss/87o=" // base64
            // "transports" member optional but ignored
        }
    ],
    "requireResidentKey": true,
    "requireUserPresence": false,
    "requireUserVerification": true,
    "rp": {
        "name": "webauthn.io",
        "id": "webauthn.io"
    },
    "user": {
        "name": "testuser",
        "displayName": "Test User",
        "id": "/QIAAAAAAAAAAA==" // base64
    }
}
```

Note that `requiresResidentKey` and `requireUserPresence` are effectively ignored: keys are resident by design, and user presence will always be verified. User verfication will always be performed if the `Authenticator` is instantiated with `authentciationRequired` set to `true`; otherwise biometric authentication will not be performed and credential generation will fail if `requireUserVerification` is `true`.

(Per the spec, `requireUserPresence` must be the inverse of `requireUserVerification`)

Create the options object from JSON:
```dart
final makeCredentialOptions = MakeCredentialOptions.fromJson(options);
```

Then, make a new credential with the given options:
```dart
final attestation = authenticator.makeCredential(options);
```

Once you have an `Attestation`, you can also retrieve its CBOR representation as follows:
```dart
Uint8List attestationBytes = attestation.asCBOR();
```

Or you can retrieve a JSON representation as follows:
```dart
String attestationJson = attestation.asJSON();
```

### Get Assertion (User Login)

Similar to `makeCredential`, `getAssertion` takes an argument of a `GetAssertionOptions` object which you can either instantiate manually or deserialized from JSON.

The JSON format follows the [authenticatorGetAssertion](https://www.w3.org/TR/webauthn/#sctn-op-get-assertion) with some changes made for handling of binary data. An example is below:

```json
{
    "allowCredentialDescriptorList": [{
        "id": "jVtTOKLHRMN17I66w48XWuJadCitXg0xZKaZvHdtW6RDCJhxO6Cfff9qbYnZiMQ1pl8CzPkXcXEHwpQYFknN2w==", // base64
        "type": "public-key"
    }],
    "authenticatorExtensions": "", // optional and ignored
    "clientDataHash": "BWlg/oAqeIhMHkGAo10C3sf4U/sy0IohfKB0OlcfHHU=", // base64
    "requireUserPresence": true,
    "requireUserVerification": false,
    "rpId": "webauthn.io"
}
```

Create the options object from JSON:
```dart
final getAssertionOptions = GetAssertionOptions.fromJson(options);
```

Step 7 of [authenticatorGetAssertion](https://www.w3.org/TR/webauthn/#sctn-op-get-assertion) requires that the authenticator prompt a credential selection. This has not yet been implemented, so the most recently created credential is currently used.

### WebAuthn API

If you are implementing your authenticator to interact directly with the Relying Party's application, then you need to be sure to implement the WebAuthn API before trying to call the authenticator according to the [Web Authentication API Spec](https://www.w3.org/TR/webauthn/#sctn-api).

The authenticator library has helper methods to help make a few of these operations easier.

#### Create a New Credential

When you need to [Create a New Credential](https://www.w3.org/TR/webauthn/#sctn-createCredential) you will receive a `CreateCredentialOptions` from the Relying Party. The library can handle the basic processing as follows:

```dart
final webApi = WebAPI();
final rpOptions = CreateCredentialOptions.fromJson(optionsPayload);
final (clientData, makeCredentialOptions) = await webApi.createMakeCredentialOptions(
    origin, // The origin from which you received the request
    rpOptions,
    sameOriginWithAncestor, // Whether we are acting on the same origin
);
// ... any code your app needs to do before creating the credential
final attestation = await Authenticator.handleMakeCredential(makeCredentialOptions);
// ... any code your app needs to do before responding
final responseObj = await webApi.createAttestationResponse(clientData, attestation);
final responseJson = json.encode(responseObj.toJson());
```

#### Make an Assertion

When you need to [Make an Assertion](https://www.w3.org/TR/webauthn/#sctn-getAssertion) you will receive a `CredentialRequestOptions` from the Relying Party. The authenticator will handle the basic processing as follows:

```dart
final webApi = WebAPI();
final rpOptions = CredentialRequestOptions.fromJson(optionsPayload);
final (clientData, getAssertionOptions) = await webApi.createGetAssertionOptions(
    origin, // The origin from which you received the request
    rpOptions,
    sameOriginWithAncestor, // Whether we are acting on the same origin
);

// ... any code your app needs to do before getting the assertion
final assertion = await Authenticator.handleGetAssertion(getAssertionOptions);
// ... any code your app needs to do before responding
final responseObj = await webApi.createAssertionResponse(clientData, assertion);
final responseJson = json.encode(responseObj.toJson());
```